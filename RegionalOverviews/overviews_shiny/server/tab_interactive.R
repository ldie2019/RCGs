

# ******************
# Tab "with leaflet"
# ******************

dd <- reactive({
  
  data<-data_list()[[3]]
  data<-as.data.frame(data)
  
  if (!("All" %in% input$region)){
    data <- data[data$Region == input$region,]
  }
  data
})
  

observe({
  # Updating selectize input
  updateSelectInput(session, "country", choices = unique(dd()$LandingCountry), selected = sort(unique(dd()$LandingCountry))[1]) 
})

output$absolute <- renderUI({
  req(input$file)
  absolutePanel(
    id = "controls",
    class = "panel panel-default",
    fixed = TRUE,
    draggable = TRUE,
    bottom = "auto",
    left = "auto",
    right = 20,
    top = 100,
    width = 450,
    height = "auto",
    h2("Sampling explorer", align = "center"),
    # uiOutput("countryui"),uiOutput("speciesui"),uiOutput("samptypeui"),uiOutput("quarterui"),
    selectInput(
      "region",
      "Region",
      choices =
        c("All", levels(data_list()[[3]]$Region)),
      multiple = F,
      selected = "All"
    ),
    selectizeInput(
      "country",
      "Country",
      choices = c(""),
      # c("All", levels(data_list()[[3]]$LandingCountry)),
      multiple = TRUE,
      #selected = "All",
      options = list(plugins = list("remove_button", "drag_drop"))
    ),
    selectizeInput(
      "species",
      "Species",
      choices =
        c("All", levels(data_list()[[3]]$Species)),
      multiple = TRUE,
      selected = "All",
      options = list(plugins = list("remove_button", "drag_drop"))
    ),
    selectizeInput(
      "samtype",
      "Sampling Type",
      choices =
        c("All", levels(data_list()[[3]]$SamplingType)),
      multiple = TRUE,
      selected = "All",
      options = list(plugins = list("remove_button", "drag_drop"))
    ),
    selectizeInput(
      "quarter",
      "Quarter",
      choices =
        c("All", levels(data_list()[[3]]$Quarter)),
      multiple = TRUE,
      selected = "All",
      options = list(plugins = list("remove_button", "drag_drop"))
    ),
    
    selectInput ("N_var2", "Variable", var, multiple = F),
    checkboxInput("rec", "ICES Rectangles"),
    br(),
    actionButton ("view2", "View"),
    downloadButton("down", "Generate report"),
    br(),
    hr(),
    br(),
    br(),
    plotOutput("plot2", height = 300)
    #, tableOutput("debug")
  )
})


# output ca_map
#    output$countryui<-renderUI({selectizeInput(
#       "country",
#       "Country",choices=
#       c("All", levels(data_list()[[3]]$LandingCountry)),
#       multiple = TRUE,
#       selected = "All",
#       options = list(plugins = list("remove_button", "drag_drop"))
#    )})
# 
#    output$speciesui<-renderUI({
# selectizeInput(
#    "species",
#    "Species",choices=
#    c("All", levels(data_list()[[3]]$Species)),
#    multiple = TRUE,
#    selected = "All",
#    options = list(plugins = list("remove_button", "drag_drop"))
# )})
# 
#   output$samptypeui<-renderUI({
# selectizeInput(
#    "samtype",
#    "Sampling Type",choices=
#    c("All", levels(data_list()[[3]]$SamplingType)),
#    multiple = TRUE,
#    selected = "All",
#    options = list(plugins = list("remove_button", "drag_drop"))
# )})
#   
#   output$quarterui<- renderUI({
# selectizeInput(
#    "quarter",
#    "Quarter",choices=
#    c("All", levels(data_list()[[3]]$Quarter)),
#    multiple = TRUE,
#    selected = "All",
#    options = list(plugins = list("remove_button", "drag_drop"))
# )})





# -----------------------------------
# Filtered data
# -----------------------------------

df <- reactive({
  
  data<-data_list()[[3]]
  data<-as.data.frame(data)
  
  #if (!("All" %in% input$country)){
    data <- data[data$LandingCountry %in% input$country,]
  #}
  if (!("All" %in% input$species )){
    data <- data[data$Species %in% input$species,]
  }
  if (!("All" %in% input$samtype)){
    data <- data[data$SamplingType %in% input$samtype,]
  }
  if (!("All" %in% input$quarter)){
    data <- data[data$Quarter %in% input$quarter,]
  }
  
  data <- data[, c("LandingCountry", "Quarter",  "Species", "SamplingType",
                   "lat", "lon", input$N_var2)]
  names(data) <- c("LandingCountry", "Quarter",  "Species", "SamplingType",
                   "lat", "lon", "aux")
  data
})

