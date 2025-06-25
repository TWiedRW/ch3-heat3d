if (FALSE) {
  library(RSQLite)
  library(tidyverse)
  conn <- dbConnect(RSQLite::SQLite(), "shiny-apps/experiment-heat3d-new-logic/data/development.db")
  dbListTables(conn)
  dbReadTable(conn, 'exp_results')
  dbReadTable(conn, 'blocks')
  dbReadTable(conn, 'completion_code')
  dbDisconnect(conn)
}