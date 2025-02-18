# Database connection
database <- 'test.db'

# Load packages and functions
source('../../../R/shiny_fn-pick_block.R')
source('../../../R/shiny_fn-randomize_order.R')
library(shiny)
library(shinyjs)


# UI
ui_experiment <- fluidPage(
  useShinyjs(),
  sidebarLayout(
    sidebarPanel(
      h2('Graph X of N'),
      radioButtons('experiment_larger',
                   'Which of the following values is larger?',
                   choices = c('Value 1'=1, 'Value 2'=2, 'Both values are the same'=3)),
      sliderInput('experiment_slider', 'If the value you selected above is 100 units, how many units does the other (smaller) value represent.',
                  min = 0, max = 100, value = 50,
                  ticks = FALSE, pre = 'pre', post = 'post.')
    ),
    mainPanel(
      uiOutput('experiment_plot')
    )
  )
)


# Server
server <- function(input, output){
  exp_data <- reactiveValues(
    block = NULL,
    trial = NULL,

  )

  # Update slider to max value if participant indicates that they are the same
  observeEvent(input$experiment_larger, {
    if(input$experiment_larger == 3){
      updateSliderInput(inputId = 'experiment_slider', value = 100)
      shinyjs::disable(id = 'experiment_slider')
    } else {
      shinyjs::enable(id = 'experiment_slider')
    }
  })


  output$experiment_plot <- renderUI({

  })
}

shinyApp(ui=ui_experiment, server = server)
