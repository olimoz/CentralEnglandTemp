
library(reshape)
library(dplyr)
library(lazyeval)
library(ggplot2)

url1<-"http://www.metoffice.gov.uk/hadobs/hadcet/cetml1659on.dat"
download.file(url1, destfile="./CET_MonthlyMean_1659.dat")
CET_MonthlyMean_1659 <- read.csv("CET_MonthlyMean_1659.dat", sep="", header=F, skip=7)

##Get the data into a shape which can be easily used for charting
CET_MonthlyMean_1659 <- CET_MonthlyMean_1659[1:(nrow(CET_MonthlyMean_1659)-1),1:14]
colnames(CET_MonthlyMean_1659)<-c("Year","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec","AnnualAvg")
CET_MonthlyMean_1659 <- melt(CET_MonthlyMean_1659[,1:13], id=c("Year"), variable_name = "Month")
CET_MonthlyMean_1659 <- arrange(CET_MonthlyMean_1659, Year, Month)

##Add seasonal flags and Month numbers
monthseason<-as.data.frame(
  cbind(
    c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"),
    c(1,2,3,4,5,6,7,8,9,10,11,12),
    c(1,1,1,2,2,2,3,3,3,4,4,4),
    c(rep("Winter",3),rep("Spring",3),rep("Summer",3),rep("Autumn",3))
  )
)
colnames(monthseason)<-c("MonthName","MonthNum","SeasonNum","SeasonName")
CET_MonthlyMean_1659$Season   <-monthseason[CET_MonthlyMean_1659$Month,3]
CET_MonthlyMean_1659$MonthNum <-monthseason[CET_MonthlyMean_1659$Month,2]

##Add Decadal Flags
CET_MonthlyMean_1659$Decade <-as.numeric(paste0(substr(CET_MonthlyMean_1659$Year,1,3),"0"))

##Add Century Flags
CET_MonthlyMean_1659$Century<-as.numeric(paste0(substr(CET_MonthlyMean_1659$Year,1,2),"00"))

##Create list of seasons and their respective number for use later...
seasonnumbers<-as.data.frame(cbind(c(1,2,3,4),c("Winter","Spring","Summer","Autumn")))
colnames(seasonnumbers)<-c("Number","Name")

##Create column options
grpcolumn_options<-c("Year", "Decade", "Century")
filcolumn_options<-c("No Filter", "Month", "Season","Decade", "Century")

##Need some chart smoothers and 
smoother_options<-c("loess","glm","lm")
smoother_value  <-"loess"

