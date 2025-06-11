library(tidyverse)
telegram_data <- rio::import("data/telegram_messages_combined.csv")
telegram_data_links <- telegram_data |> 
  mutate(urls = stringr::str_extract_all(message, "\\bhttp.+\\b")) |> 
  select(id, channel_id, urls) |> 
  unnest_longer(urls, values_to = "url")

rio::export(telegram_data_links, "data/telegram_links_combined.csv")
