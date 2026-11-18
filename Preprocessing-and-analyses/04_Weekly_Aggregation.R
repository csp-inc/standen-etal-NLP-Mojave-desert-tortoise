## ---------------------------
## 
## Project: TLD NLP
## 
## Script name: 04_Weekly_Aggregation.R
##
## Purpose of script: this script creates dataset representing weekly aggregations for tweet and article metrics
##
## Author: Madeline Standen
##
## Date last updated: 10/19/2026
##
## Email contact: standenmadeline[at]gmail.com, madi[at]csp-inc.org
##
## ---------------------------

# Clear memory (if necessary)
rm(list=ls())

# Load packages
list.of.packages <- c("lubridate","dplyr","parallel","stringr", "ggplot2","zoo","readr","ggpubr","scales","patchwork","cowplot", "Rtsne", "nlme", "mgcv","Deriv",
                      "ggpmisc","gridExtra","MASS","msm","sandwich","foreign", "performance", "broom", "gplots", "RColorBrewer", "clValid","dendextend", "gratia",
                      "ggeffects","DHARMa","pscl","AICcmodavg","lmtest","viridis","trend","tidytext","tidyr","stringr","wordcloud","VennDiagram","tseries","funtimes","systemfonts",
                      "tm", "SnowballC", "wordcloud", "cluster", "factoextra", "topicmodels","tm","text", "textTinyR", "dplyr", "ggplot2", "tm", "text2vec", "uwot","textstem")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only = TRUE)


# Articles -----
articles <- read.csv("./data_final/NFWF_articles_final_filter2_topics.csv")[,-1]

articles <- articles %>% mutate(Date = as.Date(date),
                                article_id = as.character(article_id),
                                Week_of_start = floor_date(Date, unit = "week"),
                                Week_of_end = ceiling_date(Date, unit = "week") - 1,.after = "Date")

weekly_articles <- articles %>%
  group_by(Week_of_start,Week_of_end) %>%
  summarise(Article_Count = n(),Vader_articles = mean(Raw_Sentiment_Score),Article_topic_n = length(unique(topic)) ,.groups = "drop")

# Using the old dataset to pull in the week column (for ease)
week_key <- read.csv("./data_final/Week_key.csv")[,-1]
week_key$Week_of_start <- as.Date(week_key$Week_of)
# Removes empty rows at the end
week_key <- week_key %>%
  filter(!is.na(Week_of_start))

week_key <- week_key %>% arrange(Week_of_start)

setdiff(week_key$Week_of,weekly_articles$Week_of_start)

weekly_articles <- weekly_articles %>% left_join(week_key)
weekly_articles$Week[weekly_articles$Week == "Other"] <- "Other week"
weekly_articles <- weekly_articles %>% dplyr::select(Article_Count,Vader_articles,Article_topic_n,Week,Week_of_start)
write.csv(weekly_articles,"./data_final/NFWF_weekly_articles.csv")

# Tweets-----

tweet_raw <- read.csv("./data_final/NFWF_tweets_final_topics.csv") %>% arrange(Date)
str(tweet_raw)
tweet_raw <- tweet_raw %>% mutate(Date = as.Date(Date),
                                  User = as.character(User),
                                  Week_of_start = floor_date(Date, unit = "week"),
                                  Week_of_end = ceiling_date(Date, unit = "week") - 1,.after = "Date")
max(tweet_raw$Week_of_start)
length(unique(tweet_raw$User))

first_seen <- tweet_raw %>%
  group_by(User) %>%
  summarise(First_Date = min(Date), .groups = "drop") %>%
  mutate(Week_of_first = floor_date(First_Date, unit = "week"))


tweet_raw <- tweet_raw %>% left_join(first_seen,by = join_by(User))
tweet_raw <- tweet_raw %>% mutate(Users_new = ifelse(Week_of_first == Week_of_start, 1, 0))

tweet_raw <- tweet_raw %>%
  group_by(User) %>%
  mutate(Users_new = ifelse(Users_new == 1 & cumsum(Users_new == 1) == 1, 1, 0)) %>%
  ungroup()

# Re-create the weekly summarized tweet data
weekly_tweets <- tweet_raw %>%
  group_by(Week_of_start,Week_of_end) %>%
  summarise(Tweet_Count = n(), Vader = mean(Raw_Sentiment_Score),Users = length(unique(User)),Users_new = sum(Users_new), tweet_topic_n = length(unique(topic)),.groups = "drop")

