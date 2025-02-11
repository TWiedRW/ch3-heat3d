#' Design of the experiment

# Media: 2dd, 3dd, 3dp
# Comparison: BIB to form blocks
# Set: 2

# Each participant is blocked to have 4 comparisons crossed with media and set

set.seed(2026)

pair_id <- 1:9
plan <- agricolae::design.bib(pair_id, k = 4)$book %>%
  as_tibble() %>%
  mutate(block = as.character(block),
         pair_id = as.character(pair_id)) %>%
  type_convert()

# usethis::use_data(plan)

#Function to randomize the trial order
randomize_order <- function(participant_block, plan){
  one_run_fixed = expand_grid(
    set = c('set1', 'set2'),
    media = c('2dd', '3dd', '3dp'),
    pair_id = filter(plan, block == participant_block)$pair_id
  )

  one_run_random = one_run_fixed %>%
    group_by(set, media) %>%
    slice_sample(prop = 1) %>%
    nest() %>%
    ungroup() %>%
    mutate(setxmedia = row_number()) %>%
    slice_sample(prop = 1) %>%
    unnest(data)

  return(one_run_random)

}
