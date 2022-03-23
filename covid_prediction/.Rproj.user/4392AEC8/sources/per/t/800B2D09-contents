library(ggplot2)

# load the necessary functions
source("supporting.r")

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