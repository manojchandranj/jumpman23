
# Load packages
if (!require(shinydashboard)) 
  install.packages('shinydashboard')

library(shiny)
library(shinydashboard)
library(DT)
library(leaflet)
library(highcharter)
########################################################################################################

ui <- dashboardPage(skin = "purple",

      #Dashboard header
      dashboardHeader(titleWidth = 350, title ="New York Market Analysis"),
  
      #Dashboard Sidebar
      dashboardSidebar(
        
          width = 350,
          sidebarMenu(
            menuItem("Overview", tabName = "dashboard"),
            menuItem("Data Integrity Issues",tabName = "dataIntegrity"),
            menuItem("Data Pre-Processing",tabName = "dataPreprocessing"),
            menuItem("Deep Dive Analysis",tabName = "analysis"),
            menuItem("Insights And Recommended Next Steps",tabName = "final"),
            menuItem("Here's the link to code on github",HTML('<a href="https://github.com/manojchandranj/jumpman23">Jumpman23 - New York Market Analysis!</a>'))
          )
      ),
  
    #Dashboard Body
    dashboardBody(
      
        tags$head( 
          #Style for sidebar and tab content
          tags$style(HTML(".main-sidebar { font-size: 18px; }",".nav-tabs {font-size: 25px}"),
                     HTML(".tab-content {
                                        height: 100%;
                                       font-size:18px;
                                       line-height: 35px;
                                       font-family: Arial, Helvetica, sans-serif;
                                          }")) 
        ),
      
        tabItems(
########################################################################################################################################################################################################        
        #Content for Overview tab
        tabItem(tabName = "dashboard",
                HTML('<h1>Background</h1>
                     <p>Jumpman23 is an on-demand delivery platform connecting “Jumpmen” and customers purchasing a variety of goods. Jumpman23 will send Jumpmen to merchants to purchase and
                     pickup any items requested by the customer. Whenever possible, Jumpman23 will order the
                     requested items ahead to save the Jumpmen time. Each time a Jumpman23 delivery is
                     completed, a record is saved to the Jumpman23 database that contains information about that
                     delivery. Jumpman23 is growing fast and has just launched in its newest market -- New York
                     City.</p>
                     <p></p> '),
                br(),
                HTML('<h1>Goals</h1>
                      <ul><li>If there are data integrity issues in the dataset, figure out how they would impact the analysis.</li>
                     <li>Analyze the performance of Jumpman23 newest market - New York city.</li></ul>'),
                br() 
            
        ),
########################################################################################################################################################################################################
        #Content for data integrity issue tab
        tabItem(tabName = "dataIntegrity",
                  HTML('<h1>Data Integrity Issues</h1>
                     <p>Doing exploratory data analysis on the dataset revealed that there are data integrity issues. Here are the issues with the dataset:</p>
                       <ul>
                       <li>Missing values in dataset</li>
                       <li>Repetition of data for the same order</li>
                       <li>Timestamp</li></ul>
                       <p></p> '),
                  br(),
                tabsetPanel(type="tab",
                  tabPanel("Missing values in dataset",
                      HTML('
                       <br> <p>There are several missing values found in the dataset. Missing data should be minimized as much as possible in an ideal data collection system.<br />When a new user comes in and searches for a specific item, we can query those database in real time and provide the user with the list of similar items like users who bought this item also bought.
But 20% of the data is missing from item_name and item_category_name, this would skew the results of recommendation engine.</p>
                        <br>
                       <p>From the below data summary, we can see that missing values are found in the following columns -</p>
                       <ol>
                       <li>when_the_Jumpman_left_pickup   -     550</li>
                       <li>when_the_Jumpman_arrived_at_pickup -  550</li>
                       <li>how_long_it_took_to_order    -      2945</li>
                       <li>place_category                -      883</li>
                       <li>item_name                      -    1230</li>
                       <li>item_category_name              -   1230</li>
                       <li>item_quantity                    -  1230</li></ol>'),
                #tabPanel("Summary", verbatimTextOutput("summary")),
                
                box(title = "Data Summary", 
                    status = "info", 
                    solidHeader = FALSE, 
                    collapsible = TRUE,
                    collapsed = TRUE,
                    width = NULL,
                    tabPanel("Summary", verbatimTextOutput("summary"))
                )),
                tabPanel("Repetition of data for the same order",
                         HTML('
                       <br> <p>In the dataset, we can see that if a customer has ordered multiple items then separate records have been created for each item. And because of this each column has duplicate values.
From the delivery_id column, it has been found out that almost 12% (except the item_name column) of the records have been repeated.
                              For deep dive analysis repeated records have been removed from the dataset.</p>
                        <br>
                       <p>The below example shows an order having multiple items creates multiple records in the dataset -</p>
                       '),
                         DT::dataTableOutput("repeatOrder")
                        ),
                tabPanel("Timestamp",
                         HTML('
                              <br> <p>Some of the data for timestamp variables are incorrect. The average delivery speed was calculated for all the records in the dataset and for some of the records the speed was more than 40mph on bicycles.  </p>
                              <br>
                              <p>The below example shows some of the orders in the dataset having abnormal delivery speed -</p>
                              '),DT::dataTableOutput("timeStampData")
                         )
                
                ),
                  br() 
                  
                 ),
########################################################################################################################################################################################################        
        #Content for data pre-processing tab
        tabItem(tabName = "dataPreprocessing",
                           HTML('<h1>Data Pre-Processing</h1>
                     <p>For analysis purposes timestamp format has been modified for the below listed columns and new updated columns have been created.</p>
                       <ul><li>when_the_delivery_started</li>
                       <li>when_the_Jumpman_arrived_at_pickup</li>
                        <li>when_the_Jumpman_left_pickup</li>
                       <li>when_the_Jumpman_arrived_at_dropoff</li></ul><p></p> '),
                           br(),
                           
                           HTML('<p>And the following metrics have been created and added to the dataset to gain more insight.</p>
                       <ul><li>Preparation time : when_the_Jumpman_left_pickup - when_the_Jumpman_arrived_at_pickup</li>
                       <li>Transport time : when_the_Jumpman_arrived_at_dropoff - when_the_Jumpman_left_pickup</li>
                       <li>Total delivery time : when_the_Jumpman_arrived_at_dropoff - when_the_delivery_started</li>
                      <li>Distance : Distance between pick up location and drop off location</li>
                      <li>Delivery speed : Distance / Transport Time</li></ul>
                      <br/>
                      <p>Orders with multiple items have records for each item in the dataset and this creates duplicate values in most of the columns.Dataset have been modified to have only the first entry for an order having multiple items.</p>
                      <br/>
                       <p>Here is how the modified dataset looks like</p>'),
                        DT::dataTableOutput("updatedDataset"),
                           br() 
                           
                 ),
########################################################################################################################################################################################################        
        #Content for deep dive analysis tab
        tabItem(tabName = "analysis",
                           HTML('<h1>Deep Dive Analysis</h1>
                                 <p>All sides of the marketplace are equally important to ensure a seamless Jumpman23 experience.<br/>If there are not enough customers placing orders, merchants will not want to participate. 
                                <br/>If there are not enough merchants, the selection decreases and fewer customers will want to order from the platform. 
                                <br/>If orders decreased, delivery-partners will not be incentivized to sign up since they might make less income. 
                                <br/>With too few delivery-partners, delivery times could increase for customers and this will affect the overall experience.</p>
                                 '),
                           br(),
                           
                           HTML(''),
                           br(),
                           tabsetPanel(type="tab",
                           tabPanel("Customer Analysis", 
                            
                            HTML('<h1>Customer Acquisition</h1>
                            <p>Gaining new customers will help in growth of the business. Analysis of customer behavior, customer loyalty programs and customer referrals will help in acquiring new customers.</p>
                            <br>
                            <p>From the chart below we can see that new customers acquired decreases by day.</p> '),
                                    plotOutput("newCustomerPlot"),
                                    
                           
                            HTML('<h1>Customer Retention</h1>
                            <p>Best customers don’t just use the service only once. They come back again and again for more. Customer retention increases customers lifetime value and boosts revenue.</p>
                            <br>
                            <p>From the chart below we can see that only 30% of customers have ordered twice or more.</p> '),
                                    plotOutput("customerOrderPlot"),
                            
                            
                            HTML('<h1>Customer Distribution across New York</h1>
                            <p>Best customers don’t just use the service only once. They come back again and again for more. Customer retention increases customers lifetime value and boosts revenue.</p>
                            <br>
                            <p>From the chart below we can see that only 30% of customers have ordered twice or more.</p> '),
                            leafletOutput("customerDistribution")),
                           
                           
                           
                           tabPanel("Delivery-Partners Analysis", 
                           HTML('<h1>Modes of Transport</h1>
                            <p>From the below chart we can see that hte bicycles and cars are preferred modes of transportation. They seems to cover almost 90% of the deliveries.</p>
                                                                       <br>
                                                                       <p></p> '),
                                    highchartOutput("transportMode"), 

                            HTML('<h1>Delivery-partners wait time at merchants</h1>
                            <p>Earnings are typically the main incentive that motivates delivery-partners, and  
                              the number of deliveries they can make while they are online, plays a huge part in how much they can earn.
                              So, accurately predicting the time when the item will be ready decreases the delivery-partners wait time at each 
                              merchant.</p>
                              <br>
                              <p>From the below histogram we can see that the delivery-partners had to wait for more than 25 minutes at some merchants and this should be optimized for efficiency</p> '),
                                    highchartOutput("deliveryPartnerWaitTime")),
                           
                           
                           
                           
                           
                           
                           
                           tabPanel("Merchant Analysis", 
                            HTML('<h1>Customer Experience</h1>
                            <p>From the dataset, customers favorite places and items could be figured out by looking at the number of orders placed at a merchant partner 
                                and most frequently ordered items. By doing this we can reduce the order congestion with the merchant by letting them 
                                know about the rise and fall of market demand-supply.</p>
                            <br>
                            <p>The below chart shows the popular merchants ranked by order volume</p> '),
                                    highchartOutput("popularRestaurants"), 
                            
                            
                            HTML('<h1>Customer Retention</h1>
                                 <p>By looking at the popularity of different categories of items, we could recommend relevant merchants and diverse types of items to customers.
                                      So, by ranking merchant-partners and items by relevance and diversity increases the likelihood of customers ordering from the platform.</p>
                                 <br>
                                 <p>The below chart shows the popular categories of items ranked by order volume</p> '),
                            highchartOutput("popularCategories"),
                            
                            
                            HTML('<h1>Merchant-partners distribution across New York</h1>
                                 <p>Best customers don’t just use the service only once. They come back again and again for more. Customer retention increases customers lifetime value and boosts revenue.</p>
                                 <br>
                                 <p>From the chart below we can see that only 30% of customers have ordered twice or more.</p> '),
                            leafletOutput("merchantDistribution")))
                           
                 ),
########################################################################################################################################################################################################        
        #Content for insights and final steps tab
        tabItem(tabName = "final",
                           HTML('<h1>Insights And Recommended Next Steps</h1>
                                 <h2>Current Scenario</h2>
                                
                                <ul><li>Data Integrity
                                    <ul><li>There seems to be lots of missing values,repetition of same orders and incorrect timestamps.</li></ul>
                                    </li>
                                <li>Customer
                                <ul><li>Even though the rate at which the customers acquired is decreasing the New York city market is growing.</li>
                                <li>Only 30% of customers have ordered twice or more using the platform.</li></ul>
                                </li>
                                <li>Delivery-Partner
                                <ul><li>Bicycles and Cars seems to be the preferred modes of transportation and they cover almost 90% of deliveries.</li>
                                <li>The average delivery-Partners wait time at merchants is around 20 minutes. But at some merchants the wait time is more than 50min.</li></ul>
                                </li>
                                <li>Merchant
                                <ul><li>"Shake Shack" is the popular merchant.</li>
                                <li>"Italian" is the most popular place category.</li></ul>
                                </li>
                                
                                </ul>'),
                           br(),
                           
                           HTML('<h2>Next Steps</h2>
                                <ul><li>Data Integrity
                                    <ul><li>Diagnose and fix the data collection in the database and make sure the right data is being gathered.</li></ul>
                                </li>
                                <li>Customer
                                <ul><li>To acquire new customers and retain existing customer, referral programs and promotions based on target audience can be implemented.</li>
                                <li>To predict whether the customer would come back to Jumpman23 platform again, we can develop a model that gives the probability of customer ordering from Jumpman23 again if the customer orders from a specific merchant. The model could use features from both the customers and merchants past order experiences, such as order delivery time discrepancy, item preparation time, etc. </li></ul>
                                </li>
                                <li>Delivery-Partner
                                <ul><li>The pick-up time at merchants and drop-off times at different locations impacts utilization. By incentivizing merchants to improve the delivery-partner experience by down-ranking merchants with longer pick-up times, which also leads to longer delivery times.</li>
                                <li>When the delivery-partners are dispatched to a merchant, the different trip states like waiting/walking/parking at merchants can be utilized  to ensure they arrive just when the item is ready. This dispatch method minimizes the wait time for the delivery-partner at the merchant and, ultimately, helps them complete more trips. For the customer, we can offer better estimated time of delivery and ensure that the item is delivered as soon as possible with shorter wait time.</li></ul>
                                </li>
                                <li>Merchant
                                <ul><li>We have to provide opportunity for all the merchants to be seen on our platform. With the historical data the merchants can be ranked by relevance on the platform and can be shown to customers.</li>
                                <li>Build a model for merchants such that a new merchant is ranked highly initially to increase exposure. And as the new merchant gathers more impressions, more weight is given back to relevance.</li></ul>
                                </li>
                                
                                </ul>'),
                           br() 
                           
                           )
########################################################################################################################################################################################################        

        ) #Ending tabItems
    
  )
)