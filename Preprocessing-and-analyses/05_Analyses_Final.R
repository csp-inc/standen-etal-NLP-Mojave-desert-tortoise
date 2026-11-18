## ---------------------------
## 
## Project: TLD NLP
## 
## Script name: 05_Analyses_Final.R
##
## Purpose of script: this script runs all analyses included in the associated manuscript
##
## Author: Madeline Standen
##
## Date last updated: 11/18/2026
##
## Email contact: standenmadeline[at]gmail.com, madi[at]csp-inc.org
##
## ---------------------------


# Clear memory (if necessary)
rm(list=ls())

# Load packages
list.of.packages <- c("lubridate","dplyr","parallel","stringr", "ggplot2","zoo","readr","ggpubr","scales","patchwork","cowplot", "Rtsne", "nlme", "mgcv","Deriv", "zoo", "jpeg",
                      "ggpmisc","gridExtra","MASS","msm","sandwich","foreign", "performance", "broom", "gplots", "RColorBrewer", "clValid","dendextend", "gratia", "perm", "fastDummies",
                      "ggeffects","DHARMa","pscl","AICcmodavg","lmtest","viridis","trend","tidytext","tidyr","stringr","wordcloud","VennDiagram","tseries","funtimes","systemfonts",
                      "tm", "SnowballC", "wordcloud", "cluster", "factoextra", "topicmodels","tm","text", "textTinyR", "dplyr", "ggplot2", "tm", "text2vec", "uwot","textstem","forcats","forecast")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only = TRUE)

if(dir.exists("./figures") == FALSE){dir.create("./figures")}
## Loading data -----

weekly_dat_all <- read.csv("./Weekly_aggregated_data.csv")[,-1] %>% mutate(Week_of_start = as.Date(Week_of_start),
                                                                           Week_of_end = as.Date(Week_of_end))


article_raw <- read.csv("./Article_data.csv")[,-1]
tweet_raw <- read.csv("./Tweet_data.csv")[,-1]

## Chi-squared test to compare distribution of sentiment -----
### Tweets -----
mean(tweet_raw$Raw_Sentiment_Score)
sd(tweet_raw$Raw_Sentiment_Score)

groups <- levels(factor(tweet_raw$VADER_Sentiment))
combos <- combn(groups, 2, simplify = FALSE)

results <- lapply(combos, function(pair) {
  df <- tweet_raw %>% filter(VADER_Sentiment %in% pair)
  subset_table <- table(df$VADER_Sentiment)
  test <- chisq.test(subset_table)
  data.frame(
    group1 = pair[1],
    group2 = pair[2],
    p_value = test$p.value,
    x2 = test$statistic
  )
})

results_df <- do.call(rbind, results)
results_df$p_adj <- p.adjust(results_df$p_value, method = "bonferroni")
print(results_df)


