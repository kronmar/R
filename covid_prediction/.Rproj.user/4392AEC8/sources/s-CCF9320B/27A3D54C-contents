library(dplyr)

# Define the function to prepare the data
prep_data <- function(){
  # IN:  the reported data found on opendata
  # OUT: data frame with day, day of the week, and the number of reported cases 
  
  url <- "https://www.covid19.admin.ch/api/data/20220321-5gqgzg7z/sources/COVID19Cases_geoRegion.csv"
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
  
  return(data)
}