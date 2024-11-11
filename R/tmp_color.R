# https://stackoverflow.com/questions/70003908/colour-contrast-checker-in-r-for-more-than-2-colours
# Minimum contrast for text WCAG Level AAA: 7:1
library(tidyverse)
RColorBrewer::brewer.pal.info
x = viridis::viridis(n = 10)
y = rep(1, times = length(x))

greyscale <- tibble(
  hexcodeg = colorRampPalette(c("black", "white"))(1000)) %>%
  mutate(rgb = map(hexcodeg, \(x) as_tibble(t(col2rgb(x))))) %>%
  unnest(rgb) %>%
  mutate(R = ifelse(red<=0.04045, red/12.92, ((red+0.055)/1.055)^2.4),
         G = ifelse(green<=0.04045, green/12.92, ((green+0.055)/1.055)^2.4),
         B = ifelse(blue<=0.04045, blue/12.92, ((blue+0.055)/1.055)^2.4)) %>%
  mutate(L = 0.2126 * R + 0.7152 * G + 0.0722 * B)

virpal <- tibble(hexcode = x) %>%
  mutate(rgb = map(hexcode, \(x) as_tibble(t(col2rgb(x))))) %>%
  unnest(rgb) %>%
  mutate(R = ifelse(red<=0.04045, red/12.92, ((red+0.055)/1.055)^2.4),
         G = ifelse(green<=0.04045, green/12.92, ((green+0.055)/1.055)^2.4),
         B = ifelse(blue<=0.04045, blue/12.92, ((blue+0.055)/1.055)^2.4)) %>%
  mutate(L = 0.2126 * R + 0.7152 * G + 0.0722 * B) %>%
  mutate(Llighter = 7*(L+0.05)-0.05,
         Ldarker = (L+0.05)/7-0.05)

save <- virpal %>%
  rowwise() %>%
  mutate(Lg1 = greyscale$L[which.min(abs(Llighter-greyscale$L))],
         Lg2 = greyscale$L[which.min(abs(Ldarker-greyscale$L))]) %>%
  left_join(dplyr::select(greyscale, hexcodeg, L), by = c('Lg1'='L')) %>%
  left_join(dplyr::select(greyscale, hexcodeg, L), by = c('Lg2'='L')) %>%
  mutate(color = ifelse(L>Lg1, hexcodeg.x, hexcodeg.y))

save


ggplot(save, aes(x = hexcode, y = 1, fill = hexcode)) +
  geom_raster() +
  geom_text(aes(label = hexcodeg.x, color = hexcodeg.x)) +
  scale_fill_manual(values = x) +
  scale_color_manual(values = save$hexcodeg.x)


ggplot(save, aes(x = L, y = Lg2)) +
  geom_point() +
  geom_abline(slope = 1)



ggplot(mapping = aes(x = x, y = 1, fill = x)) +
  geom_raster() +
  scale_fill_manual(values = x)