p_tweet_bar <- ggplot(
  tweet_raw,
  aes(x = as.factor(VADER_Sentiment), fill = as.factor(VADER_Sentiment))
) +  
  geom_bar() +
  geom_text(
    stat = "count",
    aes(label = after_stat(count)),
    color = "black",
    vjust = -0.3
  ) +
  # scale_fill_manual(values = c("#bd242a", "#d14f2b", "#f1c40f")) +
  scale_fill_manual(values = c("gray", "gray", "gray")) +
  scale_x_discrete(
    breaks = c("negative", "neutral", "positive"),
    labels = c("Negative", "Neutral", "Positive")
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  theme_minimal() +
  labs(x = "", y = "Count", title = "(a) Tweets") +
  theme(legend.position = "none",
        plot.title = element_text(size = 14, face = "bold")
  ) 

p_tweet_bar

ggsave('./figures/Chi-squared_bar_tweets.png',width = 7, height = 4)


### Articles -----
mean(article_raw$Raw_Sentiment_Score)
sd(article_raw$Raw_Sentiment_Score)

groups <- levels(factor(article_raw$VADER_Sentiment))
combos <- combn(groups, 2, simplify = FALSE)

results <- lapply(combos, function(pair) {
  df <- article_raw %>% filter(VADER_Sentiment %in% pair)
  subset_table <- table(df$VADER_Sentiment)
  test <- chisq.test(subset_table)
  data.frame(
    group1 = pair[1],
    group2 = pair[2],
    p_value = test$p.value,
    x2 = test$statistic
  )
})

results_df <- do.call(rbind, results)
results_df$p_adj <- p.adjust(results_df$p_value, method = "bonferroni")
print(results_df)


p_article_bar <- ggplot(
  article_raw,
  aes(x = as.factor(VADER_Sentiment), fill = as.factor(VADER_Sentiment))
) +  
  geom_bar() +
  geom_text(
    stat = "count",
    aes(label = after_stat(count)),
    color = "black",
    vjust = -0.3
  ) +
  # scale_fill_manual(values = c("#bd242a", "#d14f2b", "#f1c40f")) +
  scale_fill_manual(values = c("gray", "gray", "gray")) +
  scale_x_discrete(
    breaks = c("negative", "neutral", "positive"),
    labels = c("Negative", "Neutral", "Positive")
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  theme_minimal() +
  labs(x = "", y = NULL, title = "(b) Articles") +
  theme(legend.position = "none",
        plot.title = element_text(size = 14, face = "bold"))

p_article_bar
ggsave('./figures/Chi-squared_bar_articles.png',width = 7, height = 4)


p_all_bar <- grid.arrange(p_tweet_bar,p_article_bar, nrow = 1, ncol = 2,widths = c(0.42,0.4))
ggsave("./figures/Chi-squared_bar.jpeg", p_all_bar,
       width = 7, height = 4, units = "in", dpi = 300)

## Mann-Kendall (MK) test for trends -----

mk.test(weekly_dat_all$Vader) # significant and increasing
mk.test(weekly_dat_all$Users_adjusted) # significant and decreasing
mk.test(weekly_dat_all$Users_new_adjusted) # significant and decreasing
mk.test(weekly_dat_all$Tweet_per_user) # significant and increasing


mk.test(weekly_dat_all$Users)
mk.test(weekly_dat_all$Users_new)
mk.test(weekly_dat_all$Tweet_Count)

weekly_dat_all_articles <- weekly_dat_all %>% filter(Article_Count > 0)


mk.test(weekly_dat_all_articles$Article_Count)
mk.test(weekly_dat_all_articles$Vader_articles)


## Finding weekly outliers -----

identify_outliers <- function(df,variable) {
  # Calculate quartiles and IQR
  Q1 <- quantile(df[[variable]], 0.25, na.rm = TRUE)
  Q3 <- quantile(df[[variable]], 0.75, na.rm = TRUE)
  IQR_value <- Q3 - Q1
  
  lower_bound <- Q1 - 1.5 * IQR_value
  upper_bound <- Q3 + 1.5 * IQR_value
  
  # Create and rename the new column in one step
  df <- df %>%
    mutate(
      !!paste0(variable, "_Outlier") := case_when(
        .data[[variable]] < lower_bound ~ "Lower Outlier",
        .data[[variable]] > upper_bound ~ "Upper Outlier",
        TRUE ~ "Not Outlier"
      )
    )
  
  return(df)
}



weekly_dat_all <- identify_outliers(weekly_dat_all,"Vader")
weekly_dat_all <- identify_outliers(weekly_dat_all,"Tweet_per_user")
weekly_dat_all <- identify_outliers(weekly_dat_all,"Users_adjusted")
weekly_dat_all <- identify_outliers(weekly_dat_all,"Users_new_adjusted")
weekly_dat_all <- identify_outliers(weekly_dat_all,"Article_Count")
weekly_dat_all <- identify_outliers(weekly_dat_all,"Vader_articles")

tweet_counts_outliers_sentiment <- weekly_dat_all %>% filter(Vader_Outlier != "Not Outlier")
tweet_counts_outliers_count <- weekly_dat_all %>% filter(Tweet_per_user_Outlier != "Not Outlier")
tweet_counts_outliers_users <- weekly_dat_all %>% filter(Users_adjusted_Outlier != "Not Outlier")
tweet_counts_outliers_users_new <- weekly_dat_all %>% filter(Users_new_adjusted_Outlier != "Not Outlier")
article_counts_outliers_count <- weekly_dat_all %>% filter(Article_Count_Outlier != "Not Outlier")
article_counts_outliers_sentiment <- weekly_dat_all %>% filter(Vader_articles_Outlier != "Not Outlier")


# Filter data by year and date
dual_plot_data <- weekly_dat_all %>%
  rename(Average_Sentiment = Vader,User_Count = Users_adjusted, log_User_Count = log_Users_adjusted,Users_New = Users_new_adjusted,log_Users_New = log_Users_new_adjusted)

dual_plot_data <- dual_plot_data %>%
  mutate(Average_Sentiment_articles = na.approx(Vader_articles,na.rm = FALSE))

x_limits <- range(dual_plot_data$Week_of_start)
x_breaks <- seq(min(dual_plot_data$Week_of_start), max(dual_plot_data$Week_of_start), by = "1 year")

tweet_sentiment_outliers_p <- ggplot(dual_plot_data, aes(x=Week_of_start)) +
  geom_hline(
    aes(yintercept = 0),
    linetype = "solid", size = .5,color = 'gray'
  ) +
  geom_line( aes(y=Average_Sentiment), size=.6, color="black") + 
  geom_point( data = tweet_counts_outliers_sentiment, aes(y=Vader,color=Vader_Outlier), size=2) +
  scale_color_manual(values = c("Lower Outlier" = "#B23AEE", "Upper Outlier" = "#FFD700")) + 
  scale_x_date(limits = x_limits, breaks = x_breaks, date_labels = "%Y") + labs(x = NULL, y = "Tweet Sentiment", title = NULL)+
  theme_classic() + theme(legend.position = "none") +
  theme(
    plot.background  = element_rect(fill = NA, color = NA),
    panel.background = element_rect(fill = NA, color = NA),
    legend.background = element_rect(fill = NA, color = NA),
    legend.box.background = element_rect(fill = NA, color = NA)
  )

tweet_sentiment_outliers_p


article_sentiment_outliers_p <- ggplot(dual_plot_data, aes(x=Week_of_start)) +
  geom_hline(
    aes(yintercept = 0),
    linetype = "solid", size = .5,color = 'gray'
  ) +
  geom_line( aes(y=Average_Sentiment_articles), size=.6, color="black") + 
  geom_point( data = article_counts_outliers_sentiment, aes(y=Vader_articles,color=Vader_articles_Outlier), size=2) +
  scale_color_manual(values = c("Lower Outlier" = "#B23AEE", "Upper Outlier" = "#FFD700")) + 
  scale_x_date(limits = x_limits, breaks = x_breaks, date_labels = "%Y") + labs(x = NULL, y = "Article Sentiment", title = NULL)+
  theme_classic() + theme(legend.position = "none") +
  theme(
    plot.background  = element_rect(fill = NA, color = NA),
    panel.background = element_rect(fill = NA, color = NA),
    legend.background = element_rect(fill = NA, color = NA),
    legend.box.background = element_rect(fill = NA, color = NA)
  )

article_sentiment_outliers_p

tweet_count_outliers_p <- ggplot(dual_plot_data, aes(x=Week_of_start)) +
  geom_line( aes(y=Tweet_per_user), size=.6, color="black") + 
  geom_point( data = tweet_counts_outliers_count, aes(y=Tweet_per_user,color=Tweet_per_user_Outlier), size=2) +
  scale_color_manual(values = c("Lower Outlier" = "#B23AEE", "Upper Outlier" = "#FFD700")) + 
  scale_x_date(limits = x_limits, breaks = x_breaks, date_labels = "%Y") + labs(x = NULL, y = "Tweets per User", title = NULL)+
  theme_classic() + theme(legend.position = "none") +
  theme(
    plot.background  = element_rect(fill = NA, color = NA),
    panel.background = element_rect(fill = NA, color = NA),
    legend.background = element_rect(fill = NA, color = NA),
    legend.box.background = element_rect(fill = NA, color = NA)
  )

tweet_count_outliers_p

article_count_outliers_p <- ggplot(dual_plot_data, aes(x=Week_of_start)) +
  geom_line( aes(y=Article_Count), size=.6, color="black") + 
  geom_point( data = article_counts_outliers_count, aes(y=Article_Count,color=Article_Count_Outlier), size=2) +
  scale_color_manual(values = c("Lower Outlier" = "#B23AEE", "Upper Outlier" = "#FFD700")) + 
  scale_x_date(limits = x_limits, breaks = x_breaks, date_labels = "%Y") + labs(x = NULL, y = "Article Count", title = NULL)+
  theme_classic() + theme(legend.position = "none") +
  theme(
    plot.background  = element_rect(fill = NA, color = NA),
    panel.background = element_rect(fill = NA, color = NA),
    legend.background = element_rect(fill = NA, color = NA),
    legend.box.background = element_rect(fill = NA, color = NA)
  )

article_count_outliers_p

tweet_users_outliers_p <- ggplot(dual_plot_data, aes(x=Week_of_start)) +
  geom_line( aes(y=log_User_Count), size=.6, color="black") +
  geom_point( data = tweet_counts_outliers_users, aes(y=log_Users_adjusted,color=Users_adjusted_Outlier), size=2) +
  scale_color_manual(values = c("Lower Outlier" = "#B23AEE", "Upper Outlier" = "#FFD700")) + 
  scale_x_date(limits = x_limits, breaks = x_breaks, date_labels = "%Y") + labs(x = NULL, y = "Users (log)", title = NULL)+
  theme_classic() + theme(legend.position = "none") +
  theme(
    plot.background  = element_rect(fill = NA, color = NA),
    panel.background = element_rect(fill = NA, color = NA),
    legend.background = element_rect(fill = NA, color = NA),
    legend.box.background = element_rect(fill = NA, color = NA)
  )

tweet_users_outliers_p

tweet_users_new_outliers_p <- ggplot(dual_plot_data, aes(x=Week_of_start)) +
  # geom_line( aes(y=log_Users_New), size=.75, color="#528970") + 
  geom_line( aes(y=log_Users_New), size=.6, color="black") + 
  geom_point( data = tweet_counts_outliers_users_new, aes(y=log_Users_new_adjusted,color=Users_new_adjusted_Outlier), size=2) +
  # geom_line( aes(y=Users_New), size=.75, color="#528970") + 
  # geom_point( data = tweet_counts_outliers_users_new, aes(y=Users_new_adjusted,color=Users_new_adjusted_Outlier), size=2) +
  scale_color_manual(values = c("Lower Outlier" = "#B23AEE", "Upper Outlier" = "#FFD700")) + 
  scale_x_date(limits = x_limits, breaks = x_breaks, date_labels = "%Y") + labs(x = NULL, y = "New Users (log)", title = NULL)+
  theme_classic() + theme(legend.position = "none") +
  theme(
    plot.background  = element_rect(fill = NA, color = NA),
    panel.background = element_rect(fill = NA, color = NA),
    legend.background = element_rect(fill = NA, color = NA),
    legend.box.background = element_rect(fill = NA, color = NA)
  )

tweet_users_new_outliers_p


final_outliers_plot_all <- plot_grid(tweet_sentiment_outliers_p, article_sentiment_outliers_p,tweet_count_outliers_p, article_count_outliers_p,tweet_users_outliers_p,tweet_users_new_outliers_p,ncol = 1, align = "v", axis = "lr",rel_heights = c(.4,.4, .4, .4, .4, .4))
final_outliers_plot_all

ggsave('./figures/outliers_trend_adjusted_all.png',final_outliers_plot_all,width = 10, height = 10, units = "in", dpi = 300,bg = "transparent")
ggsave('./figures/outliers_trend_adjusted_all.jpeg',final_outliers_plot_all,width = 10, height = 10, units = "in", dpi = 300,bg = "transparent")


## Trends in sentiment departure and proportional contribution by topic -----

monthly_totals <- tweet_raw %>% filter(!is.na(topic)) %>%
  mutate(month = make_date(Year, Month, 1)) %>%
  count(month, name = "total")

tweet_time_month <- tweet_raw %>% filter(!is.na(topic)) %>%
  mutate(month = make_date(Year, Month, 1)) %>%
  filter(month >= as.Date("2012-01-01"), month <= as.Date("2024-12-01")) %>%
  group_by(topic) %>%
  mutate(topic_mean = mean(Raw_Sentiment_Score, na.rm = TRUE)) %>%
  group_by(topic, month) %>%
  summarise(
    n_topic  = n(),
    sent_dev = mean(Raw_Sentiment_Score, na.rm = TRUE) - first(topic_mean),
    .groups  = "drop"
  ) %>%
  complete(
    topic,
    month = seq(as.Date("2012-01-01"), as.Date("2024-12-01"), by = "month"),
    fill  = list(n_topic = 0)
  ) %>%
  left_join(monthly_totals, by = "month") %>%
  mutate(count = if_else(!is.na(total) & total > 0, n_topic / total, 0))


tweet_time_month <- tweet_time_month %>% as.data.frame() %>% mutate(topic = factor(topic, levels = c(1,2,3,4,5,6,7), labels = c("Tortoise conservation","Emotional and personal connections to tortoises","Renewable energy development",
                                                                                                                                "Tortoise movement and observation","Outreach and education","Ranching and human- wildlife conflict","California tortoise protection")))

tweet_time_month %>% group_by(topic) %>% summarise(mean_freq = mean(count),
                                                   med_freq = median(count),
                                                   sd_freq = sd(count),
                                                   cv_freq = mean_freq/sd_freq)

# Scale factor so the largest sentiment deviation reaches ~half the max count
k1 <- 0.5 * max(tweet_time_month$count) / max(abs(tweet_time_month$sent_dev), na.rm = TRUE)

p1 <- ggplot(tweet_time_month, aes(x = month)) +
  geom_ribbon(aes(ymin = 0, ymax = pmax(sent_dev, 0) * k1, fill = "Above topic mean"),
              alpha = 0.6, na.rm = TRUE) +
  geom_ribbon(aes(ymin = pmin(sent_dev, 0) * k1, ymax = 0, fill = "Below topic mean"),
              alpha = 0.6, na.rm = TRUE) +
  geom_hline(yintercept = 0, linewidth = 0.3, color = "grey60") +
  geom_line(aes(y = count), linewidth = 0.5, show.legend = FALSE) +
  facet_wrap(~ topic, ncol = 2) +
  # scale_color_manual(values = pal_topic1) +
  scale_fill_manual(values = c("Above topic mean" = "#3987e5",
                               "Below topic mean" = "#e34948")) +
  scale_y_continuous(
    name     = "Proportion of monthly total tweets",
    sec.axis = sec_axis(~ . / k1, name = "Sentiment departure")
  ) +
  scale_x_date(
    limits      = as.Date(c("2012-01-01", "2024-12-31")),
    date_breaks = "2 years",
    date_labels = "%Y",
    expand      = c(0, 0)
  ) +
  labs(x = NULL, fill = NULL, title = "(a) Tweets") +
  theme_minimal() +
  theme(
    legend.position   = "none",
    legend.text       = element_text(size = 10),
    legend.key.width  = unit(0.5, "cm"),
    legend.key.height = unit(0.25, "cm"),
    strip.text        = element_text(size = 10, face = "bold"),
    panel.grid.minor  = element_blank(),
    plot.title        = element_text(size = 14, face = "bold")
  )

p1



monthly_totals_art <- article_raw %>% filter(!is.na(topic)) %>%
  mutate(month = make_date(year, month, 1)) %>%
  count(month, name = "total")

article_time_month <- article_raw %>% filter(!is.na(topic)) %>%
  mutate(month = make_date(year, month, 1)) %>%
  filter(month >= as.Date("2012-01-01"), month <= as.Date("2024-12-01")) %>%
  group_by(topic) %>%
  mutate(topic_mean = mean(Raw_Sentiment_Score, na.rm = TRUE)) %>%
  group_by(topic, month) %>%
  summarise(
    n_topic  = n(),
    sent_dev = mean(Raw_Sentiment_Score, na.rm = TRUE) - first(topic_mean),
    .groups  = "drop"
  ) %>%
  complete(
    topic,
    month = seq(as.Date("2012-01-01"), as.Date("2024-12-01"), by = "month"),
    fill  = list(n_topic = 0)
  ) %>%
  left_join(monthly_totals_art, by = "month") %>%
  mutate(count = if_else(!is.na(total) & total > 0, n_topic / total, 0))

article_time_month <- article_time_month %>% as.data.frame() %>% mutate(topic = factor(topic, levels = c(1,2,3,4,5,6,7), labels = c("Renewable energy development",
                                                                                                                                    "Roads and habitat fragmentation",
                                                                                                                                    "Habitat use on military bases",
                                                                                                                                    "Emotional and personal connections to tortoises",
                                                                                                                                    "Public lands and protected landscapes",
                                                                                                                                    "Raven predation",
                                                                                                                                    "Science/research"
)))

# Scale factor so the largest sentiment deviation reaches ~half the max count
k2 <- 0.5 * max(article_time_month$count) / max(abs(article_time_month$sent_dev), na.rm = TRUE)

p2 <- ggplot(article_time_month, aes(x = month)) +
  geom_ribbon(aes(ymin = 0, ymax = pmax(sent_dev, 0) * k2, fill = "Above topic mean"),
              alpha = 0.6, na.rm = TRUE) +
  geom_ribbon(aes(ymin = pmin(sent_dev, 0) * k2, ymax = 0, fill = "Below topic mean"),
              alpha = 0.6, na.rm = TRUE) +
  geom_hline(yintercept = 0, linewidth = 0.3, color = "grey60") +
  geom_line(aes(y = count), linewidth = 0.5, show.legend = FALSE) +
  facet_wrap(~ topic, ncol = 2) +
  # scale_color_manual(values = pal_topic1) +
  scale_fill_manual(values = c("Above topic mean" = "#3987e5",
                               "Below topic mean" = "#e34948")) +
  scale_y_continuous(
    name     = "Proportion of monthly total articles",
    sec.axis = sec_axis(~ . / k2, name = "Sentiment departure")
  ) +
  scale_x_date(
    limits      = as.Date(c("2012-01-01", "2024-12-31")),
    date_breaks = "2 years",
    date_labels = "%Y",
    expand      = c(0, 0)
  ) +
  labs(x = NULL, fill = NULL, title = "(b) Articles") +
  theme_minimal() +
  theme(
    legend.position   = "none",
    legend.text       = element_text(size = 10),
    legend.key.width  = unit(0.5, "cm"),
    legend.key.height = unit(0.25, "cm"),
    strip.text        = element_text(size = 10, face = "bold"),
    panel.grid.minor  = element_blank(),
    plot.title        = element_text(size = 14, face = "bold")
  )

p2

p_all <- grid.arrange(p1,p2, nrow = 2, ncol = 1,heights = c(0.4,0.4))

ggsave("./figures/Topic_trends_sentiment.jpeg", p_all,
       width = 8, height = 9, units = "in", dpi = 600)


tweet_topic_sentiment <- tweet_raw %>% filter(!is.na(topic)) %>% group_by(topic) %>% summarise(mean_sent = mean(Raw_Sentiment_Score),
                                                                                               sd_sent = sd(Raw_Sentiment_Score))

article_topic_sentiment <- article_raw %>% filter(!is.na(topic)) %>% group_by(topic) %>% summarise(mean_sent = mean(Raw_Sentiment_Score),
                                                                                               sd_sent = sd(Raw_Sentiment_Score))