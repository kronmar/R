library(shiny)
library(dplyr)

# load the necessary files
source("supporting.r")
source("ui.r")
source("server.r")

# Run the application 
shinyApp(ui = ui, server = server)
