set.seed(2026)
library(shiny)
data('data1')
data('data2')
data('data3')
data('data4')
data('stimuli')
good_letters <- sample(c(1,2,4,5,6,7,8,13,14,18))
L <- LETTERS[good_letters]
l <- letters[good_letters]

stimuli_labels <- tibble(good_letters,
       L, l) %>%
  mutate(pair_id = row_number()) %>%
  pivot_longer(L:l, names_to = 'case', values_to = 'label') %>%
  group_by(good_letters) %>%
  mutate(within_pair = sample(c('p1', 'p2')))





# Define UI for application that draws a histogram
ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = 'dataset',
        label = 'Dataset',
        choices = c('data1', 'data2', 'data3', 'data4')
      ),
      selectInput(
        inputId = 'style',
        label = 'Graphing Style',
        choices = c('Grid', 'Tile')
      ),
      selectInput(
        inputId = 'pair_id',
        label = 'Pair Identifier',
        choices = 1:9
      ),
      selectInput(
        inputId = 'palette',
        label = 'Color Palette',
        choices = c(
          'Blues',
          'Viridis',
          'YlOrBr',
          'Spectral'
        )
      )
    ),
    mainPanel(
      plotOutput('graph'),
      tableOutput('tibble')
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

  app_data <- reactiveValues(
    data = NULL
  )

  observeEvent(input$dataset, {
    use_data <- function(input_data){
      switch(input_data,
             data1 = data1,
             data2 = data2,
             data3 = data3,
             data4 = data4)
    }
    app_data$data <- use_data(input$dataset)
  })

  output$graph <- renderPlot({
    graph_data <- app_data$data %>%
      group_by(pair_id) %>%
      mutate(within_pair = ifelse(is.na(pair_id), NA,
                                  sample(c('p1', 'p2')))) %>%
      left_join(stimuli_labels, by = c('within_pair', 'pair_id')) %>%
      mutate(z = ifelse(pair_id == input$pair_id, z, NA))

    theme_set(theme_bw() + theme(aspect.ratio = 1))
    gtile <- graph_data %>%
      filter(pair_id == input$pair_id) %>%
      mutate(x = 1:2, y = 1) %>%
      ggplot(mapping = aes(x = 1:2, y = 1, fill = z)) +
      geom_tile(color = 'black') +
      geom_text(aes(label = label), size = 12) +
      theme(aspect.ratio = 1/2, axis.text = element_blank(),
            axis.ticks = element_blank(),
            axis.title = element_blank(),
            panel.grid = element_blank(),
            legend.position = 'bottom')

    ggrid <- graph_data %>%
      mutate(label = ifelse(pair_id == input$pair_id,
                            label, NA)) %>%
      ggplot(mapping = aes(x = x, y = y, fill = z)) +
      geom_tile(na.rm = T, color = 'black') +
      geom_text(aes(label = label), na.rm = T) +
      theme(legend.position = 'bottom',
            axis.text = element_blank(),
            axis.ticks = element_blank(),
            axis.title = element_blank(),
            panel.grid = element_blank())

    p <- switch(input$style,
           'Grid' = ggrid,
           'Tile' = gtile)
    switch(input$palette,
           'Blues' = p + scale_fill_distiller(palette = 'Blues', limits = c(0,100), direction = 1),
           'Spectral' = p + scale_fill_distiller(palette = 'Spectral', limits = c(0,100), direction = 1),
           'YlOrBr' = p + scale_fill_distiller(palette = 'YlOrBr', limits = c(0,100), direction = 1),
           'Viridis' = p + scale_fill_viridis_c(limits = c(0,100)))

  })

  output$tibble <- renderTable({
    print(app_data$data)
  })



}

# Run the application
shinyApp(ui = ui, server = server)