weekly_tweets <- weekly_tweets %>% mutate(Year = year(Week_of_start),Month = month(Week_of_start))
weekly_tweets <- weekly_tweets %>% arrange(Week_of_start)



# Using the old dataset to pull in the week column (for ease)
week_key <- read.csv("./data_final/Week_key.csv")
week_key$Week_of <- as.Date(week_key$Week_of)
# Removes empty rows at the end
week_key <- week_key %>%
  filter(!is.na(Week_of))
# Filter out one week with no raw tweet data
week_key <- week_key %>% filter(Week_of != "2024-08-11")
week_key <- week_key %>% arrange(Week_of)

setdiff(week_key$Week_of,weekly_tweets$Week_of_start)

weekly_tweets$Week <- week_key$Week
weekly_tweets$Week[weekly_tweets$Week == "Other"] <- "Other week"

rm(week_key)

write.csv(weekly_tweets,"./data_final/NFWF_weekly_tweets.csv")

# Combining both datasets into final weekly dataset -----

tweet_counts <- read.csv("./data_final/NFWF_weekly_tweets.csv")[,-1]
tweet_counts <- tweet_counts %>% mutate(Week_of_start = as.Date(Week_of_start),
                                        Week_of_end = as.Date(Week_of_end))



# Adding sentiment categories using cutoffs as factor for analyses
tweet_counts <- tweet_counts %>%
  mutate(Sentiment = case_when(
    Vader < -0.05 ~ 1,  # If Vader is less than -0.05, it's Negative
    Vader > 0.05 ~ 3,   # If Vader is greater than 0.05, it's Positive
    TRUE ~ 2             # Otherwise, it's Neutral
  )) %>% mutate(Sentiment = factor(Sentiment,
                                   levels = 1:3,
                                   labels = c("Negative",
                                              "Neutral",
                                              "Positive")))

article_counts <- read.csv("./data_final/NFWF_weekly_articles.csv")[,-1] %>% mutate(Week_of_start = as.Date(Week_of_start)) %>% dplyr::select(-Week)

# Adding sentiment categories using cutoffs as factor for analyses
article_counts <- article_counts %>%
  mutate(Sentiment_articles = case_when(
    Vader_articles < -0.05 ~ 1,  # If Vader is less than -0.05, it's Negative
    Vader_articles > 0.05 ~ 3,   # If Vader is greater than 0.05, it's Positive
    TRUE ~ 2             # Otherwise, it's Neutral
  )) %>% mutate(Sentiment_articles = factor(Sentiment_articles,
                                            levels = 1:3,
                                            labels = c("Negative",
                                                       "Neutral",
                                                       "Positive")))


weekly_dat_all <- tweet_counts %>% left_join(article_counts, by = c("Week_of_start")) 

weekly_dat_all <- weekly_dat_all %>% mutate(Article_Count = if_else(is.na(Article_Count),0,Article_Count)) %>%
  mutate(Article_topic_n = if_else(is.na(Article_topic_n),0,Article_topic_n))

# Normalizing users based on temporal twitter trends

twitter_users_year <- read.csv("./data_final/Statista_Twitter_use_data_Yearly_users.csv")
colnames(twitter_users_year) <- c("Year","Users_ALL")
twitter_users_year$Users_ALL_real <- twitter_users_year$Users_ALL*1000000

weekly_dat_all <- weekly_dat_all %>% left_join(twitter_users_year)
weekly_dat_all <- weekly_dat_all %>% mutate(Users_new = if_else(Users_new == 0,1,Users_new))
weekly_dat_all <- weekly_dat_all %>% mutate(Users_adjusted = Users/Users_ALL_real) %>% mutate(Users_new_adjusted = Users_new/Users_ALL_real)
weekly_dat_all <- weekly_dat_all %>% mutate(Tweet_per_user = Tweet_Count/Users)
weekly_dat_all <- weekly_dat_all %>% arrange(Week_of_start) %>% mutate(log_Tweet_Count = log(Tweet_Count),log_Article_Count = log(Article_Count+1),log_Users = log(Users),log_Users_new = log(Users_new),log_Users_adjusted = log(Users_adjusted),log_Users_new_adjusted = log(Users_new_adjusted),log_Tweets_per_user = log(Tweet_per_user))
weekly_dat_all <- weekly_dat_all %>% mutate(Prop_new = Users_new/Users, log_Prop_new = log(Prop_new+1))


write.csv(weekly_dat_all,"./Weekly_aggregated_data.csv")
