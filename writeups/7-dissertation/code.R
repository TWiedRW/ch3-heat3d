## -----------------------------------------------------------------------
#| message: false
#| warning: false
#| echo: false
library(tidyverse)

set.seed(3141)

# Data from Shiny app
library(RSQLite)
conn <- dbConnect(SQLite(), "../../shiny-apps/experiment-heat3d/data/stat218-summer2025.db")
dbListTables(conn)
blocks <- dbReadTable(conn, "blocks")
exp_results <- dbReadTable(conn, "exp_results")
users <- dbReadTable(conn, "users")
dbDisconnect(conn)

# Solutions
solutions <- readRDS("../../data/solutions.rda")

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
  group_by(user_id, user_seq) %>%

  # Remove blocks that were assigned after the trials started
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
  filter(system_time == min(system_time))

results$pair_id <- factor(results$pair_id)


## -----------------------------------------------------------------------
users_clean <- results %>%
  inner_join(users, by = 'user_id', relationship = 'many-to-many') %>%
  select(user_id, user_age:user_unique) %>%
  distinct() %>%
  dplyr::filter(!str_detect(tolower(user_unique), 'test,'))


## -----------------------------------------------------------------------
users_in_person <- users_clean %>%
  inner_join(results) %>%
  group_by(user_id, media) %>%
  summarise(n = n()) %>%
  filter(media == '3dp' & n > 0) %>%
  select(user_id)





## -----------------------------------------------------------------------
res_q2 <- results %>%
  mutate(target_ratio = 100*true_ratio,
         target_size = ifelse(z > 50, 50, z*true_ratio),
         target_diff = z-target_size) %>%
  # filter(pair_id != 5) %>%
  group_by(user_id, block) %>%
  mutate(prop_correct = mean(user_larger==true_larger),
         trial_correct = factor(user_larger==true_larger))


## -----------------------------------------------------------------------
library(flexmix)

# At least 87.5% correct
res_q2_filter_q1_875 <- res_q2 %>%
  group_by(user_id, block) %>%
  filter(mean(user_larger==true_larger) >= 0.875)
length(unique(res_q2$user_id)) - length(unique(res_q2_filter_q1_875$user_id))
all_users <- unique(res_q2$user_id); length(all_users)
sub_users <- unique(res_q2_filter_q1_875$user_id); length(sub_users)


users %>%
  filter(user_id %in% sub_users) %>%
  group_by(user_reason) %>%
  summarize(count = n()) %>%
  mutate(included = 'yes',
         prop = count/sum(count))

users %>%
  filter(!(user_id %in% sub_users)) %>%
  group_by(user_reason) %>%
  summarize(count = n()) %>%
  mutate(included = 'no',
         prop = count/sum(count))

mod.sf <- stepFlexmix(user_slider ~ target_ratio:media  | user_id:block,
            k = 1:7, nrep = 10,
        data = res_q2_filter_q1_875)

mod.f <- getModel(mod.sf, which = which.min(AIC(mod.sf)))
parameters(mod.f)
summary(mod.f)

# Define the variables
variables <- c("target_ratio", "target_diff", "target_size", "media", "set")

# Generate all possible combinations of variables
all_formulas <- unlist(
  lapply(1:length(variables), function(m) {
    combn(variables, m, function(x) {
      # Main effects only
      main_effects <- paste(x, collapse = " + ")
      # Interaction terms (includes main effects + interactions)
      interaction_terms <- paste(x, collapse = " * ")
      c(
        paste("user_slider ~", main_effects, "| user_id:block"),       # Main effects only
        paste("user_slider ~", interaction_terms, "| user_id:block")  # Main effects + interactions
      )
    })
  })
)

# View all generated formulas
all_combs <- data.frame()
for(i in seq_along(all_formulas)) {
  try({
    mod.sf <- stepFlexmix(as.formula(all_formulas[i]),
                          data = res_q2_filter_q1_875,
                          k = 1:5, nrep = 4)
    k <- 1:5; aic <- AIC(mod.sf)
    tmp.df <- data.frame(formula = all_formulas[i], k = k, aic = aic)
    all_combs <- rbind(all_combs, tmp.df)
  }, silent = T)
}
best_aic <- all_combs %>%
  filter(aic == min(aic)) %>%
  pull(formula) %>%
  first()
best_k <- all_combs %>%
  filter(aic == min(aic)) %>%
  pull(k) %>%
  first()
set.seed(431)
fm.mod <- flexmix(as.formula(best_aic),
        k = best_k,
        data = res_q2_filter_q1_875)
summary(fm.mod)
parameters(fm.mod)

# Clusters 1 and 5 seem to be the people on task correctly
# Clusters 3 and 4 seem to be different strategies.
# Not sure what cluster 2 is doing

res_q2_clustered <- res_q2_filter_q1_875 %>%
  ungroup() %>%
  mutate(cluster = clusters(fm.mod))

p <- ggplot(res_q2_clustered, mapping = aes(x = user_slider-target_ratio, group = user_id)) +
  geom_density() +
  facet_wrap(~cluster)


# Models for sensitivity
library(lme4)
library(lmerTest)

mod.cluster.all <- lmer(user_slider ~ set*media*pair_id + (1|user_id:block/set:media),
     data = filter(res_q2_clustered, pair_id != 5))
