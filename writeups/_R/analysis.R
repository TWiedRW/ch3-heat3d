library(tidyverse)
library(lme4)
library(lmerTest)
results <- read_csv('writeups/_data/stat218fall2025.csv')

# Q1

mod1 <- glmer(q1_correct ~ set*media*pair_id + (1|user_id/set:media),
      family = binomial(link = 'logit'),
      control = glmerControl(optimizer = 'nlminbwrap'),
      data = results)
summary(mod1)
anova(mod1)

car::Anova(mod1, type='III')
