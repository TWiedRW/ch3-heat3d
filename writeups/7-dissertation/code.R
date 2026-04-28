
library(tidyverse)
library(lme4)
library(lmerTest)
library(emmeans)
library(kableExtra)

load('../../data/stimuli.rda')
load('../../data/data1.rda')
load('../../data/data2.rda')
set.seed(3141)

# Data from Shiny app
library(RSQLite)
conn <- dbConnect(SQLite(), "../../shiny-apps/experiment-heat3d/data/stat218-summer2025.db")
# dbListTables(conn)
blocks <- dbReadTable(conn, "blocks")
exp_results <- dbReadTable(conn, "exp_results")
users <- dbReadTable(conn, "users")
dbDisconnect(conn)

# Solutions
solutions <- readRDS("../../data/solutions.rda")
load("../../data/data1.rda")
load("../../data/data2.rda")

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



## -------------------------------------------------------------
# Combine users and results, remove all "test" entries
users_clean <- results %>%
  inner_join(users, by = 'user_id', relationship = 'many-to-many') %>%
  select(user_id, user_age:user_unique) %>%
  distinct() %>%
  dplyr::filter(!str_detect(tolower(user_unique), 'test,'))


## -------------------------------------------------------------
# Get in-person users (have at least 1 3dp trial)
users_in_person <- users_clean %>%
  inner_join(results) %>%
  group_by(user_id, media) %>%
  summarise(n = n()) %>%
  filter(media == '3dp' & n > 0) %>%
  select(user_id)


## -------------------------------------------------------------
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



## -------------------------------------------------------------
df_time <- res_q2 %>%
  group_by(user_id, block) %>%
  summarise(total_time = (max(end_time)-min(start_time))/60)

median_time_in_person <- df_time %>% filter(user_id %in% users_in_person$user_id) %>%
  pull(total_time) %>%
  median()

median_time_online <- df_time %>% filter(!(user_id %in% users_in_person$user_id)) %>%
  pull(total_time) %>%
  median()


## -------------------------------------------------------------

df_time_grouped <- df_time %>%
  mutate(Section = ifelse(user_id %in% users_in_person$user_id, 'In-person', 'Online')) %>%
  group_by(Section) %>%
  summarise(Mean = mean(total_time),
            SD = sd(total_time),
            Median = median(total_time))
df_time_total <- df_time %>%
  mutate(Section = 'All Participants') %>%
  group_by(Section) %>%
  summarise(Mean = mean(total_time),
            SD = sd(total_time),
            Median = median(total_time))


## -------------------------------------------------------------
#| fig-width: 6
#| fig-height: 4
#| fig-dpi: 600
#| fig-cap: "Three potential estimation strategies from participants. Many participants followed instructions to estimate ratios. However, some participants appeared to estimate the difference between stimuli pairs or submitted random values."
#| fig-scap: "Examples of participant estimation strategies"
#| label: fig-user-strategies

# results %>%
#   group_by(user_id) %>%
#   summarize(corr_ratio = cor(user_slider, target_ratio)) %>%
#   arrange(-corr_ratio)



## -------------------------------------------------------------
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




## ----appendix-setup, message=FALSE, warning=FALSE, echo = F----
library(tidyverse)


## -------------------------------------------------------------
#| fig-height: 3
#| fig-cap: "Counts of response behavior for Stimuli Pair 5. This pair had identical values, which means that true solutions indicates marking that they were the same value and positioning the slider at 100."
#| fig-scap: "Response behavior for identical-value stimuli pair"
#| label: fig-pair5-issues
infilter.labs <- c('Included Participants', 'Excluded Participants')
names(infilter.labs) <- c(TRUE, FALSE)

res_q2 %>%
  filter(pair_id == 5) %>%
  mutate(infilter = user_id %in% res_q2_filtered$user_id) %>%
  group_by(q1_correct = user_larger == true_larger,
           slider100 = user_slider == 100,
           infilter) %>%
  count() %>%
  arrange(infilter, q1_correct) %>%
  ggplot(mapping = aes(x = slider100, y = n, fill = q1_correct)) +
  geom_col(position = position_dodge()) +
  geom_text(aes(label = n, y = n+8), position = position_dodge(width = 1),
            size = 3) +
  labs(x = 'Slider position', y = 'Count',
       fill = 'Correct solution\nto Q1?') +
  facet_wrap(~infilter, labeller = labeller(infilter = infilter.labs)) +
  scale_fill_manual(labels = c("No", "Yes"),
                    values = c('#b8b8b8', '#1a80bb')) +
  scale_x_discrete(labels = c('Not at 100', 'At 100')) +
  theme_bw() +
  theme(aspect.ratio = 1, legend.position = 'bottom')


## -------------------------------------------------------------
# Format: mod_(participant)_(response)

# All participants
mod_all_all <- lmer(q2_error_cm ~ set*media*pair_id + (1|user_id:block/set:media),
     data = filter(res_q2, pair_id != 5))
mod_all_q1 <- lmer(q2_error_cm ~ set*media*pair_id + (1|user_id:block/set:media),
     data = filter(res_q2, pair_id != 5 & user_larger == true_larger))

