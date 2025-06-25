modal_instructions <- function() {
    require(shiny)
    showModal(modalDialog(
        title = "Instructions",
        easyClose = TRUE,
        #footer = NULL,
        tags$div(
            tags$p("In this experiment, you will be tasked with estimating numerical quantities of 2D and 3D heatmaps. Please ensure that your web browser is in the full screen mode before starting the experiment."),
            tags$p("You will be presented a series of charts on the right-hand side of your screen. If you are an in-person participant, you will occasionally be directed to use the 3D-printed charts located in LPH 208.1 or HARH 349E."),
            tags$p("Each trial consists of two questions for a pair of values marked on the charts. A reference heatmap above “Question 1” indicates the locations for each value."),
            tags$p("Question 1 asks you to identify which value of the pair represents a larger quantity. If you believe that the pair of values represent the same quantity, select “Both values are the same”. Question 2 asks you to use the slider to estimate the quantity of the smaller value if the larger value represents 100 units. After completing all trials for a particular chart type, you will be asked to rate your confidence in your answers. "),
            tags$p("For example, suppose that the marked coordinates indicated that the current trial compares “B” to “b”.  If “b” represented the larger quantity, select “b” for Question 1. For Question 2, if “B” is approximately 3/4 the height of “b”, then move the slider so that it is around 75. "),
            tags$p("If you encounter any issues with the experiment, please email Dr. Susan VanderPlas (susan.vanderplas@unl.edu) with a description of the problem.")
        )
))
}
