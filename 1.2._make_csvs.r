library(tidyverse)
telegram_messages_combined <- list.files("data_decompressed", pattern = ".csv$", full.names = TRUE) |> 
  lapply(\(f) read_csv(f, col_types = "iicc")) |> 
  bind_rows() |> 
  select(id, channel_id, date, message)

rio::export(telegram_messages_combined, "data/telegram_messages_combined.csv")
telegram_data_links <- telegram_messages_combined |> 
  filter(!is.na(message)) |> 
  mutate(urls = stringr::str_extract_all(message, "\\bhttp.+\\b")) |> 
  select(id, channel_id, urls) |> 
  unnest_longer(urls, values_to = "url") |> 
  mutate(domain = adaR::ada_get_domain(url))

rio::export(telegram_data_links, "data/telegram_links_combined.csv")
