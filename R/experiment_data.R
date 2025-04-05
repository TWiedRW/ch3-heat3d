#Set to T to simulate new data
if(F){
  set.seed(2026)

  data1 <- generate_heatmap_data(f = \(x,y)(sqrt(7^2-(x-mean(x))^2-(y-mean(y))^2)), stimuli = stimuli)
  data2 <- generate_heatmap_data(f = \(x,y)(sqrt(7^2+(x-mean(x))^2+(y-mean(y))^2)), stimuli = stimuli)
  practice_data <- generate_heatmap_data(f = \(x,y)(x + y), stimuli = stimuli)


  usethis::use_data(data1, overwrite = T)
  usethis::use_data(data2, overwrite = T)
  usethis::use_data(practice_data, overwrite = T)

}
