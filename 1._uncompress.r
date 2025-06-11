# This files decompress the .db into individual json files

library(DBI)
library(RSQLite)
library(R.utils)
library(jsonlite)

channel_files <- list.files("data", ".db$", full.names = TRUE)

# This is the input format: "data/channel_1009639194.db"
decompress_channel <- function(x) {
  channel_id <- sub(".*(channel_\\d+)\\.db$", "\\1", x)
  con <- dbConnect(RSQLite::SQLite(), dbname = x)
  df <- dbReadTable(con, "messages")
  for (i in seq_along(df$message)) {
    decompressed <- memDecompress(df$message[[i]], type = "gzip", asChar = TRUE)
    json_list <- fromJSON(decompressed) # We need this step to deal with unicode escape
    message_id <- json_list$id
    filename <- paste0("decompressed_json/", channel_id, "_", message_id, ".json")
    writeLines(toJSON(json_list), filename)
    #message("Decompressed to: ", filename, " (", i, "/", nrow(df), ")")
  }
}

for (file in channel_files) {
  message("Decompressing ", file)
  decompress_channel(file)
}
