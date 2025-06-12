library(DBI)
library(RSQLite)
library(tidyverse)
library(stringr)
library(dataverse)


#download chats.db to data folder
Sys.setenv("DATAVERSE_SERVER" = "dataverse.harvard.edu")
data_files <- get_dataset(dataset = "https://doi.org/10.7910/DVN/1M5KHX") |>
  pluck("files") |>
  filter(label == "chats.db") |>
  mutate(download_url = map_chr(id, \(id) get_file(id, return_url = TRUE)))

curl::curl_download(data_files$download_url, file.path("data", data_files$filename))


#read chat.db
con <- dbConnect(RSQLite::SQLite(), dbname = "data/chats.db")
dbListTables(con)

df <- dbReadTable(con, "chats")

keywords <- c("trump", "maga", "donald") #choose your own key words

pattern <- paste(keywords, collapse = "|")
filtered_df <- df %>%
  filter(str_detect(token, pattern)) %>%
  select(type_and_id) %>%
  drop_na(type_and_id) %>%
  distinct(type_and_id)

writeLines(filtered_df$type_and_id, "channel with key words.txt")


download_db_files <- function(urls, destfiles) {
  destfiles_all <- destfiles
  done <- file.exists(destfiles)
  urls <- urls[!done]
  destfiles <- destfiles[!done]
  id <- seq_along(urls)
  chunks <- split(id, ceiling(id / 30))
  cli::cli_progress_step("downloading {sum(!done)} files")
  for (chunk in cli::cli_progress_along(chunks)) {
    curl::multi_download(
      urls[chunk],
      destfiles[chunk],
      progress = FALSE
    )
    Sys.sleep(5)
  }
  cli::cli_progress_done()
  done <- file.exists(destfiles)
  if (any(!done)) {
    cli::cli_alert_info("{sum(!done)} still missing")
    download_db_files(urls, destfiles)
  }
  return(destfiles_all)
}


channels <- read_lines("channel with key words.txt")
data_files <- tibble(name = channels) %>%
  mutate(
    #size_h = prettyunits::pretty_bytes(size),
    download_url = glue::glue("https://g-b81a79.a78b8.36fe.data.globus.org/{name}?download=1")
  )

#download the .db files
df <- data_files |>
  mutate(downloaded = download_db_files(
    download_url,
    file.path("data", name)
  ))
