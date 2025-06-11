plot_2dd <- function(data, stimuli_labels, low_color, high_color){
  library(showtext)
  # Register both regular and bold weights for Atkinson Hyperlegible
  font_add_google("Atkinson Hyperlegible", "Atkinson Hyperlegible", regular.wt = 400, bold.wt = 700)
  showtext_auto()
  data %>%
    left_join(stimuli_labels, by = c('pair_id', 'within_pair')) %>%
    ggplot(mapping = aes(x = x, y = y, fill = z)) +
    geom_tile() +
    # Use fontface = "bold" to get the bold version
    geom_text(aes(label = label), color = 'black', na.rm = TRUE, 
      family = 'Atkinson Hyperlegible', fontface = "bold", size = 10) +
    scale_fill_gradient(low = '#0C2841', high = '#66D9FF', #limits = c(0, 100),
                        labels = c('Smallest Value', 'Largest Value'), breaks = c(min(data$z), max(data$z)))+
    labs(x = 'Factor 1', y = 'Factor 2', fill = '') +
    theme_minimal() +
    theme(aspect.ratio = 1, panel.grid = element_blank(),
          # legend.position = 'none',
          legend.title = element_text(vjust = 1),
          axis.text = element_blank(),
          axis.title = element_text(size = 20, color = 'black', family = 'Atkinson Hyperlegible', face = "bold"),
          plot.background = element_rect(fill = 'white', color = 'white'))
}