# # --------------------------------------
# # Data aggregation at location 
# # filtered data updated with view button
# # --------------------------------------
# 
filter_df <- eventReactive(input$view2, {
  if(nrow(df())!=0){
    dat<-aggregate(list(aux = df()$aux),
                   by = list(lat = df()$lat, lon = df()$lon),
                   # LandingCountry = df()$LandingCountry,
                   # Species = df()$Species,
                   # SamplingType = df()$SamplingType,
                   # Quarter = df()$Quarter),
                   FUN = sum)
  }
  else {
    dat <- df()
  }
})
# 

# -----------------------------------
# Debugging
# -----------------------------------

 # output$debug <- renderTable({
 # #head(df(), 5)
 #   head(data_list()[[3]])
 # })


# -----------------------------------
# leaflet map and barplots
# -----------------------------------



#input$view2ColorsBAR <- colour_table$colour4
ColorsBAR <- colour_table$colour4
names(ColorsBAR) <- colour_table$Country
colScaleBAR<-scale_fill_manual(name="LandingCountry", values=ColorsBAR)

pal.rmd<-reactive({colorNumeric ("viridis", domain = as.numeric(filter_df()$aux))})


output$down <- downloadHandler(
  # For PDF output, change this to "report.pdf"
  filename = paste("report",Sys.Date(),".html",sep=''),
  
  content = function(file) {
    # Copy the report file to a temporary directory before processing it, in
    # case we don't have write permissions to the current working dir (which
    # can happen when deployed).
    tempReport <- file.path(tempdir(), "report.Rmd")
    
    file.copy("markdown/report.Rmd", tempReport, overwrite = TRUE)
    # 
    
    
    # Set up parameters to pass to Rmd document
    params <- list(c = input$country, s = input$species,
                   t = input$samtype, q = input$quarter,
                   v = input$N_var2, data1 = df(),data2 = filter_df(),
                   f = colScaleBAR,
                   p = pal.rmd())
    
    # Knit the document, passing in the `params` list, and eval it in a
    # child of the global environment (this isolates the code in the document
    # from the code in this app).
    rmarkdown::render(tempReport, output_file = file,
                      params = params,
                      envir = new.env(parent = globalenv())
    )
  }
)

# -----------------------------------
# leaflet map and barplots
# -----------------------------------



output$map <- renderLeaflet({
  leaflet() %>% addProviderTiles(providers$CartoDB.Positron)  %>% 
    setView(lng = -5,lat =  52, zoom = 5)
})






# -----------------------------------
# Add filtered data to map
# -----------------------------------

observeEvent(input$view2,{
  #if (input$plottype == "Map")
  pal<-colorNumeric ("viridis", domain = as.numeric(filter_df()$aux))
  
  leafletProxy("map", data = filter_df())%>% 
    clearMarkers()%>% clearControls() %>% addProviderTiles(providers$CartoDB.Positron) %>% 
    addCircleMarkers(color=~pal(aux),
                     stroke=F,
                     radius=~ (sqrt(sqrt(aux))+0.6),
                     fillOpacity=0.8)%>%
    addLegend( "bottomleft", pal=pal, values=~aux, title = input$N_var2,opacity = 0.8)
})

# -----------------------------------
# Add ICES Rectangles Shapefile
# -----------------------------------

observe({
  proxy<-leafletProxy("map", data = filter_df())
  proxy%>%clearShapes()
  if (input$rec){
    proxy%>% addPolygons(data=ices.rect, weight=.4,fillOpacity = .1,color = 'grey',group = 'ices_squares',label = ~paste0(ICESNAME),highlight = highlightOptions(weight = 3, color = "red",
                                                                                                                                                                 bringToFront = TRUE))
  }
})

# -----------------------------------
# barplot to panel
# -----------------------------------


output$plot2 <- renderPlot ({
  #input$view2
  if (input$view2==0) return()
  
  #validate(need(input$plottype=="Barplot", message=FALSE))
  ColorsBAR <- colour_table$colour4
  names(ColorsBAR) <- colour_table$Country
  colScaleBAR<-scale_fill_manual(name="LandingCountry", values=ColorsBAR)
  isolate({ ggplot(df(), aes(x=LandingCountry, y=aux, fill=LandingCountry)) +
      geom_bar(stat="identity")+
      colScaleBAR +
      theme_bw()+
      theme(axis.text.x = element_text(angle = 90, hjust = 1))+
      labs(y = input$N_var2)
    
    
  })
  
})
