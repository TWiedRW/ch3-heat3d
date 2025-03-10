# Create a database with starting block values.
# Other tables will populate when appended.

create_db <- function(output_location, plan){
  require(RSQLite)
  conn <- dbConnect(SQLite(), output_location)
  load('../../data/plan.rda')
  num_blocks = max(plan$block)
  blocks <- data.frame(
    block = 1:num_blocks,
    user_id = 'Initial setup - please delete me',
    system_time = Sys.time()
  )
  dbWriteTable(conn, 'blocks', blocks)
  dbDisconnect(conn)
}
