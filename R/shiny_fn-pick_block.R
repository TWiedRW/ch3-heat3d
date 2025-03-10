# # Function to randomly select a block for a participant
# # Note: this will also update the blocking table
#
# pick_block <- function(database, participant){
#   require(RSQLite)
#   data('plan')
#   possible_blocks <- sort(unique(plan$block))
#   current_time <- Sys.time()
#
#   # Get user table
#   conn <- dbConnect(SQLite(), database)
#   if('blocking' %in% dbListTables(conn)){
#     blocking <- dbReadTable(conn, 'blocking')
#   } else{
#     blocking <- data.frame(participant = 0, block = possible_blocks, time = Sys.time())
#     message('New database created')
#     dbWriteTable(conn, 'blocking', blocking)
#   }
#
#
#   # Current block information
#   blocks_used <- as.numeric((table(blocking$block)))
#
#   # Randomly sample blocks
#   block = sample(x = possible_blocks,
#                  size = 1,
#                  prob = 1/blocks_used)
#   new_entry <- data.frame(participant = participant,
#                           block = block,
#                           time = current_time)
#
#   # Update block information
#   dbWriteTable(conn, 'blocking', new_entry, append = T)
#   message(paste0("System message: new entry into 'blocking' table: ", participant, " at ", current_time))
#   dbDisconnect(conn)
#   return(block)
# }
# pick_block('data/test.db', 9)


pick_block <- function(database){
  # Read blocks used in database
  conn <- dbConnect(SQLite(), database)
  blocks <- dbReadTable(conn, 'blocks')
  dbDisconnect(conn)

  # Sample so that least used blocks are picked more often
  blocks_used <- as.numeric((table(blocks$block)))
  block = sample(x = 1:max(blocks$block),
                 size = 1,
                 prob = 1/blocks_used)
  return(block)
}
