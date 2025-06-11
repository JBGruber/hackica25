# globus ls --long --format json c3e4dc38-a5e2-47d5-baa2-8b3f5b2a59db:/ > 0.datafiles.json

library(tidyverse)
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


data_files <- jsonlite::read_json(("0.datafiles.json")) |>
  pluck("DATA") |>
  bind_rows() |>
  mutate(
    size_h = prettyunits::pretty_bytes(size),
    download_url = glue::glue("https://g-b81a79.a78b8.36fe.data.globus.org/{name}?download=1")
  )

# download a sample for now
set.seed(42)
df <- data_files |>
  slice_sample(prop = 0.01) |>
  mutate(downloaded = download_db_files(
    download_url,
    file.path("data", name)
  ))
