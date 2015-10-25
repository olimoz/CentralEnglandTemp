shinyUI(pageWithSidebar(
  
  headerPanel(""),
  
  sidebarPanel(
              
              h1("Central England Temperature Record"),
              p("This temperature data begins in 1659 and is the longest instrumental record of temperature anywhere in the world. It is representative of an approximately triangular area of the United Kingdom enclosed by Lancashire, London and Bristol."),     
              p("Use this tool to explore trends in the data"),
              
              uiOutput("summariseby_column_output"),
              
              uiOutput("filterby_column_output"),
              
              uiOutput("filterby_value_output"),
              
              uiOutput("select_charttype_output"),
              
              br(),
              
              a(href = "https://gist.github.com/4211337", "Source code")
              ),
            
  
  mainPanel(
            plotOutput("ggplot_chart_output"),
            #,tableOutput("data_table_output")
            br(),
            p("REFERENCE"),
            p("Parker, D.E., T.P. Legg, and C.K. Folland. 1992. A new daily Central England Temperature Series, 1772-1991. Int. J. Clim., Vol 12, pp 317-342"),
            a(href = "http://www.metoffice.gov.uk/hadobs/hadcet/", "Source data")
           )
))