# Filtered participants
mod_q1_all <- lmer(q2_error_cm ~ set*media*pair_id + (1|user_id:block/set:media),
     data = filter(res_q2_filtered, pair_id != 5))
mod_q1_q1 <- lmer(q2_error_cm ~ set*media*pair_id + (1|user_id:block/set:media),
     data = filter(res_q2_filtered, pair_id != 5 & user_larger == true_larger))




## -------------------------------------------------------------
#| eval: true
bind_rows(
  car::Anova(mod_all_all, type = 3, test = 'F') %>%
  data.frame() %>%
  janitor::clean_names() %>%
  rownames_to_column('effect'),
  car::Anova(mod_all_q1, type = 3, test = 'F') %>%
  data.frame() %>%
  janitor::clean_names() %>%
  rownames_to_column('effect'),
  car::Anova(mod_q1_all, type = 3, test = 'F') %>%
  data.frame() %>%
  janitor::clean_names() %>%
  rownames_to_column('effect'),
  car::Anova(mod_q1_q1, type = 3, test = 'F') %>%
  data.frame() %>%
  janitor::clean_names() %>%
  rownames_to_column('effect'),
  .id = 'model'
) %>%
  filter(effect != '(Intercept)') %>%
  select(model, effect, pr_f) %>%
  pivot_wider(names_from = effect, values_from = pr_f) %>%
  mutate(across(where(is.numeric), round, 3)) %>%
  mutate(model = case_when(
    model=='1' ~ 'All participants, all responses',
    model=='2' ~ 'All participants, Q1 correct',
    model=='3' ~ 'Filtered participants, all responses',
    model=='4' ~ 'Filtered participants, Q1 correct'
  )) %>%
  column_to_rownames('model') %>%
  t() %>%
  as.data.frame() %>%
  rownames_to_column('Term') %>%
  kable(caption = 'ANOVA Table p-values for model terms', digits = 3, booktabs = T,
        label = 'tbl-all-models-anova')


# car::Anova(mod_all_all, type = 3, test = 'F')
# car::Anova(mod_all_q1, type = 3, test = 'F')
# car::Anova(mod_q1_all, type = 3, test = 'F')
# car::Anova(mod_q1_q1, type = 3, test = 'F')


## -------------------------------------------------------------
#| fig-height: 8
em_all_all <- emmeans(mod_all_all, ~media+set+pair_id, pbkrtest.limit = 5800)
em_all_q1 <- emmeans(mod_all_q1, ~media+set+pair_id, pbkrtest.limit = 5800)
em_q1_all <- emmeans(mod_q1_all, ~media+set+pair_id, pbkrtest.limit = 5800)
em_q1_q1 <- emmeans(mod_q1_q1, ~media+set+pair_id, pbkrtest.limit = 5800)


## -------------------------------------------------------------
#| eval: true
#| label: fig-model-int1
#| fig-width: 6
#| fig-height: 6
#| fig-dpi: 600
#| fig-cap: "Interaction plots for media type and response filtering, facetted by stimuli pair and dataset."
#| fig-scap: "Media by filtering interaction effects"


bind_rows(
  data.frame(em_all_all),
  data.frame(em_all_q1),
  data.frame(em_q1_all),
  data.frame(em_q1_q1),
  .id = 'model'
) %>%
  mutate(model = case_when(
    model=='1' ~ 'All participants, all responses',
    model=='2' ~ 'All participants, Q1 correct',
    model=='3' ~ 'Filtered participants, all responses',
    model=='4' ~ 'Filtered participants, Q1 correct'
  )) %>%
  ggplot(mapping = aes(x = media, y = emmean, color = model, group = model)) +
  geom_point(size = 1) +
  geom_line() +
  facet_wrap(~set+pair_id, labeller = label_both) +
  # facet_grid(set ~ pair_id) +
  # facet_grid(pair_id ~ set) +
  theme_bw() +
  guides(color=guide_legend(nrow=2,byrow=TRUE)) +
  theme(aspect.ratio = 1/2,
        legend.position = 'bottom')


## -------------------------------------------------------------
#| eval: true
#| label: fig-model-int2
#| fig-width: 6
#| fig-dpi: 600
#| fig-cap: "Interaction plots for dataset and response filtering, facetted by stimuli pair and media type."
#| fig-scap: "Data set by filtering interaction effects"


bind_rows(
  data.frame(em_all_all),
  data.frame(em_all_q1),
  data.frame(em_q1_all),
  data.frame(em_q1_q1),
  .id = 'model'
) %>%
  mutate(model = case_when(
    model=='1' ~ 'All participants, all responses',
    model=='2' ~ 'All participants, Q1 correct',
    model=='3' ~ 'Filtered participants, all responses',
    model=='4' ~ 'Filtered participants, Q1 correct'
  )) %>%
  ggplot(mapping = aes(x = set, y = emmean, color = model, group = model)) +
  geom_point(size = 1) +
  geom_line() +
  facet_grid(media~pair_id, labeller = label_both) +
  # facet_grid(set ~ pair_id) +
  # facet_grid(pair_id ~ set) +
  theme_bw() +
  guides(color=guide_legend(nrow=2,byrow=TRUE)) +
  theme(aspect.ratio = 1/1,
        strip.text.y = element_text(size = 6),
        legend.position = 'bottom')


