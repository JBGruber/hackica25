library(tidyverse)
library(dataverse)
Sys.setenv("DATAVERSE_SERVER" = "dataverse.harvard.edu")

data_files <- get_dataset(dataset = "https://doi.org/10.7910/DVN/1M5KHX") |> 
  pluck("files") |> 
  # head(15) |> 
  mutate(download_url = map_chr(id, \(id) get_file(id, return_url = TRUE)))

rio::export(data_files, "0._data_files.csv")
dir.create("data", showWarnings = FALSE)

curl::multi_download(
  urls = data_files$download_url[1:6], 
  destfile = file.path("data", data_files$filename[1:6])
)

