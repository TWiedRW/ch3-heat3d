
library(shiny)
library(shinythemes)

# Define UI for application that draws a histogram
ui.consent <- {
  fluidPage(theme = shinytheme('cerulean'),
  fluidRow(
    column(
      width = 8, offset = 2,
      wellPanel(
        selectInput('is-218-student',
                    label = 'Are you currently enrolled in Stat 218?',
                    choices = c("Please pick one of the following" = "",
                                "Yes, I am a Stat 218 student" = "TRUE",
                                "No, I am not a Stat 218 student" = "FALSE")),
        'Informed Consent will go here',
        radioButtons('informed-consent',
                     'Select "Yes" if you agree to participate in the study, or "No" if you do not agree to participate in the study.',
                     choices = c('Yes, I agree', 'No, I do not agree')),
        radioButtons('data-consent',
                     'Select "Yes" if you agree to let us collect your data',
                     choices = c('Yes, I agree', 'No, I do not agree'))
      )
    )
  )
  )
}
ui <- navbarPage(
  '3D Graphics Study',
  tabPanel('Informed Consent', ui.consent),
  tabPanel('Demographics'),
  tabPanel('Practice'),
  tabPanel('Experiment'),
  tabPanel('Wrap-up')
)


# Define server logic required to draw a histogram
server <- function(input, output) {

}

# Run the application
shinyApp(ui = ui, server = server)
