
library(Hmisc)
library(udunits2)
library(geosphere)
library(plyr)
library(dplyr)
library(ggplot2)
library(lubridate)
library(leaflet)

server <- function(input, output) { 
  
#Read data file
  inputData <- reactive ({
    
      #Read data
      dataset <- NULL
      
      if(file.exists("analyze_me.csv")){
        
        dataset <- read.csv("analyze_me.csv")

    }
      return(dataset)
    
  })
  
#Data pre-processing  
  updatedInputData <- reactive ({
    
    #Read data
    dataset <- inputData()
    
    if (is.null(dataset)) return(NULL)
    
    #Modifying timestamp format
    dataset$updatedTimestampFormat_when_the_delivery_started <- as.POSIXct(strptime(dataset$when_the_delivery_started,"%Y-%m-%d %H:%M:%S"),"America/New_York")
    dataset$updatedTimestampFormat_when_the_Jumpman_arrived_at_pickup <- as.POSIXct(strptime(dataset$when_the_Jumpman_arrived_at_pickup,"%Y-%m-%d %H:%M:%S"),"America/New_York")
    dataset$updatedTimestampFormat_when_the_Jumpman_left_pickup <- as.POSIXct(strptime(dataset$when_the_Jumpman_left_pickup,"%Y-%m-%d %H:%M:%S"),"America/New_York")
    dataset$updatedTimestampFormat_when_the_Jumpman_arrived_at_dropoff <- as.POSIXct(strptime(dataset$when_the_Jumpman_arrived_at_dropoff,"%Y-%m-%d %H:%M:%S"),"America/New_York")
    
    #Metric for preparation time - preparation_time
    dataset$preparation_time <- difftime(dataset$updatedTimestampFormat_when_the_Jumpman_left_pickup,dataset$updatedTimestampFormat_when_the_Jumpman_arrived_at_pickup,units="mins")
    
    #Metric for time taken to travel from pick up point to drop off - transport_time
    dataset$transport_time <- difftime(dataset$updatedTimestampFormat_when_the_Jumpman_arrived_at_dropoff,dataset$updatedTimestampFormat_when_the_Jumpman_left_pickup,units="mins")
    
    #Metric for total delivery - totalDelivery_time
    dataset$totalDelivery_time <- difftime(dataset$updatedTimestampFormat_when_the_Jumpman_arrived_at_dropoff,dataset$updatedTimestampFormat_when_the_delivery_started,units="mins")
    
    
    #Metric - distance
    dataset$distance <- distHaversine(cbind(dataset$dropoff_lat,dataset$dropoff_lon),cbind(dataset$pickup_lat,dataset$pickup_lon))
    
    #Convert the unit of the distance metric from meters to miles
    dataset$distance <- ud.convert(dataset$distance, "m","miles")
    
    #Metric for delivery speed - delivery_speed
    dataset$delivery_speed <- dataset$distance/as.numeric(dataset$transport_time)
    
    #Convert the delivery speed unit from miles/min to miles/hr
    dataset$delivery_speed <- ud.convert(dataset$delivery_speed, "miles/min","miles/hr")
    
    #Removing the repeated records & keep the first entry for each order
    updatedDataset <- distinct(dataset, delivery_id, .keep_all = TRUE)
    
    return(updatedDataset)
    
  })
  

  
  
  output$newCustomerPlot <- renderPlot({
    #load data
    dataset <- updatedInputData()
    
    newCustomerData<-dataset %>%
      group_by(customer_id) %>%
      dplyr::summarise(delivery_date = min(date(when_the_delivery_started)))
    
    ggplot(newCustomerData,aes(x=date(delivery_date),y=1))+
      stat_summary(fun.y=sum,colour="red",geom="line")+
      ggtitle("New customers acquired by day")+
      ylab("Customers")+
      xlab("Days")
  })
  
  
  
  
  
###########################################################################################################################################################  
  #Output plot - Delivery-partners wait time at merchants
  output$deliveryPartnerWaitTime <- renderHighchart({
    #load data
    dataset <- updatedInputData()
    
    tempData<-dataset %>%
      group_by(pickup_place) %>%
      dplyr::summarise(avgPreptime = mean(preparation_time,na.rm = TRUE))
    
    hchart(as.numeric(tempData$avgPreptime))%>% 
      hc_title(text = "Delivery-partners wait time at Merchants") %>% 
      hc_yAxis(title = list(text = "No of Merchants"))%>% 
      hc_xAxis(title = list(text = "Wait Time"))
    
  })   
  
  
  
   #Output plot - Preferred modes of transport
  output$transportMode <- renderHighchart({
    #load data
    dataset <- updatedInputData()
    
    tempData<-dataset %>%
      group_by(vehicle_type) %>%
      dplyr::summarise(nVehicles = n())
    
    highchart() %>% 
      hc_chart(type = "pie") %>% 
      hc_add_series_labels_values(labels = tempData$vehicle_type, values = tempData$nVehicles)
    
  })   
  
  
  
  #Output plot - Merchant distribution across New York
  output$merchantDistribution <- renderLeaflet({
    #load data
    dataset <- updatedInputData()
    
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addCircles(dataset$pickup_lon, dataset$pickup_lat,color = "Green") %>% 
      addMarkers(dataset$pickup_lon, dataset$pickup_lat,
                 clusterOptions = markerClusterOptions()
      ) 
    
  })   
  
  
  
#Output plot - Popular Place Categories
  output$popularCategories <- renderHighchart({
    #load data
    dataset <- updatedInputData()
    
    tempData<-dataset %>%
      group_by(place_category) %>%
      dplyr::summarise(nOrders = n())
    
    tempData<-tempData[-which(tempData$place_category==""),]
    
    dataForChart<-as.data.frame(head(arrange(tempData,desc(nOrders)), n = 10))
    
    
    hchart(dataForChart,type = "bar", hcaes(x = place_category, y = nOrders)) %>% 
      hc_title(text = "Popular Place Categories") %>% 
      hc_yAxis(title = list(text = "No of Orders"))%>% 
      hc_xAxis(title = list(text = "Categories"))
    
  })    

#Output plot - Popular Restaurants
  output$popularRestaurants <- renderHighchart({
    #load data
    dataset <- updatedInputData()
    
    tempData<-dataset %>%
      group_by(pickup_place) %>%
      dplyr::summarise(nOrders = n())
    
    dataForChart<-as.data.frame(head(arrange(tempData,desc(nOrders)), n = 10))
    
    
    hchart(dataForChart,type = "bar", hcaes(x = pickup_place, y = nOrders)) %>% 
      hc_title(text = "Popular Restaurants") %>% 
      hc_yAxis(title = list(text = "No of Orders"))%>% 
      hc_xAxis(title = list(text = "Restaurants"))
    
  })    
  
  
  
#Output plot - Customers distribution across New York
  output$customerDistribution <- renderLeaflet({
    #load data
    dataset <- updatedInputData()
    
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addCircles(dataset$dropoff_lon, dataset$dropoff_lat,color = "Green") %>% 
      addMarkers(dataset$dropoff_lon, dataset$dropoff_lat,
                 clusterOptions = markerClusterOptions()
      ) 
    
  })   
  
  
#Output plot - Customers Vs Orders    
  output$customerOrderPlot <- renderPlot({
    #load data
    dataset <- updatedInputData()
    
    customerData<-dataset %>%
      group_by(customer_id) %>%
      dplyr::summarise(nOrders = n())
    
    ggplot(data=customerData, aes(x=as.factor(nOrders), 1, group=1))  +
      stat_summary(fun.y = sum,colour = "red",geom = "line")+
      xlab("Orders") +
      ylab("Customers") +
      ggtitle("Customer orders frequency")
  }) 
    
    
#Output plot - New Customers Vs Day    
  output$newCustomerPlot <- renderPlot({
    #load data
    dataset <- updatedInputData()
    
    newCustomerData<-dataset %>%
      group_by(customer_id) %>%
      dplyr::summarise(delivery_date = min(date(when_the_delivery_started)))
    
    ggplot(newCustomerData,aes(x=date(delivery_date),y=1))+
      stat_summary(fun.y=sum,colour="red",geom="line")+
      ggtitle("New customers acquired by day")+
      ylab("Customers")+
      xlab("Days")
  })  
  
  
  #Output an order having multiple items
  output$timeStampData <- DT::renderDataTable({
    tempData<- updatedInputData()
    subsetData <- subset(tempData,vehicle_type == "bicycle" & delivery_speed > 25,select = c("vehicle_type","delivery_speed"))
  },options = list(
    pageLength=50, scrollX='400px'))  
  
    
#Output an order having multiple items
  output$repeatOrder <- DT::renderDataTable({
        tempData<- inputData()
        tempData[tempData$delivery_id == 1480991,]
  },options = list(
    pageLength=50, scrollX='400px'))

#Output head of modified dataset
  output$updatedDataset <- DT::renderDataTable({
    tempData<- updatedInputData()
    head(tempData)
  },options = list(
    pageLength=50, scrollX='400px'))
  
#Output summary statistics
  output$summary <- renderPrint({
    summary(inputData())
  })
  
  #End of server
  
  }