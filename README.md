# Assessing online sentiment towards the Mojave desert tortoise using Natural Language Processing
### Authors: Madeline P. Standen, L. Mae Lacey, Alexander J. Robillard, Amy C. Collins, Kaitlyn Shaw, James Danoff-Burg, Elissa Olimpi, Justin Suraci, Brett G. Dickson
An [National Fish and Wildlife Foundation](https://www.nfwf.org/) project in collaboration with the [Conservation Science Partners](https://www.csp-inc.org/) [T&E Lab](https://csp-inc.org/t-e-lab/) and the [Living Desert Zoo and Gardens](https://www.livingdesert.org/) using natural language processing ("NLP") for analysis of content posted on Twitter/X and online news articles related to the Mojave desert tortoise (</i>Gopherus agassizii</i>).

## 🐢x🐦: Repository Structure <a name="repo"></a>
```bash
├── GDELT-article-extraction # Article extraction workflows
├── Tweet-extraction  # Tweet scraping 
├── Weekly_aggregated_data.csv # Dataset representing metrics of sentiment, engagement, and activity aggregated to the weekly level
├── Article_data.csv # Article dataset, text and identifying information removed
├── Tweet_data.csv # Tweet dataset, text and identifying information removed
├── Preprocessing-and-analyses  # Data preprocessing, analyses, and figures
├── .gitignore
└── README.md
```

## :information_source: About this Project <a name="about"></a>
Public attitudes towards a species can determine a community’s willingness to support conservation management actions. User-generated, open-source content represents a rich resource for studying public perceptions of and engagement with conservation topics, and can provide actionable insights for designing outreach efforts. Here we analyze social media posts on Twitter/X (hereafter ‘Twitter’) and news articles published from 2012-2024 related to the Mojave desert tortoise (</i>Gopherus agassizii</i>, hereafter ‘tortoise’). We quantified the sentiment and volume of, and engagement with, online content, and identified salient topics of discussion and key events impacting online discourse. This work represents a practical framework for using NLP to develop metrics to measure public perception.

## Data Availability
Due to restrictions on sharing Twitter/X data, and to protect user privacy, following the guidelines of Di Minin et al. (2021), we do not share the full Twitter or Article datasets. We provide "anonymized" versions with the tweet/article text and other identifying information removed. All statistical analyses can be conducted using these datasets. 

## :computer: Analysis
### Step 1: Compile relevant social media posts
We successfully collected Twitter/X (hereafter ‘Twitter’) data using the Twitter API (Roesslein 2020). Our process involved authenticating with the Twitter API and systematically retrieving tweets based on predefined keywords with dates ranging from January 2012 to August 2024. At a minimum, data included tweet text, unique user id, and date. Search queries excluded retweets and non-English tweets. Specific keywords used were “Mojave desert tortoise”, “Gopherus agassizii”, “desert tortoise”, and related variations. We initially pulled 24,380 tweets. Following data filtering and cleaning, our final dataset included 19,192 tweets. 

### Step 2: Compile relevant news articles
To gather news media data we leveraged the Global Database of Events, Language, and Tone (GDELT) library (GDELT Project, 2026), which allowed us to scrape all web sources in the GDELT database for article links relevant to the Mojave desert tortoise. If a URL provided by GDELT did not return any information (i.e., the link was broken), we queried the Wayback Machine API (archive.org) for an archived snapshot of that article. We collected the full text of articles posted from 2013 (the year in which daily article data became available from GDELT) through 2024. Specific keywords used for querying articles were “Mojave desert tortoise”, “Gopherus agassizii”, “desert tortoise”, “tortoise”, “Mojave”, “desert”, and related variations. We initially accessed 90,921 articles. Following data filtering and cleaning, our final dataset included 956 articles.

### Step 3: Perform sentiment analysis
To analyze the sentiment of tweets and news articles, we employed the sentiment analysis model Valence Aware Dictionary and sEntiment Reasoner (VADER; Hutto & Gilbert, 2014). VADER is a lexicon (i.e., a dictionary of words with assigned sentiment scores) and rule-based sentiment analysis tool that was selected for its effectiveness in analyzing social media content (Fink et al., 2020; Hutto & Gilbert, 2014). In the VADER lexicon, which consists of 6,338 English words, ASCII emoticons, initialisms, and slang phrases, entries are associated with valence scores for sentiment intensity ranging from -4 to +4. VADER also provides “context-awareness” to its lexicon by considering valence shifters (e.g., “not” in the phrase “not good”), punctuation, capitalization, and degree modifiers (e.g., “very”). Analysis of a body of text using VADER provides a normalized compound score that reflects the overall sentiment of the text and ranges from -1 to 1. Scores ranging from -0.05 to 0.05 are considered neutral, while scores above 0.05 or below -0.05 are considered ‘positive’ or ‘negative’, respectively. To better understand how sentiment relates to stance and attitude in this dataset, we conducted a qualitative content analysis on a subset of 50 tweets (0.2% of the full Twitter dataset) which contained high frequency terms. Two authors processed tweets independently based on metrics of ‘stance’ (1 = pro-tortoise, 0 = neutral/ambiguous, -1 = anti-tortoise) and ‘attitude’ (1 = optimistic, 0 = neutral/ambiguous, -1 = pessimistic). 

### Step 4: Perform topic modeling
We used Latent Derelict Allocation (LDA, Blei et al. 2003) modeling to identify which narratives about the tortoise were most salient across online discourse. LDA models use mixtures of words present in a body of texts to identify distinct topics and assign a topic to each text. We created separate LDA models for articles and tweets, and used these models to assign each article and tweet to one of seven platform-specific topics. 

### Step 5: Quantify baseline sentiment and temporal trends in sentiment, engagement, and activity
To quantify the baseline sentiment of Twitter posts and news articles regarding the tortoise, we used a pairwise chi-square test to compare the number of tweets and articles in each sentiment category (positive, neutral, negative). Mann-Kendall trend tests were conducted to assess the presence of weekly trends in sentiment, engagement, and activity across Twitter and news outlets from 2012–2024. To examine trends of online content within salient topics, we visualized monthly trends in proportional contribution and deviation from mean sentiment by topic, for both tweets and news articles. Finally, to identify key events impacting online discourse through time, we identified weeks that were outliers for sentiment, engagement, or activity and examined content of tweets and articles posted in those weeks.


## References
Blei, D. M., Ng, A. Y., & Jordan, M. I. (2003). Latent dirichlet allocation. Journal of machine Learning research, 3(Jan), 993-1022.

Di Minin, E., Fink, C., Hausmann, A., Kremer, J., & Kulkarni, R. (2021). How to address data privacy concerns when using social media data in conservation science. Conservation Biology, 35(2), 437-446.

Fink, C., Hausmann, A., & Di Minin, E. (2020). Online sentiment towards iconic species. Biological Conservation, 241, 108289.

GDELT Project. (2026). Global Database of Events, Language, and Tone (GDELT). https://www.gdeltproject.org/.

Hutto, C., & Gilbert, E. (2014, May). Vader: A parsimonious rule-based model for sentiment analysis of social media text. In Proceedings of the international AAAI conference on web and social media (Vol. 8, No. 1, pp. 216-225).

Roesslein, J. (2009). Tweepy. An easy-to-use Python library for accessing the Twitter API. Github repository. https://github.com/tweepy/tweepy.
