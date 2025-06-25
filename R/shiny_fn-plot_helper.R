plot_helper <- function(data, trial_pair_id, stimuli_labels){
  data %>%
    mutate(pair_id = ifelse(pair_id == trial_pair_id, pair_id, NA)) %>%
    left_join(stimuli_labels, by = join_by(pair_id, within_pair)) %>%
    ggplot(mapping = aes(x = x, y = y, fill = factor(pair_id))) +
    geom_tile(color = 'black') +
    geom_text(aes(label = label), na.rm = T) +
    labs(x = 'Factor 1', y = 'Factor 2',
         title = 'Location of values to compare') +
    theme_minimal() +
    theme(aspect.ratio = 1,
          legend.position = 'none',
          panel.grid = element_blank(),
          axis.text = element_blank(),
          plot.title = element_text(hjust = 0.5, vjust = 0))
}
