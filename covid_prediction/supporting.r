library(dplyr)
library(rvest)
library(stringr)

# Define the function to prepare the data
load_data <- function(){
  # IN:  
  # OUT: data frame with day, day of the week, and the number of reported cases, the log of these cases,
  #      deseasoned values, and the index
  
  url <- get_url()
  data <- url %>%
    read.csv %>%
    # Filter by geoRegion, interested in the total including the Principality of Liechtenstein
    filter(geoRegion == "CHFL") %>%
    # select the desired columns
    select(datum, entries)
  
  # convert datum to a proper datetimeobject
  data$datum <- as.Date(data$datum)
  
  # add the weekday
  data$weekday <- weekdays(data$datum)
  
  # the data is updated multiple times a day, and sometimes incomplete data is added
  # as a quick band-aid fix for this, I remove the last entry if it's "too small"
  if(tail(data$entries, 1) < 0.1 * mean(tail(data$entries, 7))){
    data <- head(data, -1)
  }
  
  # add log data
  data$logEntries <- log(data$entries)
  
  # add deseasonize
  # first define, the total mean
  totMean <- mean(data$logEntries)
  # calculate and add
  # WIP: THINK OF BETTER SOLUTION!
  data$deseasoned <- data %>% 
    # create a tibble
    group_by(weekday) %>%
    mutate(deseasoned = logEntries - mean(logEntries) + totMean) %>%
    # to simplify matters, pull the entry created and convert to a vector to add it to the data frame
    pull(deseasoned)
  # add index
  data$index <- 1:nrow(data)
  
  return(data)
}

# Define the function to fetch the url from opendata
get_url <- function(){
  # IN:
  # OUT: the newest, up-do-date url found on opendata to the case numbers
  
  # base url, where the download url is found
  base_url <- "https://opendata.swiss/de/dataset/covid-19-schweiz/resource/d2aa549d-492b-452c-aab3-7c1ced16a98d"
  
  url <- base_url %>%
    # read the base_url
    read_html() %>%
    # identify the appropriate class and read the corresponding text
    html_node(".container.additional-info") %>%
    html_text() %>%
    # find the (first) spot where the url is listed
    str_match("https://www.covid19.admin.ch/api/data/(.*?)/sources/COVID19Cases_geoRegion.csv")
  
  # return the complete match
  return(url[1])
}

# prepare data for cv
prep_data <- function(data, numFolds = 5){
  # IN:  the dataframe data which should be prepared, and the number of folds (default 5)
  # OUT: shuffled dataframe, adds a column for the the split in cv

  # shuffle
  shuffle <- sample(x = 1:nrow(data), size = nrow(data), replace = F)
  shuffledData <- data[shuffle,] 
  
  # setup for cv
  shuffledData$fold <- cut(seq(1, nrow(data)), breaks = numFolds, labels = F)
  
  return(shuffledData)
}

# performe parameter tuning for span
tune_span <- function(data, numFolds = 5, minDaysSpan = 5, maxDaysSpan = 30){
  # IN:  the dataframe data (containing deseasoned values to fit, index and foldnumber), the number of Folds numFolds, 
  #      the minimum days in the span minDaysSpan as well as the maximum,
  #      
  
  # prepare for the loop
  rmseList <- c()
  spanList <- seq(minDaysSpan, maxDaysSpan, 1)
  
  # cv
  for(i in  1:numFolds){
    train_fold <- data %>%
      filter(fold != i)
    
    test_fold <- data %>%
      filter(fold == i)
    
    for(span in spanList){
      # fit model
      loessMod <- loess(deseasoned ~ index, data = train_fold, span = span/nrow(data), 
                        control = loess.control(surface = "direct"))
      
      # predict on test_fold
      pred <- unname(predict(loessMod, test_fold))
      
      # calculate RMSE and save
      rmseList <- append(rmseList, sqrt(mean((pred-test_fold$deseasoned)^2)))
    }
  }
  # define result df
  resultDf <- data.frame(fold = rep(1:5, each = length(spanList)), span = rep(spanList, 5), rmse = rmseList)
  
  # calculate mean per span
  meanDf <- resultDf %>% group_by(span) %>% summarise_at(vars(rmse), list(mean))
  
  # and find the span of the minimum and return it
  return(meanDf$span[which.min(meanDf$rmse)])
}

# transforms the predicted value back and adds the seasonal (i.e. weekday dependent) offset
seasonalize <- function(predValue, date, data){
  # calculate the mean for the asked for date
  dailyMean <- data %>% filter(weekday == weekdays(date)) %>%
    select(deseasoned) %>%
    pull() %>%
    mean()
  
  # calculate the total mean
  totMean <- data %>%
    select(deseasoned) %>%
    pull() %>%
    mean()
  
  return(exp(predValue - totMean + dailyMean))
}