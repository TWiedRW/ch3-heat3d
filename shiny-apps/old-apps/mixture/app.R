#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(tidyverse)
library(rayshader)
library(rgl)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Uniform Mixture Distribution"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            sliderInput("bins",
                        "Percent Uniform",
                        min = 0,
                        max = 1,
                        animate = T,
                        value = 0.5)
        ),

        # Show a plot of the generated distribution
        mainPanel(
           rglwidgetOutput("distPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  scale0to100 <- function(z){
    zstar = 100*(z-min(z))/(max(z)-min(z))
    return(zstar)
  }
    output$distPlot <- renderRglwidget({
        # generate bins based on input$bins from ui.R
        x <- y <- 1:10
        set.seed(3940894)
        dat <- expand_grid(x,y) %>%
          mutate(unif = runif(nrow(.), 0, 100),
                 dtn = scale0to100((6^2+(x-mean(x))^2-(y-mean(y))^2)),
                 mix = input$bins*unif + (1-input$bins)*dtn)
        mod <- loess(dtn ~ unif, data = dat)
        dat <- mutate(dat, smooth = scale0to100(predict(mod)),
                      mix = input$bins*unif + (1-input$bins)*dtn)
        # draw the histogram with the specified number of bins
        p <- ggplot(dat, aes(x = x, y = y, fill = mix)) +
          geom_tile() +
          scale_fill_gradient(low = 'darkblue', high = 'darkblue', limits = c(0,100)) +
          theme(aspect.ratio = 1)
        rayshader::plot_gg(p, raytrace = T)
        rglwidget()
    })
}

# Run the application
shinyApp(ui = ui, server = server)
