library(ggplot2)
ui_instructions <- fluidPage(
  h2('Instructions'),
  p('In this study, you will be making comparisons between two values on a 2-dimensional or 3-dimensional heatmap.'),
  h2('Step 1'),
  p('The first question'),
  radioButtons('null_smaller', 'Which of the two values is smaller?',
               choices = c('Value 1', 'Value 2', 'Both values are the same'),
               selected = ''),
  h2('Step 2'),
  p('Next, you will be asked to estimate '),
  sliderInput('null_estimate', 'Your answer here',
              min = 0, max = 100, value = 50)

)

server <- function(input, output){

}

shinyApp(ui = ui_instructions, server = server)
