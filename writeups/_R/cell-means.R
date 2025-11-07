library(tidyverse)
library(lme4)
library(lmerTest)

df <- read_csv('writeups/_data/stat218fall2025.csv')

q2 <- df %>%
  filter(q1_correct, pair_id != 5, set != 'practice')

mod <- lmer(log(q2_abs_error) ~ 0 + set:media:factor(pair_id) + (1|user_id/set:media),
     data = q2)
plot(mod)
anova(mod)
summary(mod)
library(emmeans)
pairs(emmeans(mod, ~set:media:pair_id, type = 'response')) %>%
  data.frame() %>%
  filter(p.value < 0.05)
