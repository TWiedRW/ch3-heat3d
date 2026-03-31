library(brms)

set.seed(3141)

# Data from Shiny app
library(RSQLite)
conn <- dbConnect(SQLite(), "shiny-apps/experiment-heat3d/data/stat218-summer2025.db")
dbListTables(conn)
blocks <- dbReadTable(conn, "blocks")
exp_results <- dbReadTable(conn, "exp_results")
users <- dbReadTable(conn, "users")
dbDisconnect(conn)

# Solutions
solutions <- readRDS("data/solutions.rda")

library(tidyverse)
# Pre-processing of results
results <- exp_results %>%

  # Remove all practice trials
  filter(set != "practice") %>%

  # Arrange by user id and trial time
  group_by(user_id) %>%
  arrange(start_time) %>%

  # Identify sequence of trials
  mutate(user_seq = ifelse(user_trial_order > lag(user_trial_order), 0, 1),
         user_seq = ifelse(start_time == min(start_time), 0, user_seq)) %>%
  mutate(user_seq = cumsum(user_seq)) %>%

  # Join with blocks
  left_join(blocks, by = "user_id", relationship = 'many-to-many') %>%

  # Remove blocks that were assigned after the trials started
  group_by(user_id, user_seq) %>%
  filter(system_time < min(start_time)) %>%

  # Get time difference with block and filter for smallest difference
  mutate(time_diff_block = min(start_time) - system_time) %>%
  filter(time_diff_block == min(time_diff_block)) %>%

  # Filter so that only the first completed trial is included
  filter(user_seq == min(user_seq))

# Get user sequences with full completions
full_completions <- results %>%
  group_by(user_id, user_seq, block) %>%
  count() %>%
  filter(n %in% c(16,24))

# Inner join to filter
results <- inner_join(results, full_completions) %>%
  select(-c(time_diff_block, n)) %>%
  ungroup()

# Join with results and filter so that only first completed block is there
results <- left_join(results, solutions) %>%
  ungroup() %>%
  group_by(user_id) %>%
  filter(system_time == min(system_time)) %>%
  ungroup() %>%
  filter(between(as_datetime(system_time), as_date('2025-08-01'), as_date('2025-12-31'))) %>%
  mutate(target_ratio = 100*true_ratio,
         target_size = ifelse(z > 50, 50, z*true_ratio),
         target_diff = z-target_size)

results$pair_id <- factor(results$pair_id)

# All instances of starting the experiment
all_starts <- inner_join(blocks, users) %>%
  filter(!str_detect(tolower(user_unique), 'test,'))

users_clean <- results %>%
  inner_join(users, by = 'user_id', relationship = 'many-to-many') %>%
  select(user_id, user_age:user_unique) %>%
  distinct() %>%
  dplyr::filter(!str_detect(tolower(user_unique), 'test,'))

users_in_person <- users_clean %>%
  inner_join(results) %>%
  group_by(user_id, media) %>%
  summarise(n = n()) %>%
  filter(media == '3dp' & n > 0) %>%
  select(user_id)

res_q1 <- results %>%
  inner_join(users_clean, by = 'user_id') %>%
  mutate(q1 = case_when(
    user_larger == 'Both values are the same' ~ 'Equal',
    (user_larger != true_larger) & (user_larger != 'Both values are the same') ~ 'Smaller',
    user_larger != 'Both values are the same' & user_larger == true_larger ~ 'Larger'
  ), correct_label = ifelse(user_larger == true_larger, '*', NA)) %>%
  mutate(q1_label = factor(q1, labels = c('Smaller value\n(or incorrect)',
                                          'Equal', 'Larger value'),
                           levels = c('Smaller', 'Equal', 'Larger'), ordered = T),
         prop = round(100*true_ratio,1),
         facet_label = paste0('Stimuli Pair ', pair_id, ' (', prop, '%)'),
         q1 = factor(q1, levels = c('Smaller', 'Equal', 'Larger'), ordered = F))

res_q1_filtered <- res_q1 %>%
  filter(pair_id != 5) %>%
  group_by(user_id) %>%
  summarize(n_trials = n(),
            n_correct = sum(user_larger == true_larger),
            p.value = pbinom(n_correct, size = n_trials, prob = 2/3, lower.tail = F)) %>%
  ungroup() %>%
  filter(p.value <= 0.05)


res_q2 <- results %>%
  mutate(q2_error = user_slider - target_ratio,
         q2_error_cm = log2(abs(user_slider - target_ratio) + 1/8))
res_q2_filtered <- res_q2 %>% inner_join(res_q1_filtered)



#===== Bayes Mixture Models ====================================================
# Source: https://paulbuerkner.com/brms/reference/mixture.html

mix <- mixture(gaussian, gaussian, gaussian) #One for ratio, diff, and random
prior <- c(
  brms::prior(normal(1,1), Intercept, dpar = mu1),
  brms::prior(normal(1,1), Intercept, dpar = mu2),
  brms::prior(normal(0,7), Intercept, dpar = mu3)
)

mod1 <- brm(bf(user_slider ~ set*media, mu1 ~ target_ratio, mu2 ~ target_diff),
    res_q2_filtered, family = mix, prior = prior, cores = 4, chains = 4)
