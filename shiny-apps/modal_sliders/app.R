#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#


show_solution <- function(slider1, slider2) {
    showModal(modalDialog(
        title = "Solution",
        easyClose = TRUE,
        footer = NULL,
        size = "l",
        fluidRow(
            column(
                width = 6,
                sliderInput("modal_slider1", "Slider 1", min = 0, max = 100, value = slider1),
                sliderInput("modal_slider2", "Slider 2 (disabled)", min = 0, max = 100, value = slider2)
            ),
            column(
                width = 6,
                uiOutput("plot")
            )
        )
    ))
}

library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(

  # Application title
  titlePanel("Old Faithful Geyser Data"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
        sliderInput("slider1", "Slider 1", min = 0, max = 100, value = 50),
      actionButton("show", "Show solution")
    ),

    # Show a plot of the generated distribution
    mainPanel(
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    observeEvent(input$show, {
        show_solution(input$slider1, 55)
    })

    output$line_plot <- renderPlot({
        plot(input$slider1)
    })

    output$plot <- renderUI({
        plotOutput("line_plot")
    })

}

# Run the application
shinyApp(ui = ui, server = server)
