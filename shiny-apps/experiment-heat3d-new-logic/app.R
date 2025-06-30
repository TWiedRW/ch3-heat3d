# TODO
#| Add confidence questions
#| Save each rgl scene

# Load packages and functions
library(shiny)
library(shinythemes)
library(shinyjs)
library(glue)
library(RSQLite)
library(tidyverse)
library(magrittr)
renv::snapshot()
message(glue("Shiny app opened at: {getwd()}"))

load("../../data/valid_words.rda")
load("../../data/stimuli_labels.rda")
load("../../data/data1.rda")
load("../../data/data2.rda")
load("../../data/plan.rda")
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
source("modals/modal_instructions.R")
source("modals/modal_show_correct.R")

# Initial Values
app_start_time <- Sys.time()
database <- "data/development.db"
message(glue("Active database: {database}"))

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
  theme = shinythemes::shinytheme("sandstone"),
  div(
    style = "text-align: center;",
    h1("Stat 218 Experiment: 2D and 3D Heat Maps")
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
      p("Please read the informed consent on the right side of the screen. You may download a PDF copy of the informed consent 
        by clicking the following link."),
      div(
        style = "text-align: center;",
        tags$a(
          href = "informed_consent.pdf",
          target = "_blank",
          "Download Informed Consent (PDF)"
        )
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
      conditionalPanel(
        condition = "input.is_online == 'FALSE'",
        helpText("If your Stat 218 course is held in-person, 
          you will need to have access to the 3D-printed charts.")
      ),
      conditionalPanel(
        #'input.is_218_student != "" && 
        #input.is_online != "" && 
        #input.data_consent != ""',
        'true',
        p("Click on the button below to advance to the next page."),
        div(style = "text-align: center; width: 100%;",
          actionButton("submit_consent", "Continue")
        )
      )

    ),
    mainPanel(
      div(
        style = "max-height: 600px; overflow-y: auto; border: 1px solid #ccc; padding: 10px;",
        includeHTML("informed-consent/graphics-consent-218.html")
      )
    )
  )
)


# ---- Demographics ----
options_ages <- c("Under 19", "19-25", "26-30",
                  "31-35", "36-40", "41-45", "46-50",
                  "51-55", "56-60", "Over 60",
                  "Prefer not to answer")
options_gender <- c("Female", "Male",
                    "Variant/Nonconforming",
                    "Prefer not to answer")

options_education <- c("High School or Less",
                       "Some Undergraduate Courses",
                       "Undergraduate Degree",
                       "Some Graduate Courses",
                       "Graduate Degree",
                       "Prefer not to answer")
options_reason <- c("Participation credit",
                    "Extra credit",
                    "Other",
                    "Not applicable")

ui_demographics <- fluidPage(
  column(
    width = 6, offset = 3,
    wellPanel(
      div(style = "text-align: center;", h2("Demographics")),
      p("Please complete the following demographic questions. All fields are required before proceeding. Once all questions are answered, a button will appear to continue to the next page."),

      div(
        radioButtons("user_age", "What category includes your age?",
             choices = options_ages, selected = "", inline = TRUE),
        radioButtons("user_gender",
             "How would you describe your gender identity?",
             choices = options_gender, selected = "", inline = TRUE),
        radioButtons("user_education",
             "What is your highest education level?",
             choices = options_education, selected = "", inline = TRUE),
        radioButtons("user_reason",
             "How is your participation graded?",
             selected = "", inline = TRUE,
             choices = options_reason)
      ),
      div(style = "text-align: center;", h3("Unique Identifier")),
      p("The next question helps us to uniquely identify your responses 
      in our study. Your answer will not be used in attempt to identify you."),
      textInput("user_unique", "What is your favorite movie and/or actor?"),

      conditionalPanel(
        'input.user_age !== "" && 
         input.user_gender !== "" && 
         input.user_education !== "" && 
         input.user_reason !== "" && 
         input.user_unique !== ""',
        p("Click on the button below to advance to the next page."),
        div(style = "text-align: center;",
            actionButton("submit_demographics", "Continue"))
      )
    )
  )
)




# ---- Experiment ----
ui_experiment <- fluidPage(
  shinyjs::useShinyjs(),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  sidebarLayout(
    sidebarPanel(
      uiOutput("trialHeader"),

      p("For this trial, use the values indicated in the chart below to answer the questions."),
      plotOutput("plotHelper", height = "150px"),
      checkboxInput("isPractice",  "practice", value = TRUE),
      radioButtons("userLarger", "Question 1: Which value represents a larger quantity?",
                   choices = 1:3, selected = "", inline = FALSE),
      sliderInput("userSlider",
                  "Question 2: If the larger value you selected above represents 100 units, 
                  how many units is the smaller value?",
                  min = 0, max = 100, value = 50, ticks = FALSE, step = 0.1),
      helpText("You must move the slider at least once to submit your answer."),
      div(style = "text-align: center;", actionButton("submit", "Submit", width = "50%"))
    ),
    mainPanel(
      #textOutput("slider_clicks_txt"),
      #textOutput("rgl_clicks"),
      conditionalPanel("input.isPractice",
                      div(
                        style = "text-align: center;",
                        h2("Instructions"),
                        p("The first four trials are for practice. Click the 'Show Instructions' to display the instructions at any point during the practice trials. You may also display the correct solutions by clicking 'Show Solutions'."), # nolint
                        actionButton("showInstructions", "Show Instructions", width = "35%"),
                        actionButton("showCorrect", "Show Solution", width = "35%"),
                        hr()
                      )),
      uiOutput("exp_plot"),
      #tableOutput("current_slice"),
      #tableOutput("current_trial_data"),
      #tableOutput("trial_table")
    )
  )
)

# ---- UI Logic ----
app_ui <- navbarPage(
  "Heat Map Experiment",
  id = "expNav",
  header = tags$head(
    tags$script(HTML("
      $(document).on('shiny:connected', function() {
        $('.nav.navbar-nav > li > a').on('click', function(e) {
          e.preventDefault();
          return false;
        });
      });
    "))
  ),
  tabPanel("Informed Consent", ui_consent),
  tabPanel("Demographics", ui_demographics),
  tabPanel("Experiment", ui_experiment)
)

# ---- Server Logic ----
server <- function(input, output, session) {

  # Create a reactive value to store user information
  user_values <- reactiveValues(
    # User information
    is_218_student = NULL,
    is_online = NULL,
    data_consent = NULL,
    user_age = NULL,
    user_gender = NULL,
    user_education = NULL,
    user_reason = NULL,
    user_unique = NULL,
    user_id = NULL,
    can_save = NULL
  )

  # Create a reactive value to store the app values
  app_values <- reactiveValues(

    #App state
    exp_state = "practice",

    #Counters
    slider_clicks = -1,
    current_counter = NULL,
    slider_start = 0,
    clicks_3dd = 0,

    #All trials information
    experiment_trials_data = NULL,
    practice_trials_data = NULL,

    #Max trials
    practice_max = 4,
    experiment_max = NULL,

    #Current trials based on app state
    current_trials_data = NULL,
    current_max = NULL,
    current_media = "start",
    current_set = "start"
  )

  # Create a reactive value to store the experiment data
  exp_values <- reactiveValues(
    user_larger = NULL,
    user_slider = NULL
  )

  current_slice <- reactive({
    req(!is.null(app_values$current_trials_data))
    app_values$current_trials_data[app_values$current_counter, ]
  })

  # Initial startup values
  observeEvent(input$submit_consent, {
    validate(
    need(
      input$is_218_student != "",
      "Please select if you are enrolled in Stat 218."
    ),
    need(
      input$data_consent != "",
      "Please indicate your data consent choice."
    ),
    need(
      input$is_online != "",
      paste(
        "Please indicate if you have access to the",
        "3D-printed charts."
      )
    )
  )
    # Pick block for user
    user_values$block <- pick_block(database)

    # Generate completion code
    user_values$completion_code <- generate_completion_code(valid_words)
    completion_code <- data.frame(code = user_values$completion_code)
    write_to_db(completion_code,
                database = database, write = TRUE)
    message(glue("Completion code generated: {user_values$completion_code}"))

    #Initialize trials
    app_values$experiment_trials_data <- randomize_order(user_values$block, plan, input$is_online=="FALSE")
    app_values$practice_trials_data <- practice_order(plan = plan)

    #Initialize max values
    app_values$practice_max <- nrow(app_values$practice_trials_data)
    app_values$experiment_max <- nrow(app_values$experiment_trials_data)

    #Set practice as current
    app_values$current_trials_data <- app_values$practice_trials_data
    app_values$current_max <- app_values$practice_max
    app_values$current_counter <- 1

    # Move to Experiment tab if data consent is not given
    if(input$data_consent == "FALSE") {
      user_values$can_save <- FALSE
      updateNavbarPage(inputId = "expNav", selected = "Experiment")
      modal_instructions() 
      app_values$trial_start_time <- Sys.time()
    } else {
      updateNavbarPage(inputId = "expNav", selected = "Demographics")
    }
  })

  observeEvent(input$submit_demographics, {
    validate(
      need(input$user_age != "", "Please select your age category."),
      need(input$user_gender != "", "Please select your gender identity."),
      need(input$user_education != "", "Please select your highest education level."),
      need(input$user_reason != "", "Please select how your participation is graded."),
      need(input$user_unique != "", "Please provide a unique identifier.")
    )

    # Save user demographics
    user_values$user_age <- input$user_age
    user_values$user_gender <- input$user_gender
    user_values$user_education <- input$user_education
    user_values$user_reason <- input$user_reason
    user_values$user_unique <- input$user_unique

    user_values$user_id <- rlang::hash(paste(user_values$user_age,
                                             user_values$user_gender,
                                             user_values$user_education,
                                             user_values$user_reason,
                                             user_values$user_unique,
                                             #user_values$completion_code,
                                             app_values$app_start_time, collapse = "-"))

    # Allow data saving if user is not under 19
    if (input$user_age == "Under 19") {
      user_values$can_save <- FALSE
    } else {
      user_values$can_save <- TRUE
      blocks <- tibble(
        block = user_values$block,
        user_id = user_values$user_id,
        system_time = Sys.time()
      )
      write_to_db(blocks, database, write = user_values$can_save)
      message("Block information updated")
    }

    # Move to experiment tab
    updateNavbarPage(inputId = "expNav", selected = "Experiment")
    modal_instructions()
    app_values$trial_start_time <- Sys.time()
  })
  # Submit button logic
  observeEvent(input$submit, {
    validate(
      need(input$userLarger != "", "Please select which value is larger."),
      need(app_values$slider_clicks > 0, "You must move the slider at least once.")
    )

    exp_values$user_larger <- input$userLarger
    exp_values$user_slider <- input$userSlider

    exp_results <- current_slice() %>%
      dplyr::mutate(
        user_id = user_values$user_id,
        user_larger = exp_values$user_larger,
        user_slider = exp_values$user_slider,
        slider_start = app_values$slider_start,
        slider_clicks = app_values$slider_clicks,
        clicks_3dd = app_values$clicks_3dd,
        slider_start = app_values$slider_start,
        start_time = app_values$trial_start_time,
        end_time = Sys.time()
      )


    # Write results to database
    if(user_values$can_save) {
      write_to_db(exp_results, database, write = TRUE)
      message("Results written to database.")
    }


    if ((app_values$current_counter == app_values$current_max) &
          app_values$exp_state == "practice") {
      # Change from practice state to experiment state
      app_values$exp_state <- "experiment"
      app_values$current_counter <- 1
      app_values$slider_clicks <- -1
      app_values$clicks_3dd <- 0
      showModal(modalDialog(p("You successfully completed the practice trials. 
                               The next set of charts will be used for the experiment."),
                            title = "Practice trials completed",
                            size = "xl"))
    } else if ((app_values$current_counter == app_values$current_max) &
                 app_values$exp_state == "experiment") {
      # Experiment is complete
      showModal(modalDialog(p("You successfully completed the experiment. 
                              Here is your completion code: ",
                                div(style = "text-align: center;", p(strong(user_values$completion_code))),
                              p("Save this code as you will not have access 
                                  once you exit the application. You may now close this window."),
                              title = "Experiment complete!"),
                              footer = NULL))
    } else {
      # Update to next trial
      app_values$current_counter <- app_values$current_counter + 1
      app_values$slider_clicks <- -1
      app_values$clicks_3dd <- 0
      app_values$trial_start_time <- Sys.time()
    }
  })

  observe({
    if (app_values$exp_state != "practice") {
      app_values$current_trials_data <- app_values$experiment_trials_data
      app_values$current_max <- app_values$experiment_max
      updateCheckboxInput(inputId = "isPractice", value = FALSE)
    }
  })

  observeEvent(current_slice(), {
    req(is.reactive(current_slice))
    app_values$slider_start <- runif(1, 0, 100)
    updateSliderInput(inputId = "userSlider",
                      value = app_values$slider_start)
  })

  observeEvent(input$showCorrect, {
      req(app_values$exp_state == "practice")
      req(input$userLarger != "")

      practice_guess_larger <- isolate(input$userLarger)
      practice_guess_slider <- isolate(input$userSlider)
      practice_slice <- isolate(current_slice())

      practice_slice %>%
      left_join(switch(practice_slice$set,
        "practice" = practice_data,
        "set1" = data1,
        "set2" = data2
      ), by = c("pair_id"))

      correct_solutions <- practice_slice %>%
        left_join(switch(practice_slice$set,
          "practice" = practice_data,
          "set1" = data1,
          "set2" = data2
        ), by = c("pair_id")) %>%
        left_join(stimuli_labels, by = c("pair_id", "within_pair")) %>%
        mutate(
          correct_slider = min(z)/max(z) * 100,
          correct_larger = ifelse(
            length(unique(z)) == 1,
            "Both values are the same",
            label[which.max(z)]
          )
        ) %>% 
        select(set, media, pair_id, correct_larger, correct_slider) %>%
        distinct()

      show_correct(guess_larger = practice_guess_larger,
             correct_larger = correct_solutions$correct_larger[1],
             guess_slider = practice_guess_slider,
             correct_slider = correct_solutions$correct_slider[1]
      )
      shinyjs::disable("practice_correct_slider")
  })

  observe({
    req(is.reactive(current_slice))
    trial <- current_slice() %>%
      dplyr::left_join(data_labels, by = c("pair_id"))
    exp_choices <- c(trial$p1, trial$p2, "Both values are the same")
    updateRadioButtons(inputId = "userLarger",
                       choices = exp_choices,
                       selected = "", inline = FALSE)
  })

  observe({
    req(is.reactive(current_slice))
    if(app_values$current_media != current_slice()$media[1]) {
      app_values$current_media <- current_slice()$media[1]
    }
    if(app_values$current_set != current_slice()$set[1]) {
      app_values$current_set <- current_slice()$set[1]
    }
  })


  observeEvent(input$showInstructions, {
    modal_instructions()
  })
  
  observeEvent(input$userSlider, {
    app_values$slider_clicks <- app_values$slider_clicks + 1
  })

  output$plotHelper <- renderPlot({
    req(is.reactive(current_slice))
    switch(current_slice()$set,
      "practice" = plot_helper(practice_data,
                               as.numeric(current_slice()$pair_id),
                               stimuli_labels),
      "set1" = plot_helper(data1,
                           as.numeric(current_slice()$pair_id), stimuli_labels),
      "set2" = plot_helper(data2,
                           as.numeric(current_slice()$pair_id), stimuli_labels)
    )
  })

  output$trialHeader <- renderUI({
    trial_header <- switch(as.character(current_slice()$media)[1],
      "2dd" = "2D Heat Map",
      "3dd" = "3D Heat Map - Digital",
      "3dp" = "3D Heat Map - Physical",
      "")

    trial_state <- switch(app_values$exp_state,
      "practice" = "Practice ",
      "experiment" = ""
    )
 
   tagList(
      h2(glue::glue("{trial_state}Trial {app_values$current_counter} of 
                    {app_values$current_max}"),
         style = "text-align: center;")
      #h3(trial_header, style = "text-align: center;"))
   )
  })
  output$trial_table <- renderTable({
    app_values$current_trials_data %>%
        left_join(switch(app_values$current_trials_data$set[1],
          "practice" = practice_data,
          "set1" = data1,
          "set2" = data2
        ), by = c("pair_id"))
  })

  output$slider_clicks_txt <- renderText({
    req(is.reactive(current_slice))
    paste("Slider clicks:", app_values$slider_clicks)
  })

  # Create plot for 2dd
  output$plot_2dd <- renderPlot({
    req(is.reactive(current_slice))
    req(app_values$current_media == "2dd")
    switch(app_values$current_set,
      "practice" = plot_2dd(practice_data, stimuli_labels),
      "set1" = plot_2dd(data1, stimuli_labels),
      "set2" = plot_2dd(data2, stimuli_labels)
    )
  })

  # Create plot for 3dd
  output$plot_3dd <- rgl::renderRglwidget({
    req(is.reactive(current_slice))
    req(app_values$current_media == "3dd")
    switch(app_values$current_set,
          "practice" = plot_3dd(
              "../../print-files/practice/rgl-practice_data-base.stl",
              "../../print-files/practice/rgl-practice_data-bars.stl",
              "../../print-files/practice/rgl-practice_data-letters.stl"
          ),
          "set1" = plot_3dd(
              "../../print-files/set1/rgl-data1-base.stl",
              "../../print-files/set1/rgl-data1-bars.stl",
              "../../print-files/set1/rgl-data1-letters.stl"
          ),
          "set2" = plot_3dd(
              "../../print-files/set2/rgl-data2-base.stl",
              "../../print-files/set2/rgl-data2-bars.stl",
              "../../print-files/set2/rgl-data2-letters.stl"
          )
    )
    rgl::rglwidget()
  })

  # Create plot for 3dp
  output$plot_3dp <- renderImage({
    req(is.reactive(current_slice))
    req(app_values$current_media == "3dp")
    switch(app_values$current_set,
      "set1" = list(src = "www/set1-3dp.JPG", width = "400px"),
      "set2" = list(src = "www/set2-3dp.JPG", width = "400px")
    )
  }, deleteFile = FALSE)

  output$exp_plot <- renderUI({
    req(is.reactive(current_slice))
    switch(app_values$current_media,
      "2dd" = plotOutput("plot_2dd", height = "400px"),
      "3dd" = tagList(
        rgl::rglwidgetOutput("plot_3dd", height = "400px"),
        helpText("You can interact with the 3D plot above: click and hold to rotate, and scroll to zoom.")
      ),
      "3dp" = tagList(
        imageOutput("plot_3dp", height = "400px"),
        helpText("Use the 3D printed chart that looks like the image below.")
      )
    )
  })

  onclick("plot_3dd", {
    app_values$clicks_3dd <- app_values$clicks_3dd + 1
    message(glue("3D plot clicked {app_values$clicks_3dd} times."))
  })

  output$rgl_clicks <- renderText({
    req(app_values$clicks_3dd)
    paste("3D plot clicks:", app_values$clicks_3dd)
  })
}

# Run the application
shinyApp(ui = app_ui, server = server)