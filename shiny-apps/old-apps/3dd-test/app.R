# ---- Packages and plotting function ----
library(shiny)
library(rgl)

render_3dd <- function(base_file, bars_file, letters_file, ...){
  try(close3d())
  open3d()
  par3d(windowRect = c(20, 30, 800, 800))
  readSTL(base_file,
          color = '#1D2124', ...)
  readSTL(bars_file,
          color = '#74CCFF', ...)
  readSTL(letters_file,
          color = '#FFFFFF', ...)
}


# ---- UI ----
ui <- fluidPage(

    # Application title
    titlePanel("3dd RGL Test"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
          numericInput('light1', 'Light 1', value = 0),
          numericInput('light2', 'Light 1', value = 0),
          numericInput('light3', 'Light 1', value = 0),
          actionButton('clearlight', 'Clear lights')
        ),

        # Show a plot of the generated distribution
        mainPanel(
           rglwidgetOutput('digital3d', width = '400px')
        )
    )
)

# ---- Server ----
server <- function(input, output, session) {
  output$digital3d <- renderRglwidget({
    render_3dd(
      '../../print-files/rgl-data1-base.stl',
      '../../print-files/rgl-data1-bars.stl',
      '../../print-files/rgl-data1-letters.stl',
      specular = 'black', shininess = 100
    )
    highlevel()
    rglwidget()
  })

  observeEvent(input$clearlight, {
    clear3d(type = 'lights')
    shinyGetPar3d("userMatrix", session)
  })

}




# ---- Run app ----
shinyApp(ui = ui, server = server)


