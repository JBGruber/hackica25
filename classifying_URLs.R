

news = read.csv('/Users/ernestodeleon/Downloads/dt_pc1-no-newsguard_weights.csv')



extremist = news %>% filter(mbfc_fact <= 0.3) %>% select(domain)

high_quality = news %>% filter(mbfc_fact >= 0.7) %>% select(domain)

social_media_domains <- c(
  "youtube.com", "youtu.be", "facebook.com", "fb.com", "twitter.com",
  "x.com", "t.me", "instagram.com", "whatsapp.com", "snapchat.com",
  "reddit.com", "linkedin.com", "pinterest.com", "discord.gg", "discord.com"
)

other_news <- news %>%
  filter(
    !domain %in% high_quality$domain,
    !domain %in% extremist$domain,
    !domain %in% social_media_domains
  )



#Read in messages
msgs = read.csv('/Users/ernestodeleon/Downloads/messages.csv')
colnames(msgs)

library(tidyr)

# 1. Define regex to extract URLs
url_regex <- "https?://[^\\s]+"

# 2. Extract all URLs into a list column
msgs <- msgs %>%
  mutate(urls = str_extract_all(message, url_regex))

# 3. Unnest the list into one row per URL
url_data <- msgs %>%
  select(message_id, urls) %>%
  unnest(urls)

# 4. Extract domain names from each URL
url_data <- url_data %>%
  mutate(domain = str_extract(urls, "(?<=https?://)[^/]+"))

url_data <- url_data %>%
  mutate(news_type = case_when(
    domain %in% extremist$domain     ~ "extremist",
    domain %in% high_quality$domain  ~ "high_quality",
    domain %in% other_news$domain    ~ "other",
    domain %in% social_media_domains ~ "social_media",
    TRUE                             ~ "none"
  ))

# 5. Count domain occurrences
news_type_counts <- url_data %>%
  count(news_type, sort = TRUE)
news_type_counts
