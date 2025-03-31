plot_2dd <- function(data){
  data %>%
    left_join(stimuli_labels, by = c('pair_id', 'within_pair')) %>%
    ggplot(mapping = aes(x = x, y = y, fill = z)) +
    geom_tile() +
    geom_text(aes(label = label), color = 'white') +
    scale_fill_gradient(low = '#0C2841', high = '#66D9FF') +
    labs(x = 'Factor 1', y = 'Factor 2') +
    theme_minimal() +
    theme(aspect.ratio = 1, panel.grid = element_blank(),
          legend.position = 'none',
          axis.title = element_text(color = 'white'),
          axis.text = element_blank(),
          plot.background = element_rect(fill = '#1D1E23'))
}

plot_2dd(data1)
