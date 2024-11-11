#' Create stimuli values.
#'
#' `create_stimuli()` creates a dataset using the method of constant stimuli.
#' This approach generates varying values by using equally spaced ratios between
#' the constant stimuli and the stimuli with the maximum value. The ratios are
#' then replicated with the constant stimuli as the maximum value to create
#' the stimuli that are smaller than the constant stimuli.
#'
#' @import dplyr
#' @import tidyr
#' @importFrom magrittr %>%
#'
#' @param stimuli_constant The stimuli value that will remain constant.
#' @param stimuli_max The maximum stimuli value.
#' @param num_stimuli Total number of stimuli. If an even number is used, the
#'  number of stimuli increases by one.
#' @returns A tibble
#' @export
#' @examples
#' create_stimuli()
#'

create_stimuli <- function(stimuli_constant=50, stimuli_max=90, num_stimuli=9){
  #Parameters
  constant <- stimuli_constant
  max_val <- stimuli_max
  l <- (num_stimuli+1)/2

  #Ratios
  ratios <- seq(constant/max_val, 1, l = l)

  #Values
  lower <- constant*ratios
  upper <- rev(constant/ratios)
  values <- unique(c(lower, upper))

  #Stimuli
  stimuli <- expand_grid(values, constant) %>%
    mutate(pair_id = row_number())

  return(stimuli)
}
