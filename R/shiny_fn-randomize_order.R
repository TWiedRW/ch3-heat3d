# Creates order for subject to complete trials
# Note: similar to split plot with wp as set x media and sp as pair_id

randomize_order <- function(participant_block, plan){

  one_run_fixed <- expand_grid(
    set = c('set1', 'set2'),
    media = c('2dd', '3dd', '3dp'),
    pair_id = dplyr::filter(plan, block == participant_block)$pair_id
  )

  one_run_random <- one_run_fixed %>%
    group_by(set, media) %>%
    slice_sample(prop = 1) %>%
    nest() %>%
    ungroup() %>%
    # mutate(setxmedia = row_number()) %>%
    slice_sample(prop = 1) %>%
    mutate(user_set_order = row_number()) %>%
    unnest(data) %>%
    mutate(user_trial_order = row_number())

  return(one_run_random)
}
