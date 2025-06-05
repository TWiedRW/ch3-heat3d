# Load packages and functions
library(shiny)
library(shinythemes)
library(shinyjs)
library(glue)
library(RSQLite)
library(tidyverse)

# Load data
load('../../data/plan.rda')
load('../../data/valid_words.rda')
load('../../data/stimuli_labels.rda')
load('../../data/data1.rda')
load('../../data/data2.rda')
load('../../data/practice_data.rda')

source('../../R/shiny_fn-generate_completion_code.R')
source('../../R/shiny_fn-randomize_order.R')
source('../../R/shiny_fn-create_db.R')
source('../../R/shiny_fn-pick_block.R')
source('../../R/shiny_fn-plot_helper.R')
source('../../R/shiny_fn-plot_2dd.R')
source('../../R/shiny_fn-plot_3dd.R')
source('../../R/shiny_fn-write_to_db.R')
source('../../R/shiny_fn-practice_order.R')
source('../../R/shiny_fn-show_instruction_modal.R')



# Initial Values
appStartTime <- Sys.time()
database <- 'data/graphics-group(04-07-2025).db'
userBlock <- 2


# Labels
expLabels <- bind_rows(practice_data, data1, data2) %>%
  filter(!is.na(pair_id)) %>%
  left_join(stimuli_labels, by = c("pair_id", "within_pair")) %>%
  select(pair_id, within_pair, label) %>%
  distinct() %>%
  pivot_wider(names_from = within_pair, values_from = label)


# ---- UI Logic ----
ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  sidebarLayout(
    sidebarPanel(
      # conditionalPanel("input.practice_indicator==true", uiOutput("trialHeader")),
      uiOutput("trialHeader"),
      conditionalPanel("input.isPractice", actionButton("showInstructions", "Show Instructions")),
      p("Use the values indicated on the plot below for this trial."),
      conditionalPanel("output.state == true",
        p("You are currently in the practice trials. The actual experiment will start after you complete these trials.")
      ),
      plotOutput("plotHelper", height = "200px"),
      checkboxInput("isPractice", "practice", value = T),
      radioButtons("userLarger", "Which value represents a larger quantity?",
                   choices = 1:3),
      sliderInput("userSlider", "If the larger value you selected above represents 100 units, how many units is the smaller value?",
                  min = 0, max = 100, value = runif(1, 0, 100)),
      div(style = "text-align: center;", actionButton("submit", "Submit"))
    ),
    mainPanel(
      textOutput("sliderClicks"),
      tableOutput("currSlice"),
      tableOutput("currTrial")
    )
  )
)

appUI <- navbarPage(
  "Heat3d",
  id = "expNav",
  tabPanel("Start", fluidPage(actionButton("start", "Start"))),
  tabPanel("Experiment", ui)
)

# ---- Server Logic ----
server <- function(input, output) {
  appValues <- reactiveValues(

    #App state
    expState = "practice",

    #Counters
    sliderClicks = -1,
    currCounter = NULL,

    #All trials information
    expAllTrials = NULL,
    practiceTrials = NULL,

    #Max trials
    pracMax = 4,
    expMax = NULL,

    #Current trials based on app state
    currTrials = NULL,
    currMax = NULL
  )

  currSlice <- reactive({
    req(!is.null(appValues$currTrials))
    appValues$currTrials[appValues$currCounter,]
  })

  # Initial startup values
  observeEvent(input$start, {
    #Initialize trials
    appValues$expAllTrials <- randomize_order(userBlock, plan, TRUE)
    appValues$practiceTrials <- practice_order(plan = plan)

    #Initialize max values
    appValues$pracMax <- nrow(appValues$practiceTrials)
    appValues$expMax <- nrow(appValues$expAllTrials)

    #Set practice as current
    appValues$currTrials <- appValues$practiceTrials
    appValues$currMax <- appValues$pracMax
    appValues$currCounter <- 1

    message('User trials was set')
    updateNavbarPage(inputId = 'expNav', selected = 'Experiment')
  })

  # Submit button logic
  observeEvent(input$submit, {
    if((appValues$currCounter == appValues$currMax) & appValues$expState == 'practice'){
      # Change from practice state to experiment state
      appValues$expState <- 'experiment'
      appValues$currCounter <- 1
      updateSliderInput(inputId = 'userSlider', value = runif(1, 0, 100))
      showModal(modalDialog(p('You successfully completed the practice trials. The actual experiment is next.'),
                            title = 'Practice trials completed',
                            size = 'xl'))
    } else if((appValues$currCounter == appValues$currMax) & appValues$expState == 'experiment'){
      # Experiment is complete
    message('Experiment is complete')
      showModal(modalDialog(p('You successfully completed the experiment. Here is your completion code: ',
                              p('Completion code placeholder'),
                              p('Save this code as you will not have access once you exit the application.'),
                              title = 'Experiment complete!')))
    } else {
      # Update to next trial
      appValues$currCounter <- appValues$currCounter + 1
      appValues$sliderClicks <- -1
      updateSliderInput(inputId = 'userSlider', value = runif(1, 0, 100))
  }
  })

  observe({
    if(appValues$expState != 'practice'){
      appValues$currTrials <- appValues$expAllTrials
      appValues$currMax <- appValues$expMax
      updateCheckboxInput(inputId = 'isPractice', value = F)
    }
  })


  observe({
    req(is.reactive(currSlice))
    trial <- currSlice() %>%
      left_join(expLabels, by = c('pair_id'))


    expChoices <- c(trial$p1, trial$p2, 'Both values are the same')

    updateRadioButtons(inputId = 'userLarger',
                       choices = expChoices)

  })

  observeEvent(input$userSlider, {
    appValues$sliderClicks = appValues$sliderClicks + 1
  })

  output$state <- reactive({appValues$expState=='practice'})

  output$plotHelper <- renderPlot({
    req(is.reactive(currSlice))
    switch (currSlice()$set,
      'practice' = plot_helper(practice_data, as.numeric(currSlice()$pair_id), stimuli_labels),
      'set1' = plot_helper(data1, as.numeric(currSlice()$pair_id), stimuli_labels),
      'set2' = plot_helper(data2, as.numeric(currSlice()$pair_id), stimuli_labels)
    )
  })

  output$trialHeader <- renderUI({
    tagList(
      h2(glue::glue("Trial {appValues$currCounter} of {appValues$currMax}"), style = "text-align: center;"),
    )
  })

  output$sliderClicks <- renderText(appValues$sliderClicks)
  output$currTrial <- renderTable({
    appValues$currTrials
  })
  output$currSlice <- renderTable({
    req(is.reactive(currSlice))
    currSlice()
    })
}


# Run the application
shinyApp(ui = appUI, server = server)
