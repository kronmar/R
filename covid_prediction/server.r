library(ggplot2)

# load the necessary functions
source("supporting.r")

# Define server logic required to draw a histogram
server <- function(input, output) {
  # load data
  swiss_covid <- load_data()
  # and prepare for later
  swiss_covid_prepared <- prep_data(swiss_covid, numFolds = 10)
  # calculate the optimumSpan for the LOESS modell
  optSpan <- tune_span(swiss_covid_prepared, numFolds = 10, minDaysSpan = 5, maxDaysSpan = 30)
  
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
      labs(title = "Nach Wochentag", x = "Datum", y = "log(Neuinfektionen)") +
      theme_minimal()
    
    if(input$logWeekday == TRUE) {
      weekdayPlot <- weekdayPlot + scale_y_log10()
    }
    
    return(weekdayPlot)
  })
  
  output$loessPlot <- renderPlot({
    # 
    # calculate a new loess modell with the optimum span found previously
    loessMod <- loess(deseasoned ~ index, data = head(swiss_covid, nrow(swiss_covid)-1), span = optSpan/nrow(swiss_covid), 
                      control = loess.control(surface = "direct"))
    
    # predict the value for the following day
    predLogValue <- predict(loessMod, nrow(data)+1)
    predValue <- seasonalize(predLogValue, date = tail(swiss_covid$datum)+1, data=swiss_covid)
    # plot
    loessPlot <- data.frame(datum = swiss_covid$datum, obs = swiss_covid$deseasoned, mod = predict(loessMod, 1:nrow(swiss_covid))) %>%
      filter(datum >= "2022-01-01") %>%
      ggplot() +
      geom_line(aes(x = datum, y = mod)) +
      geom_point(aes(x = datum, y = obs)) +
      labs(title = "LOESS Modell", subtitle = paste("Span = ", optSpan, " Tage. Morgen: ", round(predValue)), 
           x = "Datum", y = "log(Neuinfektionen) - deseasoned")
    
    return(loessPlot)
  })
}