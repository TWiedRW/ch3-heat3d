show_correct <- function(guess_larger, correct_larger, guess_slider, correct_slider) {
  showModal(modalDialog(
    title = "Practice Trial Solution",
    easyClose = TRUE,
    size = "xl",
    fluidRow(
        h5("Question 1: Which value represents a larger quantity?"),
        div(
          style = "display: flex; justify-content: center; align-items: center; flex-direction: column;",
          p(glue("Your answer: {guess_larger}")),
          p(glue("Correct answer: {correct_larger}"))
        ),
        h5("Question 2: If the larger value you selected above represents 100 units, 
                  how many units is the smaller value?"),
        div(
            style = "display: flex; justify-content: center; align-items: center;",
            sliderInput(
          inputId = "practice_guess_slider",
          label = "Your answer:",
          min = 0,
          max = 100,
          value = guess_slider,
          ticks = FALSE,
          step = 0.1
            )
        ),
        div(
            style = "display: flex; justify-content: center; align-items: center;",
            sliderInput(
          inputId = "practice_correct_slider",
          label = "Correct answer:",
          min = 0,
          max = 100,
          value = correct_slider,
          step = 0.1, 
          ticks = FALSE
            )
        )
    )
  ))
}

