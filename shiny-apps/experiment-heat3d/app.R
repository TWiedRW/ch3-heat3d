# Load packages and functions
library(shiny)
library(shinythemes)
library(shinyjs)
library(glue)
library(RSQLite)

load('../../data/valid_words.rda')
load('../../data/stimuli_labels.rda')

source('../../R/shiny_fn-generate_completion_code.R')
source('../../R/shiny_fn-randomize_order.R')
source('../../R/shiny_fn-create_db.R')
source('../../R/shiny_fn-pick_block.R')



# Initial Values
appStartTime <- Sys.time()
database <- 'data/heat3d.db'

# Create new database if one does not exist for {database}
# Note: this only populates with blocking information since
#   it is required when selecting blocks.
if(!(database %in% list.files(recursive = T))){
  message(glue('New database created: {database}'))
  create_db(database, plan)
}


# ---- Informed Consent ----
ui_consent <- fluidPage(
  fluidRow(
    column(
      width = 8, offset = 2,
      wellPanel(
        p('Option to select new or returning user, plus buttons and text form'),
        selectInput('is_218_student',
                    label = 'Are you currently enrolled in Stat 218?',
                    choices = c("Please pick one of the following" = "",
                                "Yes, I am a Stat 218 student" = "TRUE",
                                "No, I am not a Stat 218 student" = "FALSE")),
        'Informed Consent will go here',
        radioButtons('informed_consent',
                     'Select "Yes" if you agree to participate in the study, or "No" if you do not agree to participate in the study.',
                     choices = c('Yes, I agree' = "TRUE", 'No, I do not agree' = "FALSE"),
                     selected = ''),
        radioButtons('data_consent',
                     'Select "Yes" if you agree to let us collect your data',
                     choices = c('Yes, I agree' = "TRUE", 'No, I do not agree' = "FALSE"),
                     selected = ''),
        actionButton('submit_consent', 'Submit')
      )
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
options_reason <- c("", 'Participation credit',
                    'Extra credit',
                    'Other',
                    'Not applicable')

ui_demographics <- fluidPage(
  column(
    width = 8, offset = 2,
    wellPanel(
      h2('Demographics'),
      p('In this section, please fill out the following demographic questions.
        All questions must be answered before continuing the study.
        After completing the questions, a button will appear to move to the next page.'),
      # column(width = 6, selectizeInput("user_age", "What category includes your age?",
      #                                  choices = options_ages, width = '100%'),
      #        selectizeInput("user_gender", "How would you describe your gender identity?",
      #                       choices = options_gender, width = '100%'))
      # ,
      # column(width = 6, selectizeInput("user_education",
      #                                  "What is your highest education level?",
      #                                  choices = options_education, width = '100%'),
      #        selectizeInput('user_reason',
      #                       'How is your participation graded?',
      #                       width = '100%',
      #                       choices = options_reason)),

      selectizeInput("user_age", "What category includes your age?",
                     choices = options_ages, width = '100%'),
      selectizeInput("user_gender", "How would you describe your gender identity?",
                     choices = options_gender, width = '100%'),
      selectizeInput("user_education",
                     "What is your highest education level?",
                     choices = options_education, width = '100%'),
      selectizeInput('user_reason',
                     'How is your participation graded?',
                     width = '100%',
                     choices = options_reason),

      p('The next question helps us to uniquely identify your responses in our study. Your answer will not be used in attempt to identify you.'),
      textInput('user_unique', 'What is your favorite movie and/or actor?'),

      conditionalPanel(
        '((input.user_age!="") && (input.user_gender!="") && (input.user_education!="") && (input.user_reason!="") && (input.user_unique!=""))',
        p('Click on the button below to advance to the next page.'),
        actionButton('submit_demographics', 'Continue')
      )

    )
  )
)

# ---- Instructions ----

ui_instructions <- fluidPage(
  column(width = 8, offset = 2,
    h2('Instructions'),
    p('In this experiment, you will be using various mediums of data visualization to compare two values.
      The experiment interface will provide you with a digital rendering of a data visualizaiton, or prompt you to use one of the 3D-printed graphs.'),

  )
)

# ---- Practice ----

ui_practice <- fluidPage(
  actionButton('submit_start_exp', 'Start Experiment')
)


# ---- Experiment ----

ui_experiment <- fluidPage(
  useShinyjs(),
  uiOutput('experiment_display')
)

# ---- Ending page ----



# ---- UI Navigation ----
ui <- navbarPage(
  '3D Graphics Study',
  tabPanel('Informed Consent', ui_consent),
  tabPanel('Demographics', ui_demographics),
  tabPanel('Instructions', ui_instructions),
  tabPanel('Practice', ui_practice),
  tabPanel('Experiment', ui_experiment),
  tabPanel('Wrap-up'),
  tabPanel('Developer', uiOutput('dev_page'))
)


# ---- Server ----
server <- function(input, output, server) {

  # ---- Start-up logic ----
  appValues <- reactiveValues(
    appStartTime = NULL,
    session = NULL,
    informed_consent = NULL,
    data_consent = NULL,
    user_id = NULL,
    completion_code = NULL
  )

  # On startup or here?
  session <- reactive({as.character(floor(runif(1)*1e20))})


  # ---- Consent logic ----
  observeEvent(input$submit_consent, {
    appValues$appStartTime <- appStartTime
    appValues$session <- session()
    appValues$informed_consent <- input$informed_consent
    appValues$data_consent <- input$data_consent
    appValues$completion_code <- generate_completion_code(valid_words)

    message(glue('The following app values were created:'))
    message(glue('appStartTime: {appValues$appStartTime}'))
    message(glue('session: {appValues$session}'))
    message(glue('informed_consent: {appValues$informed_consent}'))
    message(glue('data_consent: {appValues$data_consent}'))
    message(glue('completion_code: {appValues$completion_code}'))

    # Close app if user does not want to participate in experiment
    if(appValues$informed_consent == 'FALSE'){
      showModal(modalDialog(
        title = "System Message",
        paste0('Informed consent was not provided. Please write down the following completion code and submit it to Canvas: ', appValues$completion_code, '. You may now exit the web browser.'),
        easyClose = FALSE,
        footer = NULL
      ))
    }

  })

  # ---- Demographics logic ----


  observeEvent(input$submit_demographics, {
    #ATTENTION: Save demographic information here


    #Maybe use app start time too in user_id?
    appValues$user_id <- rlang::hash(glue('{input$user_age}-{input$user_gender}-{input$user_education}-{input$user_reason}-{input$user_unique}'))
    message(glue('A new user was created at {appValues$appStartTime}: {appValues$user_id}'))
  })
  # ---- Instructions logic ----


  # ---- Practice logic ----


  # ---- Experiment logic ----
  expValues <- reactiveValues(
    user_id = NULL,
    trialStartTime = NULL,
    trialEndTime = NULL,
    trialNumber = NULL,
    trialSet = NULL,
    block = NULL,
    user_results = NULL,
    user_trial_num = NULL,
    user_trial_max = NULL,
    user_set_num = NULL,
    user_set_max = NULL,
    user_slice = NULL,
    user_guess_smaller = NULL,
    user_guess_slider = NULL,
    data_consent = NULL
  )
  observeEvent(input$submit_start_exp, {
    #User information
    expValues$user_id <- appValues$user_id
    expValues$data_consent <- appValues$data_consent
    expValues$block <- pick_block(database)
    message(glue('Block {expValues$block} was chosen for user {expValues$user_id}'))

    #Trial information
    expValues$user_results <- randomize_order(expValues$block, plan)

    expValues$user_trial_num <- min(expValues$user_results$user_trial_order)
    expValues$user_trial_max <- max(expValues$user_results$user_trial_order)

    #First Trial
    expValues$user_slice <- dplyr::filter(expValues$user_results, user_trial_order == expValues$user_trial_num)

    #Set information
    expValues$user_set_num <- expValues$user_slice$user_set_order
    expValues$user_set_max <- max(expValues$user_results$user_set_order)
  })

  output$experiment_plot <- renderPlot({
    ggplot(mapping = aes(x = 1, y = 1, label = 'Plot Placeholder')) +
      geom_text() +
      theme(aspect.ratio = 1)
  })

  output$experiment_display <- renderUI({

    fluidPage(
      sidebarLayout(
        sidebarPanel(
          h2(glue('Trial {expValues$user_trial_num} of {expValues$user_trial_max}')),
          h3(glue('Group {expValues$user_set_num} of {expValues$user_set_max}')),
          radioButtons('user_guess_smaller',
                       'Which of the following values is larger?',
                       choices = c('Value 1', 'Value 2'),
                       selected = ''),
          sliderInput('user_guess_slider',
                      'If the larger value you selected above represents 100 units, how many units does the smaller value represent?',
                      min = 0, max = 100, value = 50),
          actionButton('submit_user_trial',
                       'Submit')

        ),
        mainPanel(
          plotOutput('experiment_plot', width = '400px'),
          tableOutput('user_slice')
        )
      )
    )
  })

  observeEvent(input$submit_user_trial, {
    #Save data into database here
    # ...


    #Update trial number and trial slice
    if(expValues$user_trial_num < expValues$user_trial_max){
      expValues$user_trial_num <- expValues$user_trial_num + 1
      expValues$user_slice <- dplyr::filter(expValues$user_results, user_trial_order == expValues$user_trial_num)
      expValues$user_set_num <- expValues$user_slice$user_set_order
    } else if(expValues$user_trial_num  == expValues$user_trial_max){
      # Move to ending page
      # ...
      message(glue('User {appValues$user_id} has completed the experiment!'))
    } else {
      message('Trial number exeeds maximun number of trials. What happened???')
    }



  })


  # ---- Post-experiment logic ----



  # ---- Developer logic ----

  output$dev_page <- renderUI({
    tableOutput('user_results')
  })

  output$user_results <- renderTable({
    expValues$user_results
  })

  output$user_slice <- renderTable({
    expValues$user_slice
  })

  # ---- End server logic ----



}

# Run the application
shinyApp(ui = ui, server = server)
