library(tidyverse)
set.seed(21012)
block <- 1:18
user_id <- 1:10
set <- c('set1', 'set2')
media <- c('2dd', '3dd', '3dp')
pair_id <- c(1:4,6:9)
load('data/plan.rda')

sim <- expand_grid(
  block,
  user_id,
  set,
  media,
  pair_id
) %>%
  inner_join(plan, by = c('block', 'pair_id')) %>%
  mutate(user_id = paste(block, user_id, sep = '-')) %>%
  mutate(e.intercept = 2.7521,
         e.set1 = ifelse(set == 'set1', -0.04236, 0),
         e.media = case_when(media == '2dd' ~ 0.2441,
                             media == '3dd' ~ 0.04592,
                             .default = 0),
         e.pair_id = case_when(pair_id == 1 ~ 0.02486,
                               pair_id == 2 ~ 0.06779,
                               pair_id == 3 ~ 0.00783,
                               pair_id == 4 ~ 0.02494,
                               pair_id == 6 ~ 0.1588,
                               pair_id == 7 ~ 0.02002,
                               pair_id == 8 ~ 0.02986,
                               pair_id == 9 ~ 0
                               )) %>%
  group_by(block) %>%
  mutate(e.block = rnorm(1, 0.001612, 0.01470)) %>%
  group_by(block, user_id) %>%
  mutate(e.user_id_block = rnorm(1, 0.3810, 0.04646)) %>%
  ungroup() %>%
  mutate(lp = e.intercept + e.set1 + e.media + e.pair_id + e.block + e.user_id_block,
         y = rgamma(nrow(.), shape = lp, scale = 1/0.7658))



library(lme4)
mod <- glmer(y ~ set + media + factor(pair_id) + (1|block/user_id),
             data = sim)
summary(mod)
plot(mod)
