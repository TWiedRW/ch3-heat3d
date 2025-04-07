#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
source('../../R/shiny_fn-show_instruction_modal.R')

# Define UI for application that draws a histogram
ui <- fluidPage(
  actionButton('showModal', 'Show instruction modal')
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  observeEvent(input$showModal, {
    show_instruction_modal()
  })

  observeEvent(input$submit_close_instructions, {
    removeModal()
  })
}

# Run the application
shinyApp(ui = ui, server = server)
