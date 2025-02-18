#' Define labels across datasets
#'
#'

set.seed(2022)
data("stimuli")
#Letters for pairs
good_letters <- sample(c(1,2,4,5,6,7,8,13,14,18))
L <- LETTERS[good_letters]
l <- letters[good_letters]
tbl_good_letters <- tibble(pair_id = seq_along(good_letters)) %>%
  mutate(p1 = L[pair_id],
         p2 = l[pair_id]) %>%
  pivot_longer(p1:p2, names_to = 'within_pair', values_to = 'label') %>%
  mutate(label_stl = paste0('\"',label,'\"'),
         pair_id = pair_id)

#Combine stimuli with labels
stimuli_labels <- stimuli %>%
  pivot_longer(values:constant, values_to = 'z', names_to = 'setting') %>%
  group_by(pair_id) %>%
  mutate(within_pair = sample(c('p1','p2'))) %>%
  left_join(tbl_good_letters, by = c('pair_id', 'within_pair')) %>%
  select(pair_id, within_pair, label, label_stl) %>%
  ungroup()


#Change to T if you need to replace stimuli labels
if(T) usethis::use_data(stimuli_labels, overwrite = T)
