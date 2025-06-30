# Options
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

# UI
ui_demographics <- fluidPage(
  column(
    width = 8, offset = 2,
    wellPanel(
      h2('Demographics'),
      p('In this section, please fill out the following demographic questions. All questions must be answered before continuing the study.'),
      column(width = 6, selectizeInput("user_age", "What category includes your age?",
                                       choices = options_ages, width = '100%'),
             selectizeInput("user_gender", "How would you describe your gender identity?",
                            choices = options_gender, width = '100%'))
      ,
      column(width = 6, selectizeInput("user_education",
                                       "What is your highest education level?",
                                       choices = options_education, width = '100%'),
             selectizeInput('user_reason',
                            'How is your participation graded?',
                            width = '100%',
                            choices = options_reason)),
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
