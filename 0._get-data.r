# globus ls --long --format json c3e4dc38-a5e2-47d5-baa2-8b3f5b2a59db:/ > 0.datafiles.json

library(tidyverse)
data_files <- jsonlite::read_json(("0.datafiles.json")) |> 
  pluck("DATA") |> 
  bind_rows() |> 
  mutate(
    size_h = prettyunits::pretty_bytes(size),
    download_url = glue::glue("https://g-b81a79.a78b8.36fe.data.globus.org/{name}?download=1")
  )

# get 15 random channels
set.seed(42)
df <- data_files |> 
  slice_sample(prop = 0.01) |> 
  mutate(downloaded = curl::multi_download(
    download_url,
    file.path("data", name)
  ))

# library(dataverse)
# Sys.setenv("DATAVERSE_SERVER" = "dataverse.harvard.edu")
# 
# data_files <- get_dataset(dataset = "https://doi.org/10.7910/DVN/1M5KHX") |> 
#   pluck("files") |> 
#   # head(15) |> 
#   mutate(download_url = map_chr(id, \(id) get_file(id, return_url = TRUE)))
# 
# rio::export(data_files, "0._data_files.csv")
# dir.create("data", showWarnings = FALSE)
# 
# curl::multi_download(
#   urls = data_files$download_url[1:6], 
#   destfile = file.path("data", data_files$filename[1:6])
# )

