set.seed(2026)

#Read template
scad_template <- readLines('print-files/3D-nxn-template.scad')
scad_template
data("stimuli_labels")
#Read data with CMD-Shift-L

#Function that writes an SCAD file based on data and template above
write_scad <- function(data, template, bottom_text){
  require(tidyverse)
  data_name = deparse(substitute(data))

  #Text on bottom of graph
  template[2] <- glue::glue('code = "{bottom_text}";')

  #Combine data with letter pairs
  data2 <- data %>%
    left_join(stimuli_labels, by = c('pair_id', 'within_pair')) %>%
    distinct() %>%
    ungroup()

  #Add values to template in correct format
  tmp_values <- data2 %>%
    select(-c(pair_id, within_pair, label, label_stl)) %>%
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
  tmp_letters <- data2 %>%
    select(x,y,label_stl) %>%
    arrange(x,y) %>%
    pivot_wider(names_from = x, values_from = label_stl) %>%
    select(-y) %>%
    mutate(tmp = pmap(., paste, sep = ','),
           scad_txt = paste0('[', tmp, '],'),
           scad_txt = ifelse(row_number() == max(row_number()),
                             str_remove(scad_txt, ',$'),
                             scad_txt),
           scad_txt = str_replace_all(scad_txt, 'NA', '\"\"'))
  template[20:29] <- tmp_letters$scad_txt

  writeLines(template, paste0('print-files/', data_name, '.scad'))
}
# write_scad(data1, scad_template, 'Sample Text')

#Read and write .scad files from data
# utils::data(data1)
# utils::data(data2)
# utils::data(practice_data)
#
# write_scad(data1, scad_template, 'Set 1')
# write_scad(data2, scad_template, 'Set 2')
# write_scad(practice_data, scad_template, 'Practice')
