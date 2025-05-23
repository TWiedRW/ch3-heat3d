write_to_db <- function(df, database, write = T){
  require(RSQLite)
  if(write){
    conn <- dbConnect(SQLite(), database)
    dbWriteTable(conn, deparse(substitute(df)), df, append = TRUE)
    message(glue('New entry was appended to {deparse(substitute(df))}'))
    dbDisconnect(conn)
  }
}
