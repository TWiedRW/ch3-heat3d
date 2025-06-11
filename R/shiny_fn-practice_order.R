# Creates order for practice run

practice_order <- function(plan){

    one_run_fixed <- expand_grid(
      set = c('practice'),
      media = c('2dd', '3dd'),
      pair_id = sample(1:max(plan$pair_id), 2)
    ) %>%
    group_by(set, media) %>%
    # slice_sample(prop = 1) %>%
    nest() %>%
    ungroup() %>%
    #slice_sample(prop = 1) %>%
    mutate(user_set_order = row_number()) %>%
    unnest(data) %>%
    mutate(user_trial_order = row_number())

  return(one_run_fixed)
}
# practice_order()
