plot_2dd <- function(data, low_color, high_color){
  data %>%
    left_join(stimuli_labels, by = c('pair_id', 'within_pair')) %>%
    ggplot(mapping = aes(x = x, y = y, fill = z)) +
    geom_tile() +
    geom_text(aes(label = label), color = 'black', na.rm = T) +
    scale_fill_gradient(low = '#0C2841', high = '#66D9FF') +
    labs(x = 'Factor 1', y = 'Factor 2') +
    theme_minimal() +
    theme(aspect.ratio = 1, panel.grid = element_blank(),
          legend.position = 'none',
          axis.title = element_text(color = 'black'),
          axis.text = element_blank(),
          plot.background = element_rect(fill = 'white', color = 'white'))
}
