# Load necessary libraries for data manipulation, date parsing, plotting, and factor handling
library(lubridate)  # for working with dates
library(dplyr)      # for data wrangling (filter, mutate, etc.)
library(ggplot2)    # for creating visualizations
library(tidyr)      # for reshaping data (unnest, pivot)
library(forcats)    # for factor reordering (fct_* functions)

# Read in the CSV of news-domain classifications (with MBFC fact-check scores)
news <- read.csv('news_classification/dt_pc1-no-newsguard_weights.csv')

# Split domains into "extremist" and "high_quality" based on MBFC factuality score thresholds
extremist <- news %>%
  filter(mbfc_fact <= 0.3) %>%        # keep domains with low fact scores
  select(domain)

high_quality <- news %>%
  filter(mbfc_fact >= 0.7) %>%        # keep domains with high fact scores
  select(domain)

# Define a vector of known social-media domains for classification
social_media_domains <- c(
  "youtube.com", "youtu.be", "facebook.com", "fb.com", "twitter.com",
  "x.com", "t.me", "instagram.com", "whatsapp.com", "snapchat.com",
  "reddit.com", "linkedin.com", "pinterest.com", "discord.gg", "discord.com"
)

# All other news domains (neither high-quality nor extremist, and not social media)
other_news <- news %>%
  filter(
    !domain %in% high_quality$domain,
    !domain %in% extremist$domain,
    !domain %in% social_media_domains
  )


# === Read and prepare the Telegram messages ===
msgs2 <- read.csv('news_classification/messages.csv')  # raw messages file
msgs <- read.csv('news_classification/us_election_chat.csv')  # raw messages file 2


msgs <- msgs %>% mutate (message_id = id)

msgs <- bind_rows(msgs, msgs2)

colnames(msgs)  # inspect column names

# Define a regex that captures http(s) URLs
url_regex <- "https?://[^\\s]+"

# 1. Extract all URLs from each message into a list-column
msgs <- msgs %>%
  mutate(urls = str_extract_all(message, url_regex))

# 2. Expand the list of URLs so each URL gets its own row
url_data <- msgs %>%
  select(message_id, urls, date, peer_id) %>%  # keep only relevant columns
  unnest(urls)                                 # one URL per row

# 3. Extract the numeric channel ID from the peer_id string
url_data <- url_data %>%
  mutate(
    channel_id = as.integer(str_extract(peer_id, "\\d+"))  # grab digits
  ) %>%
  select(-peer_id)  # drop the original peer_id column now that we have channel_id

# 4. From each URL, parse out the bare domain (host)
url_data <- url_data %>%
  mutate(
    domain = str_extract(urls, "(?<=https?://)[^/]+")  # text after http(s):// up to '/'
  )

# 5. Classify each domain into one of our news_type categories
url_data <- url_data %>%
  mutate(
    news_type = case_when(
      domain %in% extremist$domain     ~ "extremist",
      domain %in% high_quality$domain  ~ "high_quality",
      domain %in% other_news$domain    ~ "other",
      domain %in% social_media_domains ~ "social_media",
      TRUE                             ~ "none"        # no classification
    )
  )

# === Summary counts and visualizations ===
# Count how many links of each type
news_type_counts <- url_data %>%
  count(news_type, sort = TRUE)
news_type_counts  # view the raw counts

# 6. Bar chart: share of each link type across all URLs
url_data %>%
  count(news_type) %>%
  mutate(pct = n / sum(n) * 100) %>%
  ggplot(aes(x = fct_reorder(news_type, pct), y = pct, fill = news_type)) +
  geom_col() +
  coord_flip() +
  labs(
    x = NULL,
    y = "Percent of Links",
    title = "Share of Links by News Type"
  )

# 7. Time series: daily counts of each link type
url_data %>%
  mutate(date = as_date(date)) %>%    # convert string to Date
  count(date, news_type) %>%
  ggplot(aes(x = date, y = n, color = news_type)) +
  geom_line() +
  labs(
    x = "Date",
    y = "Number of Links",
    title = "Daily Link Shares by News Type"
  )

# 8. Channel-level profile: proportion of each news_type per channel
channel_profile <- url_data %>%
  group_by(channel_id, news_type) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(channel_id) %>%
  mutate(pct = count / sum(count)) %>%
  ungroup()

# Example: top 10 channels by share of extremist links
channel_profile %>%
  filter(news_type == "extremist") %>%
  arrange(desc(pct)) %>%
  slice_head(n = 10)


# === Heatmap of link-type proportions for top channels ===
url_data2 <- url_data  # duplicate for clarity

# 1. Identify the top 20 channels by total URL count
top_ch <- url_data2 %>%
  count(channel_id) %>%
  slice_max(n, n = 20) %>%
  pull(channel_id)

# 2. Compute proportion of each link type for these channels
heat_df <- url_data2 %>%
  filter(channel_id %in% top_ch) %>%
  count(channel_id, news_type) %>%
  group_by(channel_id) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup() %>%
  mutate(
    channel_id = fct_inorder(as.character(channel_id)),  # preserve ordering
    news_type = fct_rev(news_type)                      # reverse y-axis order
  )

# 3. Plot heatmap of proportions
ggplot(heat_df, aes(x = channel_id, y = news_type, fill = prop)) +
  geom_tile(color = "white") +
  scale_fill_viridis_c(labels = scales::percent_format()) +
  labs(
    x = "Channel ID",
    y = "News Type",
    fill = "Proportion",
    title = "Heatmap of Link-Type Proportions by Channel (Top 20)"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )
