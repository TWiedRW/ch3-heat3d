require(RSQLite)

conn <- dbConnect(SQLite(), 'data/graphics-group(04-07-2025).db')

dbListTables(conn)
blocks <- dbReadTable(conn, 'blocks')
confidence <- dbReadTable(conn, 'confidence')
results <- dbReadTable(conn, 'results')
users <- dbReadTable(conn, 'users')

dbDisconnect(conn)

blocks
confidence
results
users
