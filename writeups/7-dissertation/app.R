## -----------------------------------------------------------------------
#| message: false
#| warning: false
#| echo: false
library(tidyverse)
library(shiny)

set.seed(3141)

# Data from Shiny app
library(RSQLite)
conn <- dbConnect(SQLite(), "../../shiny-apps/experiment-heat3d/data/stat218-summer2025.db")
dbListTables(conn)
blocks <- dbReadTable(conn, "blocks")
exp_results <- dbReadTable(conn, "exp_results")
users <- dbReadTable(conn, "users")
dbDisconnect(conn)

# Solutions
solutions <- readRDS("../../data/solutions.rda")

library(tidyverse)
# Pre-processing of results
results <- exp_results %>%

  # Remove all practice trials
  filter(set != "practice") %>%

  # Arrange by user id and trial time
  group_by(user_id) %>%
  arrange(start_time) %>%

  # Identify sequence of trials
  mutate(user_seq = ifelse(user_trial_order > lag(user_trial_order), 0, 1),
         user_seq = ifelse(start_time == min(start_time), 0, user_seq)) %>%
  mutate(user_seq = cumsum(user_seq)) %>%

  # Join with blocks
  left_join(blocks, by = "user_id", relationship = 'many-to-many') %>%
  group_by(user_id, user_seq) %>%

  # Remove blocks that were assigned after the trials started
  filter(system_time < min(start_time)) %>%

  # Get time difference with block and filter for smallest difference
  mutate(time_diff_block = min(start_time) - system_time) %>%
  filter(time_diff_block == min(time_diff_block)) %>%

  # Filter so that only the first completed trial is included
  filter(user_seq == min(user_seq))

# Get user sequences with full completions
full_completions <- results %>%
  group_by(user_id, user_seq, block) %>%
  count() %>%
  filter(n %in% c(16,24))

# Inner join to filter
results <- inner_join(results, full_completions) %>%
  select(-c(time_diff_block, n)) %>%
  ungroup()

# Join with results and filter so that only first completed block is there
results <- left_join(results, solutions) %>%
  ungroup() %>%
  group_by(user_id) %>%
  filter(system_time == min(system_time))

results$pair_id <- factor(results$pair_id)


## -----------------------------------------------------------------------
users_clean <- results %>%
  inner_join(users, by = 'user_id', relationship = 'many-to-many') %>%
  select(user_id, user_age:user_unique) %>%
  distinct() %>%
  dplyr::filter(!str_detect(tolower(user_unique), 'test,'))


## -----------------------------------------------------------------------
users_in_person <- users_clean %>%
  inner_join(results) %>%
  group_by(user_id, media) %>%
  summarise(n = n()) %>%
  filter(media == '3dp' & n > 0) %>%
  select(user_id)





## -----------------------------------------------------------------------
res_q2 <- results %>%
  mutate(target_ratio = 100*true_ratio,
         target_size = ifelse(z > 50, 50, z*true_ratio),
         target_diff = z-target_size) %>%
  # filter(pair_id != 5) %>%
  group_by(user_id, block) %>%
  mutate(prop_correct = mean(user_larger==true_larger))


ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      selectInput('user_id', choices = sort(unique(res_q2$user_id)),
                  label = 'Participant')
    ),
    mainPanel(
      plotOutput('response')
    )
  )
)

server <- function(input, output, session) {

  output$density <- renderPlot({
    res_q2 %>%
      pivot_longer(cols = c(target_ratio, target_diff, target_size),
                   names_to = 'x', values_to = 'target') %>%
      filter(user_id == input$user_id) %>%
      ggplot(mapping = aes(x = target, y = user_slider)) +
      geom_point() +
      geom_smooth(method = 'lm') +
      facet_wrap(~x, scales = 'free_y') +
      theme(aspect.ratio = 1) +
      scale_x_continuous(limits = c(0,100))
  })

  output$response <- renderPlot({
    res_q2 %>%
      filter(user_id == input$user_id) %>%
      pivot_longer(cols = c(user_slider, target_ratio, target_diff, target_size),
                   names_to = 'point') %>%
      ggplot(mapping = aes(x = user_trial_order,
                           y = value, linetype = point,
                           color = point,
                           alpha = point)) +
      geom_col(aes(y = 100, fill = media), width = 1, color = NULL, alpha = 1/4) +
      geom_point() +
      geom_line() +
      scale_y_continuous(limits = c(0,100)) +
      scale_color_manual(values = c(
        'user_slider'='black',
        'target_ratio'='black',
        'target_diff'='#1a80bb',
        'target_size'='#a00000'
      )) +
      scale_linetype_manual(values = c(
        'user_slider'='solid',
        'target_ratio'='longdash',
        'target_diff'='dotted',
        'target_size'='dotdash'
      )) +
      scale_alpha_manual(values = c(
        'user_slider'=1,
        'target_ratio'=0.5,
        'target_diff'=0.5,
        'target_size'=0.5
      ))
  })
}

shinyApp(ui, server)




