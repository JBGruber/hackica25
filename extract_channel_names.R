# This files decompress the .db into individual json files

library(DBI)
library(tidyverse)



  con <- dbConnect(RSQLite::SQLite(), dbname = "data/chats.db")


  DBI::dbListTables(con)

  channel_names <- dbReadTable(con, "chats")
  channel_names <- channel_names %>% filter(!is.na(type_and_id)) %>%
    select(1:2|"timestamp") %>%
    mutate(channel_id = sub(".*(channel_\\d+)\\.db$", "\\1", type_and_id))

  save(channel_names, file="channel_names/channel_names.RData")
  dbDisconnect(con)
