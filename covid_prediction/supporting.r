library(dplyr)
library(rvest)
library(stringr)

# Define the function to prepare the data
prep_data <- function(){
  # IN:  
  # OUT: data frame with day, day of the week, and the number of reported cases, and the log of these cases
  
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