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
   tabPanel("Loess Modell",
    sidebarLayout(
     sidebarPanel(
      sliderInput("loessSpan", "Span für Loess Modell (in Anzahl Tagen)", min = 3, max = 60, value = 30),
      ),
     mainPanel(
        plotOutput("loessPlot")
      )
    ),
   ),
)
