modal_instructions <- function() {
    require(shiny)
    showModal(modalDialog(
        title = "Instructions",
        easyClose = TRUE,
        #footer = NULL,
        tags$div(
            tags$p("In this experiment, you will be tasked with estimating numerical quantities on 2D and 3D heatmaps. Please make sure that your web browser is in the full screen mode."),
            tags$p("Charts will be presented on the right side of your screen. If you are an in-person participant, you may also be directed to use the 3D-printed charts located in LPH 208.1 or HARH XXX. "),
            tags$p("Each trial consists of two questions for a pair of values marked on the charts. The pair of values is identified by red tiles on the grid above the questions. The first questions asks you to identify which value in the pair represents a larger quantity. The second question asks you to use the slider to estimate the quantity of the smaller value if the larger value represents 100 units. After completing all trials for a particular chart, you will be asked to rate your confidence in your answers. "),
            tags$p("For example, suppose that the marked coordinates indicated that the current trial compares “B” to “b”.  If “b” represented the larger quantity, select “b” for the first question. For the second question, if “B” is approximately 3/4 the height of “b”, then move the slider so that it is around 75. "),
            tags$p("If you encounter any issues with the experiment, please contact Dr. Susan VanderPlas (susan.vanderplas@unl.edu) or Tyler Wiederich (twiederich2@huskers.unl.edu)."),
            tags$p("Thank you for your participation!")
        )
    ))
}
