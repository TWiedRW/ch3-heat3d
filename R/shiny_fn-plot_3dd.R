library(rgl)
plot_3dd <- function(base_file, bars_file, letters_file, ...){
  try(close3d())
  open3d()
  par3d(windowRect = c(20, 30, 600, 600))
  readSTL(base_file,
          color = '#F5F5F5', ...)
  readSTL(bars_file,
          color = '#74CCFF', ...)
  readSTL(letters_file,
          color = '#000000', ...)
  rgl::clear3d(type = 'lights')

  # Front and counter clockwise
  light3d(viewpoint.rel = F, phi = -45, theta = 45,
          specular = 'black')
  # Back and counter clockwise
  light3d(viewpoint.rel = F, phi = 45, theta = -45,
          specular = 'black')
}
