generate_completion_code <- function(valid_words){
  if(F){
    # Set to true if you want to rerun. Only here for historical context
    # Sources: dictionary of my 2021 M1 MacBook Pro
    #          Carnegie Mellon University CS program (bad words)
    #          tm package (stop words)
    #          movies.fandom.com (movie transcripts)
    # Idea: words are from the Star Wars prequel series, filtered out bad words,
    #       stop words, and words not in my computer's dictionary
    all_words <- read.table('/usr/share/dict/web2',
                            header = F)$V1
    bad_words <- read.table('https://www.cs.cmu.edu/~biglou/resources/bad-words.txt')$V1


    require(rvest)
    require(tidyverse)
    url <- 'https://movies.fandom.com/wiki/Star_Wars:_Episode_I_–_The_Phantom_Menace/Transcript'

    e1.text <- read_html(url) %>%
      html_elements(xpath = '//*[@id="mw-content-text"]/div') %>%
      html_text() %>%
      stringr::str_replace_all('\n', ' ')

    url2 <- 'https://movies.fandom.com/wiki/Star_Wars:_Episode_II_–_Attack_of_the_Clones/Transcript'
    e2.text <- read_html(url2) %>%
      html_elements(xpath = '//*[@id="mw-content-text"]/div') %>%
      html_text() %>%
      stringr::str_replace_all('\n', ' ')

    url3 <- 'https://movies.fandom.com/wiki/Star_Wars:_Episode_III_-_Revenge_of_the_Sith/Transcript'
    e3.text <- read_html(url3) %>%
      html_elements(xpath = '//*[@id="mw-content-text"]/div') %>%
      html_text() %>%
      stringr::str_replace_all('\n', ' ')

    valid_words <- tibble(text = c(e1.text, e2.text, e3.text)) %>%
      mutate(text = str_remove_all(tolower(text), '[[:punct:]]')) %>%
      mutate(token = str_split(text, '\\s+')) %>%
      unnest(cols = c(token)) %>%
      count(token) %>%
      filter(!(token %in% tm::stopwords()),
             !(token %in% bad_words),
             !str_detect(token, '[0-9]'),
             nchar(token) > 2) %>%
      filter(token %in% tolower(all_words)) %>%
      select(word = token)

    usethis::use_data(valid_words, overwrite = T)
  }

  # data("valid_words")
  paste0(sample(valid_words$word, 3), collapse = '-')

}




