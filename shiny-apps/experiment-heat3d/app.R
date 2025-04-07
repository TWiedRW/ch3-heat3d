# ---- MAJOR TO-DO ----
#| Create logic to save data to database
#| instructions, practice, end page
#| Save number of clicks on 3dd charts
#| Disable ability to click on tabs
#| Fix 3dp so that it closely resembles 3dd
#| Delete saving of completion code and pre-hash



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
#|    Informed consent for non-218 includes reference to replication
#|    of CM's 1984 study.
#| Font sizes for value definitions
#| Time stamps for each page of the app
#|
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
source('../../R/shiny_fn-write_to_db.R')
source('../../R/shiny_fn-practice_order.R')



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
  fluidRow(shiny::column(12, align = 'center', h1('Heat3d: A study on 3D Heatmaps'))),
  sidebarLayout(
    sidebarPanel(
      selectInput('is_218_student',
                  label = 'Are you currently enrolled in Stat 218?',
                  choices = c("Please pick one of the following" = "",
                              "Yes, I am a Stat 218 student" = "TRUE",
                              "No, I am not a Stat 218 student" = "FALSE"),
                  selected = '', selectize = T),
      conditionalPanel(
        'input.is_218_student != ""',
        p('Please read the informed consent document. A link to download a pdf version of the informed consent is provided at the bottom of the this page.'),
        radioButtons('data_consent',
                     'Select "Yes" if you agree to the informed consent and you agree to let us collect your data',
                     choices = c('Yes, I agree' = "TRUE", 'No, I do not agree' = "FALSE"),
                     selected = ''),
        actionButton('submit_consent', 'Submit')
      )
    ),
    mainPanel(
      conditionalPanel('input.is_218_student == "TRUE" && input.is_218_student!=""', includeHTML('informed-consent/graphics-consent-218.html')),
      conditionalPanel('input.is_218_student == "FALSE" && input.is_218_student!=""', includeHTML('informed-consent/graphics-consent-dept.html'))
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
    p('For this survey, you will be using charts to estimate the relationship between a pair of values across different chart types.
    These charts consist of 2D digitally rendered heatmaps, 3D digitally rendered heatmaps, and, if applicable, 3D printed heatmaps.'),
    uiOutput('instruction_plots'),
    fluidRow(column(4, style = "margin-bottom: 0px;", tags$figure(
      class = "centerFigure",
      tags$img(
        src = "2dd-example.png",
        width = "90%",
        alt = "2dd"
      ),
      tags$figcaption("2D Digital")
    )),
    column(4, style = "margin-bottom: 0px;", tags$figure(
      class = "centerFigure",
      tags$img(
        src = "3dd-example.png",
        width = "90%",
        alt = "3dd"
      ),
      tags$figcaption("3D Digital")
    )),
    column(4, style = "margin-bottom: 0px;", tags$figure(
      class = "centerFigure",
      tags$img(
        src = "3dp-example.png",
        width = "90%",
        alt = "3dp"
      ),
      tags$figcaption("3D Printed")
    ))),
    checkboxInput('user_online', label = 'Select this option if you do not have access to the 3D printed heatmaps.',
                  value = F),



    p('Pairs of values are defined by upper and lower case instances of the same letter and are located on the heatmap.
    Each question will define the pair of values and you will need to identify the locations of the values on the heatmap.
    If it is difficult to identify the location of the values on heatmap, there is an option to produce a map showing the locations.'),

    p('Once you have identified the location of the values, you will need to select which of the two values in the pair is larger in magnitude.
    If you believe that the two values are of the same magnitude, you may check that they are the same size.






      '),
    radioButtons('instruction_guess_smaller',
                 'Which of the following values is larger?',
                 choices = c('Value 1', 'Value 2', 'They are the same'),
                 selected = ''),


    p('More text will go here, plus pictures...'),
    actionButton('submit_start_exp', 'Start Experiment')
  )),
  fluidRow(column(12, align = 'center', h1('Practice Question'))),
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

# ---- Practice ----

ui_practice <- fluidPage(
  useShinyjs(),
  uiOutput('practice_display')
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
  tabPanel('Practice', ui_practice), # Disabled for now
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
    is_218_student = NULL,
    data_consent = NULL,
    can_save = FALSE,
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
    validate(need(input$data_consent != '', "You must select an option for whether or not your data can be collected."))

    appValues$appStartTime <- appStartTime
    appValues$session <- session()
    appValues$is_218_student <- input$is_218_student
    appValues$data_consent <- input$data_consent
    appValues$completion_code <- generate_completion_code(valid_words)

    message(glue('The following app values were generated:'))
    message(glue('\tappStartTime: {appValues$appStartTime}'))
    message(glue('\tsession: {appValues$session}'))
    message(glue('\tis_218_student: {appValues$is_218_student}'))
    message(glue('\tdata_consent: {appValues$data_consent}'))
    message(glue('\tcompletion_code: {appValues$completion_code}'))

    if(appValues$data_consent == T){
      updateNavbarPage(inputId = 'navpage', selected = 'Demographics')

    } else {
      updateNavbarPage(inputId = 'navpage', selected = 'Practice')
      message('This user did not consent to data collection. Their results will not be saved.')
    }
  })

  # ---- Demographics logic ----


  observeEvent(input$submit_demographics, {

    # Save demographic fields
    demographicValues$user_age        <- input$user_age
    demographicValues$user_gender     <- input$user_gender
    demographicValues$user_education  <- input$user_education
    demographicValues$user_reason     <- input$user_reason
    demographicValues$user_unique     <- input$user_unique



    # Hash values
    appValues$user_pre_hash <- glue('{appValues$completion_code}-{demographicValues$user_age}-{demographicValues$user_gender}-{demographicValues$user_education}-{demographicValues$user_reason}-{demographicValues$user_unique}')
    appValues$user_id <- rlang::hash(appValues$user_pre_hash)
    appValues$can_save <- (input$data_consent==T) & (input$user_age != "Under 19")

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

    # Write to database
    users <- tibble(
      appStartTime     =     appValues$appStartTime,
      session          =     appValues$session,
      is_218_student   =     appValues$is_218_student,
      data_consent     =     appValues$data_consent,
      can_save         =     appValues$can_save,
      # user_pre_hash    =     appValues$user_pre_hash, #DELETE THIS ONE
      user_id          =     appValues$user_id,
      # completion_code  =     appValues$completion_code, #DELETE THIS ONE
      user_age         =     demographicValues$user_age,
      user_gender      =     demographicValues$user_gender,
      user_education   =     demographicValues$user_education,
      user_reason      =     demographicValues$user_reason,
      user_unique      =     demographicValues$user_unique
    )

    if(appValues$can_save){
      write_to_db(users, database, write = T)
      message(glue('Table "users" was successfully updated for user: {appValues$user_id}'))
    } else{
      message(glue('User {appValues$user_id} is under 19 years old, so their responses will not be recorded'))
    }

    # Update page
    updateNavbarPage(inputId = 'navpage', selected = 'Practice')

})
  # ---- Instructions logic ----
  observeEvent(input$submit_start_exp, {
    shiny::removeModal()
    updateNavbarPage(inputId = 'navpage', selected = 'Experiment')
  })

  # ---- Practice logic ----

  practiceValues <- reactiveValues(
    user_id = NULL,
    trialStartTime = NULL,
    trialEndTime = NULL,
    trialNumber = NULL,
    trialSet = NULL,
    block = NULL,
    user_practice_results = NULL,
    user_practice_trial_num = NULL,
    user_practice_trial_max = NULL,
    user_practice_set_num = NULL,
    user_practice_set_max = NULL,
    user_practice_3d_matrix = NULL,
    user_practice_slice = NULL,
    user_practice_helper = FALSE,
    user_practice_guess_larger = NULL,
    user_practice_guess_slider = NULL,
    data_consent = NULL,
    can_save = NULL,
    user_practice_last_trial = FALSE
  )

  observeEvent((input$submit_consent) | (input$submit_demographics), {

    #Trial information
    practiceValues$user_practice_results <- practice_order()


    #Label information
    practiceValues$user_practice_results <- practiceValues$user_practice_results %>%
      left_join(stimuli_labels, relationship = 'many-to-many',
                by = 'pair_id') %>%
      select(-c(label_stl)) %>%
      pivot_wider(values_from = label,
                  names_from = within_pair)


    practiceValues$user_practice_trial_num <- min(practiceValues$user_practice_results$user_trial_order)
    practiceValues$user_practice_trial_max <- max(practiceValues$user_practice_results$user_trial_order)

    #First Trial
    practiceValues$user_practice_slice <- dplyr::filter(practiceValues$user_practice_results,
                                                        user_trial_order == practiceValues$user_practice_trial_num)

    #Set information
    practiceValues$user_practice_set_num <- practiceValues$user_practice_slice$user_set_order
    practiceValues$user_practice_set_max <- max(practiceValues$user_practice_results$user_set_order)

    # Update values
    shinyjs::delay(10, {updateRadioButtons(inputId = 'user_practice_guess_larger',
                                           choices = c(practiceValues$user_practice_slice$p1,
                                                       practiceValues$user_practice_slice$p2,
                                                       'The two values are the same.'),
                                           selected = '')})

  })

  # Create helper plot
  output$practice_plot_helper <- renderPlot({
      'practice' = plot_helper(practice_data, practiceValues$user_practice_slice$pair_id)
  })

  # Create plot for 2dd
  output$plot_2dd_practice <- renderPlot({
    plot_2dd(practice_data)
  })

  # Create plot for 3dd
  output$plot_3dd_practice <- renderRglwidget({
    render_3dd('../../print-files/practice/rgl-practice_data-base.stl',
                                '../../print-files/practice/rgl-practice_data-bars.stl',
                                '../../print-files/practice/rgl-practice_data-letters.stl')
    rglwidget()
  })


  # Render UI for chart helper
  output$practice_plot_helper <- renderUI({
    validate(need(input$user_practice_helper, ''))
    plotOutput('practice_plot_helper', width = '50%')
  })

  # Render UI for experiment chart
  output$practice_plot <- renderUI({
    switch (practiceValues$user_practice_slice$media,
            '2dd' = plotOutput('plot_2dd_practice'),
            '3dd' = tagList(
              rglwidgetOutput('plot_3dd_practice'),
              helpText('You may use your mouse to move the chart on the screen.'),
              helpText('Left click: move the plot.'),
              helpText('Scroll: zoom in and out.')
            )

    )
    # plotOutput('plot_helper', width = '70%')

  })


  # Practice UI
  output$practice_display <- renderUI({

    fluidPage(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
      ),
      sidebarLayout(
        sidebarPanel(
          h1('Practice'),
          h2(glue('Trial {practiceValues$user_practice_trial_num} of {practiceValues$user_practice_trial_max}')),
          h3(glue('Group {practiceValues$user_practice_set_num} of {practiceValues$user_practice_set_max}')),
          radioButtons('user_practice_guess_larger',
                       'Which of the following values is larger?',
                       choices = c('Value 1', 'Value 2', 'They are the same.'),
                       selected = ''),
          sliderInput('user_practice_guess_slider',
                      'If the larger value you selected above represents 100 units, how many units does the smaller value represent?',
                      min = 0, max = 100, value = 50, ticks = F, step = 0.1),

          actionButton('submit_practice_trial',
                       'Submit'),

          checkboxInput('user_practice_helper', 'Select this checkbox if you need help identifying the two values on the chart.'),
          helpText('This is a practice trial. Your response is not recorded.')

        ),
        mainPanel(
          column(width = 6,
                 uiOutput('practice_plot', width = '100%'),
          ),
          column(width = 6,
                 uiOutput('practice_plot_helper')
          )


        )
      )
    )
  })

  # observeEvent(input$user_practice_guess_larger, {
  #   if(input$user_practice_guess_larger == 'They are the same.'){
  #     updateSliderInput(inputId = 'user_practice_guess_slider', value = 100)
  #     shinyjs::disable(id = 'user_practice_guess_slider')
  #   } else {
  #     shinyjs::enable(id = 'user_practice_guess_slider')
  #   }
  #
  # })

  observeEvent(input$submit_practice_trial, {


    # Update trial number and trial slice
    if(practiceValues$user_practice_trial_num < practiceValues$user_practice_trial_max){
      practiceValues$user_practice_trial_num <- practiceValues$user_practice_trial_num + 1

      practiceValues$user_practice_slice <- dplyr::filter(practiceValues$user_practice_results,
                                                          user_trial_order == practiceValues$user_practice_trial_num)
      # shinyjs::delay(100, updateSliderInput(inputId = 'user_practice_helper', value = user_practice_helper_toggle))

      practiceValues$user_practice_set_num <- practiceValues$user_practice_slice$user_set_order
      # If next trial is last trial, create marker for confidence question
      if(practiceValues$user_practice_trial_num == practiceValues$user_practice_trial_max){
        practiceValues$user_practice_last_trial <- TRUE
      }
    } else if(practiceValues$user_practice_trial_num  == practiceValues$user_practice_trial_max){

      showModal(modalDialog(
        p('You have successfully completed the practice trials. Click the button below to start the experiment.'),
        actionButton('submit_start_exp', 'Start Experiment'),
        title = 'Practice trials complete!',
        easyClose = F,
        footer = NULL
      ))




    } else {
      message('Trial number exeeds maximun number of trials. What happened???')
    }

    # Update values
    updateRadioButtons(inputId = 'user_practice_guess_larger',
                       choices = c(practiceValues$user_practice_slice$p1,
                                   practiceValues$user_practice_slice$p2,
                                   'They are the same.'),
                       selected = '')

  })





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
    user_3d_matrix = NULL,
    user_slice = NULL,
    user_helper = FALSE,
    user_guess_larger = NULL,
    user_guess_slider = NULL,
    data_consent = NULL,
    can_save = NULL,
    user_last_trial = FALSE
  )




  observeEvent(input$submit_start_exp, {

    #User information
    expValues$user_id <- appValues$user_id
    expValues$data_consent <- appValues$data_consent
    expValues$can_save <- appValues$can_save
    expValues$block <- pick_block(database)
    expValues$trialStartTime <- Sys.time()
    message(glue('Block {expValues$block} was chosen for user {expValues$user_id}'))

    if(appValues$can_save){
      blocks <- tibble(
        block = expValues$block,
        user_id = expValues$user_id,
        system_time = expValues$trialStartTime
      )
      write_to_db(blocks, database, write = appValues$can_save)
    }

    #Trial information
    expValues$user_results <- randomize_order(expValues$block, plan, remove_3dp = input$user_online)


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

    # Update values
    shinyjs::delay(10, {updateRadioButtons(inputId = 'user_guess_larger',
                       choices = c(expValues$user_slice$p1,
                                   expValues$user_slice$p2,
                                   'The two values are the same.'),
                       selected = '')})

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
            'set1' = render_3dd('../../print-files/set1/rgl-data1-base.stl',
                                '../../print-files/set1/rgl-data1-bars.stl',
                                '../../print-files/set1/rgl-data1-letters.stl'),
            'set2' = render_3dd('../../print-files/set2/rgl-data2-base.stl',
                                '../../print-files/set2/rgl-data2-bars.stl',
                                '../../print-files/set2/rgl-data2-letters.stl')
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
              helpText('Left click: move the plot.'),
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
          radioButtons('user_guess_larger',
                       'Which of the following values is larger?',
                       choices = c('Value 1', 'Value 2', 'They are the same.'),
                       selected = ''),
          sliderInput('user_guess_slider',
                      'If the larger value you selected above represents 100 units, how many units does the smaller value represent?',
                      min = 0, max = 100, value = 50, ticks = F, step = 0.1),

          actionButton('submit_user_trial',
                       'Submit'),

          checkboxInput('user_helper', 'Select this checkbox if you need help identifying the two values on the chart.'),
          conditionalPanel('input.data_consent == "FALSE"', shiny::helpText('Demo mode: your answers will not be saved.'))

        ),
        mainPanel(
          column(width = 6,
            uiOutput('experiment_plot', width = '100%'),
          ),
          column(width = 6,
            uiOutput('experiment_plot_helper')
          )


        )
      )
    )
  })

  observeEvent(input$user_guess_larger, {
    if(input$user_guess_larger == 'They are the same.'){
      updateSliderInput(inputId = 'user_guess_slider', value = 100)
      shinyjs::disable(id = 'user_guess_slider')
    } else {
      shinyjs::enable(id = 'user_guess_slider')
    }

  })

  observeEvent(input$submit_user_trial, {
    # Save data into database here
    expValues$trialEndTime <- Sys.time()
    results <- tibble(
      user_id = appValues$user_id,
      user_helper = input$user_helper,
      trialStartTime = expValues$trialStartTime,
      trialEndTime = expValues$trialEndTime,
      block = expValues$block,
      user_guess_larger = input$user_guess_larger,
      user_guess_slider = input$user_guess_slider
    ) %>%
      bind_cols(expValues$user_slice)
    write_to_db(results, database, write = appValues$data_consent)

    # user_helper_toggle <- isolate({input$user_helper})

    # Update start time for next trial
    expValues$trialStartTime <- expValues$trialEndTime

    # Update trial number and trial slice
    if(expValues$user_trial_num < expValues$user_trial_max){
      expValues$user_trial_num <- expValues$user_trial_num + 1

      expValues$user_slice <- dplyr::filter(expValues$user_results, user_trial_order == expValues$user_trial_num)
      # shinyjs::delay(100, updateSliderInput(inputId = 'user_helper', value = user_helper_toggle))
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
          title = 'Confidence Rating',
          footer = NULL

        ))
      }

      expValues$user_set_num <- expValues$user_slice$user_set_order
      # If next trial is last trial, create marker for confidence question
      if(expValues$user_trial_num == expValues$user_trial_max){
        expValues$user_last_trial <- TRUE
      }
    } else if(expValues$user_trial_num  == expValues$user_trial_max){
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
        title = 'Confidence Rating',
        footer = NULL

      ))
      # Move to ending page
      message(glue('The following user has completed the experiment!'))
      message(glue('\t{appValues$user_id}'))
      updateNavbarPage(inputId = 'navpage', selected = 'Wrap-up')
    } else {
      message('Trial number exeeds maximun number of trials. What happened???')
    }

    # Update values
    updateRadioButtons(inputId = 'user_guess_larger',
                       choices = c(expValues$user_slice$p1,
                                   expValues$user_slice$p2,
                                   'They are the same.'),
                       selected = '')

  })

  # Enable confidence submit button when choice is selected
  observeEvent(input$user_confidence, {
    updateActionButton('submit_confidence',
                       session = getDefaultReactiveDomain(),
                       disabled = F)
  })


  observeEvent(input$submit_confidence, {
    confidence <- tibble(
      user_id = expValues$user_id,
      user_confidence = input$user_confidence
    )

    write_to_db(confidence, database, write = appValues$data_consent)

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
