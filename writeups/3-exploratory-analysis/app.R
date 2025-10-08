# ---- Load data ----
library(shiny)
library(RSQLite)
library(tidyverse)
library(shiny)
conn <- dbConnect(SQLite(), '../../shiny-apps/experiment-heat3d/data/stat218-summer2025.db')
dbListTables(conn)
blocks <- dbReadTable(conn, 'blocks')
results <- dbReadTable(conn, 'exp_results')
users <- dbReadTable(conn, 'users')
dbDisconnect(conn)

abnormal_selection <- blocks %>%
  group_by(user_id) %>%
  count() %>%
  filter(n > 1)

test_users <- users %>%
  filter(str_detect(tolower(user_unique), 'test'))

weird <- results %>%
  filter(user_id %in% abnormal_selection$user_id,
         !(user_id %in% test_users$user_id)) %>%
  mutate(start_time = as.POSIXct(start_time),
         end_time = as.POSIXct(end_time))

match_block_to_trial <- blocks %>%
  inner_join(results, by = 'user_id', relationship = 'many-to-many') %>%
  mutate(trial_time = end_time - start_time,
         time_block_diff = start_time - system_time) %>%
  filter(time_block_diff > 0) %>%
  select(block, user_id, system_time, user_trial_order, start_time, end_time, time_block_diff) %>%
  group_by(user_id, user_trial_order) %>%
  filter(time_block_diff == min(time_block_diff),
         user_id %in% weird$user_id)


# ---- UI ----
ui <- fluidPage(
    sidebarLayout(
      sidebarPanel(
        selectInput('user', 'User', choices = sort(unique(match_block_to_trial$user_id)))
      ),
      mainPanel(
        plotOutput('user_plot')
      )
    )
)

# ---- Server ----
server <- function(input, output, session) {
    # Add server logic here
    output$user_plot <- renderPlot({
      match_block_to_trial %>%
        filter(user_id == input$user) %>%
        ggplot(mapping = aes(xmin = start_time, xmax = end_time,
                             y = 1, color = factor(block))) +
        geom_errorbar(width = 1/2) +
        scale_x_datetime(date_labels = '%m/%d %H:%M:%S')
    })
}

shinyApp(ui = ui, server = server)
