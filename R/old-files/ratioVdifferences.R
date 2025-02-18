if(F){
  library(plot3D)
  library(tidyverse)

  # Unrestricted Combinations
  s = 1*(1:100)
  stimuli <- expand.grid(x = s, y = s) %>%
    filter(x<=y) %>%
    mutate(difference = y - x,
           ratio = x/y*100)

  with(stimuli, scatter3D(x, y, ratio,
                          theta = 200,
                          phi = 30
  ))

  library(rgl)
  with(stimuli, rgl::plot3d(x, y, ratio, theta = -90, phi = 15,
                            size = 6))
  with(stimuli, rgl::plot3d(x, y, difference, theta = -90, phi = 15,
                            size = 6))


  stimuli %>%
    pivot_longer(difference:ratio, names_to = 'comparison') %>%
    mutate(col = ifelse(comparison == 'ratio', 'red', 'blue')) %>%
    with(., plot3d(x, y, value, col = col, size = 6))


  # response_ratio <- function(x,y)(x/y*100)
  # response_diff <- function(x,y)(y-x)
  #
  # with(stimuli, persp3D(x, y, outer(x,y,'response_diff'),
  #                       theta = 270-30, phi = 15))
  # with(stimuli, persp3D(x, y, outer(x,y,'response_ratio'),
  #                       theta = 270-30, phi = 15))

  # tmp <- outer(stimuli$x, stimuli$y, 'response_diff')
  # rownames(tmp) <- stimuli$x; colnames(tmp) <- stimuli$y
  s = 10*(1:10)
  stimuli <- expand.grid(x = s, y = s) %>%
    filter(x <= y) %>%
    mutate(difference = y - x,
           ratio = x/y*100)
  library(ggrepel)
  p1 <- ggplot(stimuli, aes(x = difference, y = ratio)) +
    geom_point(alpha = 1/1) +
    geom_text_repel(aes(label = paste0('(',x,', ',y,')')),
                    alpha = 1/2, size = 2, max.overlaps = 100) +
    # geom_smooth() +
    scale_x_continuous(breaks = 10*(0:10)) +
    scale_y_continuous(breaks = 10*(0:10)) +
    theme_bw()
  p1
  # library(plotly)
  #
  # ggplotly(p1)




  library(tidyverse)


  x = 10*10^((1:10-1)/9)
  stimuli.cm <- expand.grid(smaller = x, larger = x) %>%
    filter(smaller <= larger) %>%
    mutate(difference = larger - smaller,
           ratio = smaller/larger*100)
  stimuli.cm
  sort(unique(round(stimuli.cm$ratio, 3)))
  sort(unique(round(stimuli.cm$difference, 3)))

  ggplot(stimuli.cm, aes(x = difference, y = ratio)) +
    geom_point() +
    scale_x_continuous(breaks = 10*(0:10), limits = c(0,100)) +
    scale_y_continuous(breaks = 10*(0:10), limits = c(0,100)) +
    theme_bw()
  x
}
