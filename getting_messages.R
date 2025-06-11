# Install required packages if not already installed
install.packages("DBI")
install.packages("RSQLite")

# Load libraries
library(DBI)
library(RSQLite)

# Connect to the database
con <- dbConnect(RSQLite::SQLite(), "/Users/ernestodeleon/Downloads/channel_1000154686.db")

# List tables in the database
dbListTables(con)

# Read a specific table (replace 'your_table_name' with a name from the list above)
df <- dbReadTable(con, "messages")

# Preview the data
head(df, 1)



# Load required package
install.packages("jsonlite")  # if not already installed
library(jsonlite)

# Optionally load dplyr for cleaner manipulation
library(dplyr)

# Parse one row as a test
parsed <- fromJSON(df$message[1])

# View parsed content
str(parsed)




library(dplyr)
library(jsonlite)
library(purrr)

# Read all messages from DB
df <- dbReadTable(con, "messages")


# Define a helper to safely extract the message field
extract_message <- function(x) {
  if (!is.null(x$message) && length(x$message) == 1) x$message else NA_character_
}

# Read and parse messages
parsed_df <- df %>%
  mutate(parsed = map(message, ~ safely(fromJSON)(.x)$result)) %>%
  transmute(
    message_id,
    text = map_chr(parsed, extract_message)
  )




library(dplyr)
library(stringr)
library(tidyr)

# 1. Define regex to extract URLs
url_regex <- "https?://[^\\s]+"

# 2. Extract all URLs into a list column
parsed_df <- parsed_df %>%
  mutate(urls = str_extract_all(text, url_regex))

# 3. Unnest the list into one row per URL
url_data <- parsed_df %>%
  select(message_id, urls) %>%
  unnest(urls)

# 4. Extract domain names from each URL
url_data <- url_data %>%
  mutate(domain = str_extract(urls, "(?<=https?://)[^/]+"))

# 5. Count domain occurrences
domain_counts <- url_data %>%
  count(domain, sort = TRUE)

# View the result
print(domain_counts)

