# ---- MAJOR TO-DO ----
#| Create 3dp stl files for set2
#| Create logic to save data to database
#| Informed concent, instructions, practice, end page
#| Save number of clicks on 3dd charts
#| Remove 3dp for online-only participants
#| Add gradient scale to 2dd
#|



# ---- MINOR TO-DO ----
#| Placement of helper plot
#| Match text font on 2dd to 3dd/3dp (hyperlegible)
#| Render graphs only when the grouping changes
#|    This should help with 3dd resetting every time, but
#|    I am skeptical since the entire experiment page is
#|    created with renderUI. One solution is to save the
#|    user matrix and use it every time, but this might
#|    create a small lag when the rgl loads in for each
#|    queston.
#| Change initial viewing angle for 3dd
#| Replace 3dp images with better ones using actual charts
#| Put black border around 2dd and 3dd outputs
#|    Not necessary, but I think it would look nice
#| Confidence question does not appear for last set of graphs
#|    Idea - create another variable measuring if the experiment
#|    is complete or not. Then, the logic is that if the group
#|    of charts changed or if experiment is completed
#| Remove number above slider
#|    I think that keeping the 0 and 100 at the ends would
#|    make sense given the phrasing of the question
#| Slider bugged? Sometimes fill does not line up with where
#|    the icon is, but seems to be better now that steps
#|    are 0.1 instead of 0.01
#| 218 vs. non-218 versions (completion codes, etc. )
#| Font sizes for value definitions
#|



# ---- Idea list ----
#| Use updated radio buttons instead of value definitions
#|    As of now, I can get it working for all trials except
#|    the first trial. I suspect it is because the update
#|    function runs before the initial experiment loads in
#| The app looks incredibly dull. I would like to have
#|    literally anything else to make it more exciting.
#|    For example, color in the tab bar or background colors
#|



# ---- Shiny App Initialization ----

# Load packages and functions
library(shiny)
library(shinythemes)
library(shinyjs)
library(glue)
library(RSQLite)
library(tidyverse)

load('../../data/valid_words.rda')
load('../../data/stimuli_labels.rda')
load('../../data/data1.rda')
load('../../data/data2.rda')
load('../../data/plan.rda')

source('../../R/shiny_fn-generate_completion_code.R')
source('../../R/shiny_fn-randomize_order.R')
source('../../R/shiny_fn-create_db.R')
source('../../R/shiny_fn-pick_block.R')
source('../../R/shiny_fn-plot_helper.R')
source('../../R/shiny_fn-plot_2dd.R')
source('../../R/shiny_fn-plot_3dd.R')



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
                                "No, I am not a Stat 218 student" = "FALSE"),
                    selected = '', selectize = T),
        conditionalPanel('input.is_218_student == True && input.is_218_student!=""', includeHTML('informed-consent/graphics-consent-218.html')),
        conditionalPanel('input.is_218_student == False && input.is_218_student!=""', includeHTML('informed-consent/graphics-consent-dept.html')),

        radioButtons('data_consent',
                     'Select "Yes" if you agree to the informed concent and you agree to let us collect your data',
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
   wellPanel(
    h2('Instructions'),
    p('In this experiment, you will be using various mediums of data visualization to compare two values.
      The experiment interface will provide you with a digital rendering of a data visualizaiton, or prompt you to use one of the 3D-printed graphs.'),
    p('More text will go here, plus pictures...'),
    actionButton('submit_start_exp', 'Start Experiment')
  )),
  fluidRow(
    sidebarLayout(
      sidebarPanel(
        p('test')
      ),
      mainPanel(
        p('test')
      )
    )
  )
)

# ---- Practice (currently inactive) ----

ui_practice <- fluidPage(
  actionButton('submit_start_exp', 'Start Experiment')
)


# ---- Experiment ----

ui_experiment <- fluidPage(
  useShinyjs(),
  uiOutput('experiment_display')
)

