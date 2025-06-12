# This files decompress the .db into individual json files

library(DBI)
library(RSQLite)
library(R.utils)
library(jsonlite)
library(furrr)

channel_files <- list.files("data", ".db$", full.names = TRUE)

# This is the input format: "data/channel_1009639194.db"
decompress_channel <- function(x) {
  dir.create("decompressed_json/", showWarnings = FALSE)
  if (!file.exists("done.txt"))
    file.create("done.txt", showWarnings = FALSE)

  channel_id <- sub(".*(channel_\\d+)\\.db$", "\\1", x)
  if (channel_id %in% readLines("done.txt")) return(NULL)

  tryCatch({

    con <- dbConnect(RSQLite::SQLite(), dbname = x)
    df <- dbReadTable(con, "messages")
    for (i in seq_along(df$message)) {
      decompressed <- memDecompress(df$message[[i]], type = "gzip", asChar = TRUE)
      json_list <- fromJSON(decompressed) # We need this step to deal with unicode escape
      message_id <- json_list$id
      filename <- paste0("decompressed_json/", channel_id, "_", message_id, ".json")
      writeLines(toJSON(json_list), filename)
    }
    write(channel_id, file = "done.txt", append = TRUE)

  }, error = function(e) {

    message("Caught an error, but continuing: ", channel_id)
    write(channel_id, file = "errors.txt", append = TRUE)
    return(NULL)  # Return something to continue

  })
}

# run on 12 cores in parallel
plan(multisession, workers = 12)
future_walk(channel_files, decompress_channel, .progress = interactive())
