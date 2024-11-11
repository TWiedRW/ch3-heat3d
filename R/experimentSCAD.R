set.seed(2026)

#Read template
scad_template <- readLines('3D-nxn-template.scad')
scad_template

#Read data with CMD-Shift-L

#Function that writes an SCAD file based on data and template above
write_scad <- function(data, template){
  require(tidyverse)
  data_name = deparse(substitute(data))

  #Letters for pairs
  good_letters <- sample(c(1,2,4,5,6,7,8,13,14,18))
  L <- LETTERS[good_letters]
  l <- letters[good_letters]
  tbl_good_letters <- tibble(pair_id = seq_along(good_letters)) %>%
    mutate(p1 = L[pair_id],
           p2 = l[pair_id]) %>%
    pivot_longer(p1:p2, names_to = 'within_pair', values_to = 'label') %>%
    mutate(label = paste0('\"',label,'\"'),
           pair_id = as.character(pair_id))

  #Combine data with letter pairs
  data <- data %>%
    group_by(pair_id) %>%
    mutate(within_pair = ifelse(!is.na(pair_id),
                                sample(c('p1', 'p2'), 2),
                                NA),
           pair_id = as.character(pair_id)) %>%
    ungroup() %>%
    left_join(tbl_good_letters, by = c('pair_id', 'within_pair')) %>%
    mutate(pair_id = label) %>%
    select(-c(within_pair, label))

  #Add values to template in correct format
  tmp_values <- data %>%
    select(-pair_id) %>%
    arrange(x,y) %>%
    pivot_wider(names_from = x, values_from = z) %>%
    select(-y) %>%
    mutate(tmp = pmap(., paste, sep = ','),
           scad_txt = paste0('[', tmp, '],'),
           scad_txt = ifelse(row_number() == max(row_number()),
                             str_remove(scad_txt, ',$'),
                             scad_txt))
  template[6:15] <- tmp_values$scad_txt

  #Add pair_id letters to template
  tmp_letters <- data %>%
    select(-z) %>%
    arrange(x,y) %>%
    pivot_wider(names_from = x, values_from = pair_id) %>%
    select(-y) %>%
    mutate(tmp = pmap(., paste, sep = ','),
           scad_txt = paste0('[', tmp, '],'),
           scad_txt = ifelse(row_number() == max(row_number()),
                             str_remove(scad_txt, ',$'),
                             scad_txt),
           scad_txt = str_replace_all(scad_txt, 'NA', '\"\"'))
  template[20:29] <- tmp_letters$scad_txt

  writeLines(template, paste0(data_name, '.scad'))
}


#Read and write .scad files from data
# utils::data(data1)
# utils::data(data2)
# utils::data(data3)
# utils::data(data4)
#
# write_scad(data1, scad_template)
# write_scad(data2, scad_template)
# write_scad(data3, scad_template)
# write_scad(data4, scad_template)



#Plotting functions for testing purposes
# library(rgl)
# try(close3d())
# readSTL('data1.stl', color = 'red')
#
# p <- data1 %>%
#   mutate(pair_id = str_remove_all(pair_id, regex('\\W'))) %>%
#   ggplot(mapping = aes(x = x, y = y, label = pair_id,
#                        fill = z)) +
#   geom_tile() +
#   geom_text() +
#   scale_fill_viridis_c(limits = c(0, 100)) +
#   theme_bw() +
#   theme(aspect.ratio = 1)
# p
# rayshader::plot_gg(p, raytrace = F, scale = 400)

readSTL('data1.stl', color = 'cyan')
view3d(phi=198, theta=0)
close3d()