# ---- Ending page ----
ui_wrapup <- fluidPage(
  column(width = 8, offset = 2,
    h2('Experiment complete'),
    p('Thank you for completing the experiment.
      Your completion code is below.'),
    p('More text about saving code to Canvas'),
    textOutput('user_completion_code')
  )
)


# ---- UI Navigation ----
ui <- navbarPage(
  '3D Graphics Study',
  id = 'navpage',
  tabPanel('Informed Consent', ui_consent),
  tabPanel('Demographics', ui_demographics),
  tabPanel('Instructions', ui_instructions),
  # tabPanel('Practice', ui_practice), # Disabled for now
  tabPanel('Experiment', ui_experiment),
  tabPanel('Wrap-up', ui_wrapup),
  tabPanel('Developer', uiOutput('dev_page'))
)


# ---- Server ----
server <- function(input, output, server) {

  # ---- Start-up logic ----
  appValues <- reactiveValues(
    appStartTime = NULL,
    session = NULL,
    data_consent = NULL,
    user_pre_hash = NULL,
    user_id = NULL,
    completion_code = NULL
  )

  # On startup or here?
  session <- reactive({as.character(floor(runif(1)*1e20))})

  # Demographic values
  demographicValues <- reactiveValues(
    age = NULL,
    gender = NULL,
    education = NULL,
    reason = NULL,
    unique = NULL
  )

  # ---- Consent logic ----
  observeEvent(input$submit_consent, {
    appValues$appStartTime <- appStartTime
    appValues$session <- session()
    appValues$data_consent <- input$data_consent
    appValues$completion_code <- generate_completion_code(valid_words)

    message(glue('The following app values were generated:'))
    message(glue('\tappStartTime: {appValues$appStartTime}'))
    message(glue('\tsession: {appValues$session}'))
    message(glue('\tdata_consent: {appValues$data_consent}'))
    message(glue('\tcompletion_code: {appValues$completion_code}'))

    updateNavbarPage(inputId = 'navpage', selected = 'Demographics')

  })

  # ---- Demographics logic ----


  observeEvent(input$submit_demographics, {

    # Save demographic fields
    demographicValues$user_age <- input$user_age
    demographicValues$user_gender <- input$user_gender
    demographicValues$user_education <- input$user_education
    demographicValues$user_reason <- input$user_reason
    demographicValues$user_unique <- input$user_unique



    # Hash values
    appValues$user_pre_hash <- glue('{appValues$completion_code}-{demographicValues$user_age}-{demographicValues$user_gender}-{demographicValues$user_education}-{demographicValues$user_reason}-{demographicValues$user_unique}')
    appValues$user_id <- rlang::hash(appValues$user_pre_hash)

    # Print recorded values
    message(glue('The following demographic fields were populated:'))
    message(glue('\tuser_age: {demographicValues$user_age}'))
    message(glue('\tuser_gender: {demographicValues$user_gender}'))
    message(glue('\tuser_education: {demographicValues$user_education}'))
    message(glue('\tuser_reason: {demographicValues$user_reason}'))
    message(glue('\tuser_unique: {demographicValues$user_unique}'))
    message(glue('\tuser_pre_hash: {appValues$user_pre_hash}'))
    message(glue('\tuser_id: {appValues$user_id}'))

    # Maybe use app start time too in user_id?
    message(glue('A new user was created at {appValues$appStartTime}: {appValues$user_id}'))

    # Update page
    updateNavbarPage(inputId = 'navpage', selected = 'Instructions')

})
  # ---- Instructions logic ----
  observeEvent(input$submit_start_exp, {
    updateNavbarPage(inputId = 'navpage', selected = 'Experiment')
  })

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
    data_consent = NULL,
    user_last_trial = FALSE
  )




  observeEvent(input$submit_start_exp, {


    #User information
    expValues$user_id <- appValues$user_id
    expValues$data_consent <- appValues$data_consent
    expValues$block <- pick_block(database)
    message(glue('Block {expValues$block} was chosen for user {expValues$user_id}'))

    #Trial information
    expValues$user_results <- randomize_order(expValues$block, plan)

    #Label information
    expValues$user_results <- expValues$user_results %>%
      left_join(stimuli_labels, relationship = 'many-to-many',
                by = 'pair_id') %>%
      select(-c(label_stl)) %>%
      pivot_wider(values_from = label,
                  names_from = within_pair)


    expValues$user_trial_num <- min(expValues$user_results$user_trial_order)
    expValues$user_trial_max <- max(expValues$user_results$user_trial_order)

    #First Trial
    expValues$user_slice <- dplyr::filter(expValues$user_results, user_trial_order == expValues$user_trial_num)

    #Set information
    expValues$user_set_num <- expValues$user_slice$user_set_order
    expValues$user_set_max <- max(expValues$user_results$user_set_order)

    #Update values
    # updateRadioButtons(inputId = 'user_guess_smaller',
    #                    choices = c(expValues$user_slice$p1,
    #                                expValues$user_slice$p2,
    #                                'The two values are the same.'),
    #                    selected = '')

  })

  # Create helper plot
  output$plot_helper <- renderPlot({
    switch (expValues$user_slice$set,
            'set1' = plot_helper(data1, expValues$user_slice$pair_id),
            'set2' = plot_helper(data2, expValues$user_slice$pair_id)
    )
  })

  # Create plot for 2dd
  output$plot_2dd <- renderPlot({
    switch (expValues$user_slice$set,
            'set1' = plot_2dd(data1),
            'set2' = plot_2dd(data2)
    )
  })

  # Create plot for 3dd
  output$plot_3dd <- renderRglwidget({
    switch (expValues$user_slice$set,
            'set1' = render_3dd('../../print-files/rgl-data1-base.stl',
                                '../../print-files/rgl-data1-bars.stl',
                                '../../print-files/rgl-data1-letters.stl'),
            #MAJOR CHANGE: NEED TO CONVERT BACK TO data2 WHEN FILES ARE CREATED
            'set2' = render_3dd('../../print-files/rgl-data1-base.stl',
                                '../../print-files/rgl-data1-bars.stl',
                                '../../print-files/rgl-data1-letters.stl')
    )
    rglwidget()
  })

  # Create plot for 3dp
  output$plot_3dp <- renderImage({
    switch (expValues$user_slice$set,
      'set1' = list(src='www/set1-3dp.JPG', width = '400px'),
      'set2' = list(src='www/set2-3dp.JPG', width = '400px')
    )
  }, deleteFile = F)


  # Render UI for chart helper
  output$experiment_plot_helper <- renderUI({
    validate(need(input$user_helper, ''))
      plotOutput('plot_helper', width = '50%')
  })

  # Render UI for experiment chart
  output$experiment_plot <- renderUI({
    switch (expValues$user_slice$media,
            '2dd' = plotOutput('plot_2dd'),
            '3dd' = tagList(
              rglwidgetOutput('plot_3dd'),
              helpText('You may use your mouse to move the chart on the screen.'),
              helpText('Right click: move the plot.'),
              helpText('Scroll: zoom in and out.')
            ),
            '3dp' = tagList(
              h3('Use the 3D chart that looks like the image below.'),
              imageOutput('plot_3dp')
            )

    )
      # plotOutput('plot_helper', width = '70%')

  })


  # Experiment UI
  output$experiment_display <- renderUI({

    fluidPage(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
      ),
      sidebarLayout(
        sidebarPanel(
          h2(glue('Trial {expValues$user_trial_num} of {expValues$user_trial_max}')),
          h3(glue('Group {expValues$user_set_num} of {expValues$user_set_max}')),
          p(glue('Use the following definitions for Trial {expValues$user_trial_num}. If you need help identifying the values on the chart, there is an option at the bottom of this section to help.')),
          p(glue('Value 1: {expValues$user_slice$p1}')),
          p(glue('Value 2: {expValues$user_slice$p2}')),

          radioButtons('user_guess_smaller',
                       'Which of the following values is larger?',
                       choices = c('Value 1', 'Value 2', 'They are the same.'),
                       selected = ''),
          sliderInput('user_guess_slider',
                      'If the larger value you selected above represents 100 units, how many units does the smaller value represent?',
                      min = 0, max = 100, value = 50, ticks = F, step = 0.1),

          actionButton('submit_user_trial',
                       'Submit'),

          checkboxInput('user_helper', 'Select this checkbox if you need help identifying the two values on the chart.')

        ),
        mainPanel(
          uiOutput('experiment_plot', width = '100%'),
          tableOutput('user_slice'),
          uiOutput('experiment_plot_helper')
        )
      )
    )
  })

  observeEvent(input$submit_user_trial, {
    # Save data into database here
    # ...



    #Update trial number and trial slice
    if(expValues$user_trial_num < expValues$user_trial_max){
      expValues$user_trial_num <- expValues$user_trial_num + 1

      expValues$user_slice <- dplyr::filter(expValues$user_results, user_trial_order == expValues$user_trial_num)

      if(expValues$user_set_num != expValues$user_slice$user_set_order | expValues$user_last_trial == T){
        # Alt phrasing ideas: https://www.marquette.edu/student-affairs/assessment-likert-scales.php
        showModal(modalDialog(
          radioButtons('user_confidence',
                       glue('Rate the confidence of your answers for the previous group of questions (Group {expValues$user_set_num}).'),
                       choices = c('1 - Not confident',
                                   '2 - Slightly confident',
                                   '3 - Somewhat confident',
                                   '4 - Moderately confident',
                                   '5 - Extremely confident'),
                       selected = ''),
          actionButton('submit_confidence', 'Submit', disabled = T),
          title = 'Some title here I guess',
          footer = NULL

        ))
      }

      expValues$user_set_num <- expValues$user_slice$user_set_order
      # If next trial is last trial, create marker for confidence question
      if(expValues$user_trial_num == expValues$user_trial_max){
        expValues$user_last_trial <- TRUE
      }
    } else if(expValues$user_trial_num  == expValues$user_trial_max){

      # Move to ending page
      message(glue('The following user has completed the experiment!'))
      message(glue('\t{appValues$user_id}'))
      updateNavbarPage(inputId = 'navpage', selected = 'Wrap-up')
    } else {
      message('Trial number exeeds maximun number of trials. What happened???')
    }

    #Update values
    # updateRadioButtons(inputId = 'user_guess_smaller',
    #                    choices = c(expValues$user_slice$p1,
    #                                expValues$user_slice$p2,
    #                                'They are the same.'),
    #                    selected = '')

  })

  # Enable confidence submit button when choice is selected
  observeEvent(input$user_confidence, {
    updateActionButton('submit_confidence',
                       session = getDefaultReactiveDomain(),
                       disabled = F)
  })


  observeEvent(input$submit_confidence, {
    # Save confidence
    # ...

    #Validate does not display message, but will work
    # validate(need(input$user_confidence, 'You must select your confidence before continuing.'))
    removeModal()
  })


  # ---- Post-experiment logic ----
  output$user_completion_code <- renderText({
    appValues$completion_code
  })


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