## -------------------------------------------------------------
#| eval: true
#| label: fig-model-int3
#| fig-width: 6
#| fig-dpi: 600
#| fig-cap: "Interaction plots for stimuli pairs and response filtering, facetted by dataset and media type."
#| fig-scap: "Stimuli pair by filtering interaction effects"


bind_rows(
  data.frame(em_all_all),
  data.frame(em_all_q1),
  data.frame(em_q1_all),
  data.frame(em_q1_q1),
  .id = 'model'
) %>%
  mutate(model = case_when(
    model=='1' ~ 'All participants, all responses',
    model=='2' ~ 'All participants, Q1 correct',
    model=='3' ~ 'Filtered participants, all responses',
    model=='4' ~ 'Filtered participants, Q1 correct'
  )) %>%
  ggplot(mapping = aes(x = pair_id, y = emmean, color = model, group = model)) +
  geom_point(size = 1) +
  geom_line() +
  facet_grid(set~media, labeller = label_both) +
  # facet_grid(set ~ pair_id) +
  # facet_grid(pair_id ~ set) +
  theme_bw() +
  guides(color=guide_legend(nrow=2,byrow=TRUE)) +
  theme(aspect.ratio = 1/1,
        # strip.text.y = element_text(size = 6),
        legend.position = 'bottom')


## -------------------------------------------------------------
#| cache: true
# GAM
library(mgcv)
library(gratia)
mod_gam <- gam(
  q2_error_cm ~
    set*media +
    s(target_ratio, k = 4, by = media) +
    s(target_ratio, k = 4, by = set) +
    s(user_id, bs='re'),
  method = 'REML',
  data = filter(res_q2, pair_id != 5 & user_larger == true_larger) %>%
    mutate(set = factor(set),
           media = factor(media),
           user_id = factor(user_id))
)
gam_sum <- summary(mod_gam)



## -------------------------------------------------------------
#| cache: true
mod_gam_flt <- gam(
  q2_error_cm ~
    set*media +
    s(target_ratio, k = 4, by = media) +
    s(target_ratio, k = 4, by = set) +
    s(user_id, bs='re'),
  method = 'REML',
  data = filter(res_q2_filtered, pair_id != 5 & user_larger == true_larger) %>%
    mutate(set = factor(set),
           media = factor(media),
           user_id = factor(user_id))
)


## -------------------------------------------------------------
gam_sum <- summary(mod_gam)
gam_sum2 <- summary(mod_gam_flt)

gam_sum$p.table %>% knitr::kable(digits = 3, caption = "Parametric coefficients in gam model with all participants.", label = "gam-param1", booktabs = T)

gam_sum$s.table %>% as.data.frame() %>%
  mutate(Smooth = rownames(.),
         Smooth = str_replace(Smooth, "ratio_prop", "Ratio")) %>%
  select(Smooth, everything()) %>%
  knitr::kable(digits = 3, row.names = F, caption = "Approximate significance of smooth terms in gam mode with all participants.", label = "gam-smooth1", booktabs = T)

gam_sum$p.table %>% knitr::kable(digits = 3, caption = "Parametric coefficients in gam model without random guessers.", label = "gam-param2", booktabs = T)

gam_sum$s.table %>% as.data.frame() %>%
  mutate(Smooth = rownames(.),
         Smooth = str_replace(Smooth, "ratio_prop", "Ratio")) %>%
  select(Smooth, everything()) %>%
  knitr::kable(digits = 3, row.names = F, caption = "Approximate significance of smooth terms in gam model without random guessers.", label = "gam-smooth2", booktabs = T)


## -------------------------------------------------------------
em_gam1 <- emmeans(mod_gam, ~media|set)
em_gam2 <- emmeans(mod_gam_flt, ~media|set)

bind_rows(
  em_gam1 %>% data.frame() %>% mutate(flt = 'All participants'),
  em_gam2 %>% data.frame() %>% mutate(flt = 'Random guessers removed')
) %>%
  select(`Data filtering` = flt, set, emmean:upper.CL) %>%
  kbl(caption = 'Estimated marginal means for generalized additive model', digits = 3,
      booktabs = T, label = 'tbl-gam-emmeans') %>%
  collapse_rows()



## -------------------------------------------------------------
bind_rows(
  pairs(em_gam1) %>% data.frame() %>% mutate(flt = 'All participants'),
  pairs(em_gam2) %>% data.frame() %>% mutate(flt = 'Random guessers removed')
) %>%
  select(`Data filtering` = flt, set, contrast, estimate:p.value) %>%
  kbl(caption = 'Pairwise differences for generalized additive model', digits = 3,
      booktabs = T, label = 'tbl-gam-diffs') %>%
  collapse_rows()



## -------------------------------------------------------------
knitr::purl(input = 'index.qmd', output = 'code.R')

