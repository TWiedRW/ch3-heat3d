show_instruction_modal <- function(){
  require(shiny)
  showModal(modalDialog(
    p('In this study, you will be asked to estimate values on two or three types of charts.
      Please place your web browser into full screen mode before starting the experiment.'),

    p('The first question asks you which of two values, indicated by letters, represents a larger quantity.
      These letters are located on bars or tiles of the chart to the right side of your computer screen.
      If applicable, you will be directed to use one of the 3D-printed charts.'),

    p('The next question asks you to estimate the quantity of the smaller value that you indicated in the first question.
      Click and drag on the slider to make your estimate.'),
    p('Once you have answered both questions, you may click the Submit button to advance to the next chart.
      If you encounter any technical issues with the application, please contact either Dr. Susan VanderPlas (susan.vanderplas@unl.edu) or Tyler Wiederich (twiederich2@huskers.unl.edu) to report the issue.
      For STAT 218 students, a completion code will appear once you have completed the experiment.'),
    actionButton('submit_close_instructions', 'Close'),
    footer = NULL,
    title = 'Instructions'
  ))
}
