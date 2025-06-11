library(tidyverse)
db_files <- list.files("data_decompressed/", pattern = ".db$", full.names = TRUE)

db <- DBI::dbConnect(RSQLite::SQLite(), db_files[1])
DBI::dbListTables(db)

details <- tbl(db, "details") |> 
  collect()

details$chat |> 
  jsonlite::fromJSON()

profile_pic <- tbl(db, "profile_pictures")

messages <- tbl(db, "messages") |> 
  collect()

mes1 <- messages$message[1] |> 
  jsonlite::fromJSON()