mod.cluster.1 <- lmer(user_slider ~ set*media*pair_id + (1|user_id:block/set:media),
                        data = filter(res_q2_clustered, pair_id != 5, cluster == 1))
mod.cluster.2 <- lmer(user_slider ~ set*media*pair_id + (1|user_id:block/set:media),
                        data = filter(res_q2_clustered, pair_id != 5, cluster == 2))
mod.cluster.3 <- lmer(user_slider ~ set*media*pair_id + (1|user_id:block/set:media),
                        data = filter(res_q2_clustered, pair_id != 5, cluster == 3))
mod.cluster.4 <- lmer(user_slider ~ set*media*pair_id + (1|user_id:block/set:media),
                        data = filter(res_q2_clustered, pair_id != 5, cluster == 4))
mod.cluster.5 <- lmer(user_slider ~ set*media*pair_id + (1|user_id:block/set:media),
                        data = filter(res_q2_clustered, pair_id != 5, cluster == 5))
car::Anova(mod.cluster.1, type = 3) %>% data.frame()

bind_rows(
  car::Anova(mod.cluster.all, type = 3) %>% data.frame() %>% mutate(model = 'all') %>% rownames_to_column(var = 'term'),
  car::Anova(mod.cluster.1, type = 3) %>% data.frame() %>% mutate(model = 'c1') %>% rownames_to_column(var = 'term'),
  car::Anova(mod.cluster.2, type = 3) %>% data.frame() %>% mutate(model = 'c2') %>% rownames_to_column(var = 'term'),
  car::Anova(mod.cluster.3, type = 3) %>% data.frame() %>% mutate(model = 'c3') %>% rownames_to_column(var = 'term'),
  car::Anova(mod.cluster.4, type = 3) %>% data.frame() %>% mutate(model = 'c4') %>% rownames_to_column(var = 'term'),
  car::Anova(mod.cluster.5, type = 3) %>% data.frame() %>% mutate(model = 'c5') %>% rownames_to_column(var = 'term')
) %>%
  janitor::clean_names() %>%
  mutate(pr_chisq = round(pr_chisq, 4)) %>%
  mutate(sig = ifelse(pr_chisq < 0.05, "*", "")) %>%
  select(term, sig, model) %>%
  pivot_wider(names_from = term, values_from = sig)



library(emmeans)
em.all <- emmeans(mod.cluster.all, ~media|set:pair_id)
em.c1  <- emmeans(mod.cluster.1, ~media|set:pair_id)

em.all %>%
  data.frame() %>%
  ggplot(mapping = aes(x = pair_id, y = emmean, fill = media)) +
  geom_col(position = position_dodge())





## -----------------------------------------------------------------------
# I want to see what happens if I take three strong candidates from each possible method

res_q2 %>%
  group_by(user_id, block) %>%
  summarize(corr_ratio = cor(user_slider, target_ratio),
            corr_diffs = cor(user_slider, target_diff),
            corr_sizes = cor(user_slider, target_size)) %>%
  arrange(-corr_sizes)

random <- c('e4ed91f352e11ebe21767afd40fc6cb8',
            '86b67875e21e7d434bf3f29b31406b71',
            '2225f1dc80a8164c419fc542469b24c3')
ratio <- c('58aae8847286cdd92c64512cc75df648',
           'ad77f0143c14addacacff5161e20bfd8',
           '10f5a26c206e890b4c34bc1a32ff98f3')
diffs <- c('9ac7adb2fbb60cb32273f6c7fc8a7e90',
           '205bf71a59c22ca230bcbf31be0d4373',
           '9fd7c7ca2fa26afd0b2ab532442a27c0')

# Strategy switchers: 35f4e2131484e131d0c760cfa29bd0d8, User ID: 3e3a45e2b6960fde4d3e4eae18553a53

res_tmp <- res_q2 %>%
  filter(user_id %in% c(random, ratio, diffs)) %>%
  mutate(ttc = end_time - start_time,
         q1_status = user_larger==true_larger)
set.seed(23123)
fm <- stepFlexmix(user_slider ~ 0 + target_ratio + target_diff | user_id:block,
        data = res_tmp, k = 1:10)

summary(getModel(fm, which.min(AIC(fm))))
parameters(getModel(fm, which.min(AIC(fm))))
plot(fm)

res_tmp %>%
  ungroup() %>%
  mutate(cluster = clusters(getModel(fm, which.min(AIC(fm))))) %>%
  ggplot(mapping = aes(x = target_diff, y = user_slider, group = user_id)) +
  geom_point() +
  geom_smooth(method = 'lm') +
  facet_wrap(~cluster)


names(res_tmp)


res_tmp %>%
  ggplot(mapping = aes(x = ttc)) +
  geom_histogram() + facet_wrap(~user_id)

res_tmp$true_larger

mod <- lmer(user_slider ~ set*media + (0 + target_ratio || user_id:block),
     data = res_tmp)
summary(mod)
ranef(mod)

## -----------------------------------------------------------------------
fm <- stepFlexmix(user_slider ~ target_ratio | user_id,
        k = 1:10,
        data = res_q2)
summary(getModel(fm, which = which.min(BIC(fm))))
parameters(getModel(fm, which = which.min(BIC(fm))))


res_q2 %>%
  ggplot(mapping = aes(x = target_diff, y = user_slider)) +
  geom_point() +
  geom_smooth(aes(group = user_id), se = F, method = 'lm')

ranef(mod)


