library(shiny)
library(ggplot2)
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
  if(tail(swiss_covid$entries, 1) < 0.1 * mean(tail(swiss_covid$entries, 7))){
    data <- head(data, -1)
  }
  
  return(data)
}

# Define UI for application
ui <- navbarPage("Laborbestätigte Covidfälle Schweiz und Liechtenstein",
  tabPanel("Übersicht",
    sidebarLayout(
      sidebarPanel(
        checkboxInput(
          "logOverview", label = "Logarithmische Skala", value = FALSE
        )
      ),
      mainPanel(
        plotOutput("overviewPlot")
      )
    )
  ),
  tabPanel("Wochentag",
   sidebarLayout(
     sidebarPanel(
       checkboxInput(
         "logWeekday", label = "Logarithmische Skala", value = FALSE
       ),
       radioButtons("weekday", "Wochentag",
         c("Montag"="Montag", "Dienstag"="Dienstag", "Mittwoch"="Mittwoch",
           "Donnerstag"="Donnerstag", "Freitag"="Freitag", "Samstag"="Samstag", "Sonntag"="Sonntag")
       )
     ),
     mainPanel(
       plotOutput("weekdayPlot")
     )
   )
  ),
  # tabPanel("Modelle",
  #  sidebarLayout(
  #    sidebarPanel(
  #      radioButtons("model", "Modell",
  #        c("KNN Regression"="knn"))
  #    ),
  #    mainPanel(
  #      plotOutput("weekdayPlot")
  #    )
  #  ),
  # ),
)



# Define server logic required to draw a histogram
server <- function(input, output) {
  # load data
  swiss_covid <- prep_data()
  
  output$overviewPlot <- renderPlot({
    overviewPlot <- swiss_covid %>%
      ggplot(aes(y = entries, x = datum, color = weekday)) +
      geom_point() +
      labs(title = "Alle Wochentage", x = "Datum", y = "Neuinfektionen") +
      theme_minimal()
      
    if(input$logOverview == TRUE){
      overviewPlot <- overviewPlot + scale_y_log10()
    }
    
    return(overviewPlot)
  })
  
  output$weekdayPlot <- renderPlot({
    weekdayPlot <- swiss_covid %>%
      filter(weekday == input$weekday) %>%
      ggplot(aes(y = entries, x = datum)) + 
      geom_point() +
      labs(title = "Nach Wochentag", x = "Datum", y = "Neuinfektionen") +
      theme_minimal()
    
    if(input$logWeekday == TRUE) {
      weekdayPlot <- weekdayPlot + scale_y_log10()
    }
    
    return(weekdayPlot)
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