##Now, let's Shine!
shinyServer(function(input, output) {
  
  # Drop-down selection box for which data set
  output$summariseby_column_output  <- renderUI({
                                      selectInput("summariseby_column_input", "Summarise By", as.list(grpcolumn_options))
                                    })
  
  # Check boxes
  output$filterby_column_output <- renderUI({
                                    # Create the dropdown
                                    selectInput("filterby_column_input", "Filter By", as.list(filcolumn_options), selected = )
                                   })

  output$filterby_value_output <- renderUI({
                                    # If missing input, return to avoid error later in function
                                    if(is.null(input$filterby_column_input))
                                      return()
                                    
                                    # Prepare the valid choices given the 'groupby' choice
                                    
                                    if(input$filterby_column_input=="No Filter"){
                                      filterby_options<-"No Filter"
                                      filterby_values <-0
                                    }
                                    if(input$filterby_column_input=="Month"){
                                      filterby_options<-as.character(unique(monthseason$MonthName))
                                      filterby_values <-as.numeric(unique(monthseason$MonthNum))
                                    }
                                    if(input$filterby_column_input=="Season"){
                                      filterby_options<-as.character(unique(monthseason$SeasonName))
                                      filterby_values <-as.numeric(unique(monthseason$SeasonNum))
                                    }
                                    if(input$filterby_column_input=="Year"){
                                      filterby_options<-as.numeric(unique(CET_MonthlyMean_1659$Year))
                                      filterby_values <-filterby_options
                                    }
                                    if(input$filterby_column_input=="Decade"){
                                      filterby_options<-as.numeric(unique(CET_MonthlyMean_1659$Decade))
                                      filterby_values <-filterby_options
                                    }
                                    if(input$filterby_column_input=="Century"){
                                      filterby_options<-as.numeric(unique(CET_MonthlyMean_1659$Century))
                                      filterby_values <-filterby_options
                                    }
                                     # Create the dropdown
                                    selectInput("filterby_value_input", "Filter value", as.list(filterby_options))

                                  })
  
  output$select_charttype_output<-renderUI({
                                  radioButtons(inputId = "charttype_input", 
                                               label =   "Analysis:",
                                               choices = c("Loess Smooth"="Trend", "Significant Changepoints (95% conf.)"="Changepoint"),
                                               selected = "Trend"
                                               )
                                  })
  

  output$ggplot_chart_output <- renderPlot({

                                      if(   is.null(input$summariseby_column_input) 
                                            || is.null(input$filterby_column_input)
                                            || is.null(input$filterby_value_input)
                                      )return()
    
                                      #Get the data set
                                      groupby_column_  <- input$summariseby_column_input
                                      filterby_column_ <- input$filterby_column_input
                                      filterby_value_  <- input$filterby_value_input
                                      
                                      #If user selected a season name, then we translate that to a number.
                                      if (filterby_column_ =="Season"){
                                        filterby_value_<-as.numeric(seasonnumbers[seasonnumbers$Name==as.name(filterby_value_),1])
                                      }
                                      
                                      if(filterby_column_=="No Filter" || filterby_value_=="No Filter"){
                                        filterby_column_<-NULL
                                        filterby_value_<-NULL
                                        }
                                      
                                      ##This is the cool bit, a generalised query builder.
                                      if(!is.null(filterby_column_)&&!is.null(filterby_value_)){
                                        criteria <- interp(~ y == x, y = as.name(filterby_column_), x = filterby_value_)
                                        dat_filtered <- filter_(CET_MonthlyMean_1659, criteria)
                                      }else{
                                        dat_filtered <- CET_MonthlyMean_1659
                                      }
                                      
                                      if(!is.null(groupby_column_)){
                                        dat_filtered_grouped <- group_by_(dat_filtered, as.name(groupby_column_))
                                      }else{
                                        dat_filtered_grouped <- dat_filtered
                                      }
                                      
                                      ##Now summarise
                                      chartdat <- as.data.frame(summarise(dat_filtered_grouped, Temp=mean(value)))
                                      names(chartdat)[1]<-"x"
                                      names(chartdat)[2]<-"y"
                                      
                                      #Handle event for there being only one record in the chosen dataset
                                      validate(need(nrow(chartdat)>1, 
                                                    "Only one record results, cannot plot a chart. Please change selections."
                                                    )
                                              )
                                               
                                      
                                      #Handle event for there being insufficient points for changepoint analysis
                                      if(input$charttype_input=="Changepoint" && nrow(chartdat)<=10){
                                        CannotDoChangepoint<-1
                                      }else{
                                        CannotDoChangepoint<-0
                                      }
                                      
                                      validate(need(CannotDoChangepoint==0,
                                                    "Insufficient number of data points for changepoint analysis. Please change selection"
                                                    )
                                              )

                                      
                                      if(input$charttype_input=="Trend"){
                                        
                                        #Loess Trend plot
                                        g <-  ggplot(chartdat, aes(x, y))+
                                              geom_line()+
                                              geom_smooth(method = as.name(smoother_value), size=1.2)+
                                              xlab("Year")+
                                              ylab("Mean Temp, deg.C")+
                                              ggtitle("Central England Temperature, with Loess Smooth")
                                        
                                        print(g)
                                        
                                      }else{
                                       
                                        #Changepoint plot
                                        library(changepoint)
                                        
                                        ##Data wrangling to get changepoints into format for display on GGPLOT
                                        changes <- cpt.mean(chartdat$y, method="BinSeg", Q=5)
                                        changes_origrows <- cbind(chartdat[changes@cpts,1],changes@param.est$mean)
                                        changes_missingrows<- cbind(chartdat[1,1],changes@param.est$mean[1])
                                        
                                        loopcount<-nrow(changes_origrows)
                                        i<-1
                                        if(loopcount>1){
                                          for(i in 2:loopcount){
                                            changes_missingrows<-rbind(changes_missingrows,c(changes_origrows[i-1,1],changes_origrows[i,2]))
                                          }
                                        }
                                        
                                        changes_line     <- as.data.frame(rbind(changes_origrows,changes_missingrows))
                                        colnames(changes_line)<-c("x","y")
                                        changes_line<-arrange(changes_line,x)
                                        
                                        g <-  ggplot(chartdat, aes(x, y))+
                                              geom_line()+
                                              xlab("Year")+
                                              ylab("Temp, deg.C")+
                                              ggtitle("Central England Temperature with Significant Changepoints")+
                                              geom_line(data = changes_line, aes(x, y, colour="red"), size=1.2, show_guide = FALSE)
                                       
                                        print(g)

                                      }
                                      
                                    })
  
})