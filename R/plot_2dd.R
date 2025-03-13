library(ggplot2)
data('data1')
data('data2')

source('R/add_labels.R')

add_labels(data1, stimuli_labels) %>%
  ggplot(mapping = aes(x, y, fill = z)) +
  geom_tile() +
  geom_text(aes(label = label, color = z+2), color = 'white', size = 5,
            family = 'hyperlegible') +
  scale_fill_continuous(low = '#001222', high = '#019FF2', limits = c(0, 100)) +
  scale_color_continuous(low = 'white', high = 'white', limits = c(0, 102)) +
  theme_void() +
  labs(x = 'Factor 1', y = 'Factor 2') +
  theme(aspect.ratio = 1,
        plot.background = element_rect(fill = 'black'),
        legend.position = 'none',
        axis.title = element_text(family = 'hyperlegible', color = 'white',),
        axis.title.y = element_text(angle = 90, vjust = 0),
        axis.title.x = element_text(vjust = 1))
p1
library(rayshader)
plot_gg(p1, scale = 1000, multicore = T, raytrace = F,
        height = 3, width = 3,
        height_aes = 'fill',
        pointcontract = 1,
        offset_edges = T,
        emboss_text = 1,
        units = 'mm',
        shadow = F, verbose = T,
        solidcolor = 'white')


tmp <- readSTL('print-files/data1-bold.stl')
initial = par3d()
moved = par3d()
map2(initial, moved, \(x,y)(rlang::hash(x)==rlang::hash(y)))


open3d()
readSTL('print-files/rgl-data1-base.stl', color = 'black')
readSTL('print-files/rgl-data1-bars.stl', color = 'cyan')
readSTL('print-files/rgl-data1-letters.stl', color = 'white')
shade3d(color = "#ff00ff", specular = "black")
material3d(isTransparent = T)
close3d()

render_3dd <- function(base_file, bars_file, letters_file, ...){
  try(close3d())
  open3d()
  par3d(windowRect = c(20, 30, 600, 600))
  readSTL(base_file,
          color = '#1D2124', ...)
  readSTL(bars_file,
          color = '#74CCFF', ...)
  readSTL(letters_file,
          color = '#FFFFFF', ...)
}

render_3dd('print-files/rgl-data1-base.stl',
           'print-files/rgl-data1-bars.stl',
           'print-files/rgl-data1-letters.stl')
rgl::clear3d(type = 'lights')
light3d(viewpoint.rel = F, phi = 45, theta = 45,
        specular = 'black')
light3d(viewpoint.rel = F, phi = -45,
        specular = 'black')
light3d(theta = -45, viewpoint.rel = F)
light3d(theta = 45, viewpoint.rel = F)
