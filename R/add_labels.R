#Quick function to add labels to data

add_labels <- function(data, stimuli_labels){
  data %>%
    left_join(stimuli_labels, by = c('pair_id', 'within_pair'))
}



