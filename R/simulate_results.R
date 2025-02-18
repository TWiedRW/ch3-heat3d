


if(F){
  #Load data
  data("plan")
  data("stimuli_labels")

  library(tidyverse)

  #Set up subject/block info
  subject = data.frame(
    participant = 0, #Filter this out, only needed for initial block sampling
    block = unique(plan$block)
  )

  #All blocks
  possible_blocks <- unique(plan$block)

  #Store results
  results <- data.frame()

  #True values for stimuli
  truth = stimuli %>%
    mutate(correct = map2_dbl(values, constant, \(x,y)(100*min(c(x,y))/max(c(x,y)))))

  #Simulate results
  for(i in 1:100){
    participant = i
    blocks_used = as.numeric((table(subject$block)))
    block = sample(x = possible_blocks,
                   size = 1,
                   prob = 1/blocks_used)


    participant_run = randomize_order(block, plan) %>%
      mutate(participant = participant,
             block = block)
    participant_answer = participant_run %>%
      left_join(truth, by = 'pair_id') %>%
      mutate(guess = map_dbl(correct, \(x)(min(rnorm(1, mean = x, sd = 3), 100)))) #maximum entry is 100

    #Update tables
    subject <- bind_rows(subject, data.frame(participant, block))
    results <- bind_rows(results, participant_answer)
  }




  #Plots
  ggplot(results, aes(x = correct, y = guess)) +
    geom_point(position = position_jitter(height = 0, width = 1),
               alpha = 1/10) +
    # scale_x_continuous(limits = c(0, 102)) +
    scale_y_continuous(limits = c(0, 100))


  library(lme4)
  model <- lmer(guess ~ set*media*factor(pair_id) + (1|block/participant),
                data = results)

  library(emmeans)
  em <- emmeans(model, ~set*media*pair_id)
  plot(em)
}
