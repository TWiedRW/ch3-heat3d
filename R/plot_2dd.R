library(ggplot2)
data('data1')
data('data2')


p1 <- data1 %>%
  left_join(stimuli_labels, by = c('pair_id', 'within_pair')) %>%
  ggplot(mapping = aes(x, y, fill = z)) +
  geom_tile() +
  geom_text(aes(label = label, color = z+2), color = 'black', size = 5,
            family = 'hyperlegible') +
  scale_fill_continuous(low = '#001222', high = '#019FF2', limits = c(0, 100)) +
  scale_color_continuous(low = 'white', high = 'white', limits = c(0, 102)) +
  theme_void() +
  labs(x = 'Factor 1', y = 'Factor 2') +
  theme(aspect.ratio = 1,
        plot.background = element_rect(fill = 'white'),
        legend.position = 'none',
        axis.title = element_text(family = 'hyperlegible', color = 'white',),
        axis.title.y = element_text(angle = 90, vjust = 0),
        axis.title.x = element_text(vjust = 1))
p1

