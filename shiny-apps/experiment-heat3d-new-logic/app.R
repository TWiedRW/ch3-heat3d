# Load packages and functions
library(shiny)
library(shinythemes)
library(shinyjs)
library(glue)
library(RSQLite)
library(tidyverse)

# Load data
load("../../data/plan.rda")
load("../../data/valid_words.rda")
load("../../data/stimuli_labels.rda")
load("../../data/data1.rda")
load("../../data/data2.rda")
load("../../data/practice_data.rda")

source("../../R/shiny_fn-generate_completion_code.R")
source("../../R/shiny_fn-randomize_order.R")
source("../../R/shiny_fn-create_db.R")
source("../../R/shiny_fn-pick_block.R")
source("../../R/shiny_fn-plot_helper.R")
source("../../R/shiny_fn-plot_2dd.R")
source("../../R/shiny_fn-plot_3dd.R")
source("../../R/shiny_fn-write_to_db.R")
source("../../R/shiny_fn-practice_order.R")
source("../../R/shiny_fn-show_instruction_modal.R")



# Initial Values
app_start_time <- Sys.time()
database <- "data/development.db"

# Create new database if one does not exist for {database}
# Note: this only populates with blocking information since
#   it is required when selecting blocks.
if (!(database %in% list.files(recursive = TRUE))) {
  message(glue("New database created: {database}"))
  create_db(database, plan)
}

# Labels
data_labels <- bind_rows(practice_data, data1, data2) %>%
  filter(!is.na(pair_id)) %>%
  left_join(stimuli_labels, by = c("pair_id", "within_pair")) %>%
  select(pair_id, within_pair, label) %>%
  distinct() %>%
  pivot_wider(names_from = within_pair, values_from = label)



# ---- Informed Consent ----
ui_consent <- fluidPage(
  div(
    style = "text-align: center;",
    h1("Heat3d: A study on 3D Heatmaps")
  ),
  sidebarLayout(
    sidebarPanel(
      div(style = "text-align: center;", h3("Informed Consent")),
      selectInput("is_218_student",
                  label = "Are you currently enrolled in Stat 218?",
                  choices = c("Please pick one of the following" = "",
                              "Yes, I am a Stat 218 student" = "TRUE",
                              "No, I am not a Stat 218 student" = "FALSE"),
                  selected = "", selectize = TRUE),
      p("Please read the informed consent on the right side of the screen."),
      p("You may download a PDF copy of the informed consent 
        by clicking the following link."),
      tags$a(
        href = "informed_consent.pdf",
        target = "_blank",
        "Download Informed Consent (PDF)"
      ),
      p(""),
      selectizeInput(
        "data_consent",
        label = "Do you consent to the use of your data in this study?",
        choices = c(
          "Please pick one of the following" = "",
          "Yes, I consent to the use of my data in this study" = "TRUE",
          "No, I do not consent to the use of my data in this study" = "FALSE"
        )
      ),
      tags$hr(),
      div(style = "text-align: center;", h3("Experiment Materials")),
      selectInput(
        "is_online",
        label = "Do you have access to the physical 3D-printed charts?",
        choices = c(
          "Please pick one of the following" = "",
          "Yes, I do have access to the 3D-printed charts" = "TRUE",
          "No, I do not have access to the 3D-printed charts" = "FALSE"
        ),
        selected = "",
        selectize = TRUE
      ),
      helpText("If your Stat 218 course is held in-person, you will need to have access to the 3D-printed charts."),
      conditionalPanel(
        'input.is_218_student != "" && input.is_online != "" && input.data_consent != ""',
        p("Click on the button below to advance to the next page."),
        div(style = "text-align: center; width: 100%;",
          actionButton("submit_consent", "Continue")
        )
      )

    ),
    mainPanel(
      p("Informed consent placeholder")
    )
  )
)


# ---- Demographics ----
options_ages <- c("", "Under 19", "19-25", "26-30",
                  "31-35", "36-40", "41-45", "46-50",
                  "51-55", "56-60", "Over 60",
                  "Prefer not to answer")
options_gender <- c("", "Female", "Male",
                    "Variant/Nonconforming",
                    "Prefer not to answer")

options_education <- c("", "High School or Less",
                       "Some Undergraduate Courses",
                       "Undergraduate Degree",
                       "Some Graduate Courses",
                       "Graduate Degree",
                       "Prefer not to answer")
options_reason <- c("", "Participation credit",
                    "Extra credit",
                    "Other",
                    "Not applicable")

ui_demographics <- fluidPage(
  column(
    width = 8, offset = 2,
    wellPanel(
      div(style = "text-align: center;", h2("Demographics")),
      p("In this section, please fill out the following demographic questions.
        All questions must be answered before continuing the study.
        After completing the questions, a button will appear to move to the next page."),

      selectizeInput("user_age", "What category includes your age?",
                     choices = options_ages, width = '100%'),
      selectizeInput("user_gender", "How would you describe your gender identity?",
                     choices = options_gender, width = '100%'),
      selectizeInput("user_education",
                     "What is your highest education level?",
                     choices = options_education, width = '100%'),
      selectizeInput("user_reason",
                     "How is your participation graded?",
                     width = "100%",
                     choices = options_reason),

      p("The next question helps us to uniquely identify your responses in our study. 
         Your answer will not be used in attempt to identify you."),
      textInput("user_unique", "What is your favorite movie and/or actor?"),

      conditionalPanel(
        '((input.user_age!="") && 
        (input.user_gender!="") && 
        (input.user_education!="") && 
        (input.user_reason!="") && 
        (input.user_unique!=""))',
        p("Click on the button below to advance to the next page."),
        actionButton("submit_demographics", "Continue")
      )

    )
  )
)










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
  tabPanel("Informed Consent", ui_consent),
  tabPanel("Demographics", ui_demographics)
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
