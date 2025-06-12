# This files decompress the .db into individual json files

library(DBI)
library(RSQLite)
library(R.utils)
library(jsonlite)
library(purrr)
library(dplyr)
library(furrr)

# This is the input format: "data/channel_1009639194.db"
decompress_channel <- function(f, out_dir = "data_decompressed") {
  channel_id <- sub(".*(channel_\\d+)\\.db$", "\\1", f)
  con <- dbConnect(RSQLite::SQLite(), dbname = f)
  tryCatch({
    df <- dbReadTable(con, "messages")
    out <- map(df$message, decompress_message) |>
      bind_rows()
  }, error = function(e) {
    message("Caught an error, but continuing: ", channel_id)
    writeLines(channel_id, "errors.txt")
    return(NULL)  # Return something to continue
  })
  dbDisconnect(con)

  rio::export(out, file.path(out_dir, paste0(channel_id, ".csv")))
  return(out)
}

decompress_message <- function(m) {
  decompressed <- memDecompress(m, type = "gzip", asChar = TRUE) |>
    fromJSON()
  tibble::tibble(
    id = pluck(decompressed, "id", .default = NA_integer_),
    channel_id = pluck(decompressed, "peer_id", "channel_id", .default = NA_integer_),
    date = pluck(decompressed, "date",, .default = NA_character_),
    message = pluck(decompressed, "message", .default = NA_character_)
  )
}

dir.create("data_decompressed", showWarnings = FALSE)

channel_files <- list.files("data", ".db$", full.names = TRUE)
plan(multisession, workers = 12)
future_walk(channel_files, decompress_channel, .progress = interactive())
