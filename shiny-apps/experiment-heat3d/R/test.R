if (FALSE) {
  library(RSQLite)
  library(tidyverse)
  conn <- dbConnect(RSQLite::SQLite(), "shiny-apps/experiment-heat3d-new-logic/data/stat218-summer2025.db")
  dbReadTable(conn, 'exp_results')
  dbReadTable(conn, 'blocks')
  dbReadTable(conn, 'completion_code')
  dbReadTable(conn, 'users')
  dbDisconnect(conn)
}