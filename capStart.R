library(sp)
library(ggmap)
library(plotKML)
library(googleVis)
library(fpc)
library(dplyr)
library(doMC)
library(jsonlite)
library(ggmap)
LV <- get_map(location = 'Las Vegas', zoom = 11)
ggmap(LV)
doMC::registerDoMC(cores=4)
load("~/courCap/db.RData")
businessData <- stream_in(file("~/Downloads/yelp_dataset_challenge_academic_dataset/yelp_academic_dataset_business.json"))
ggmap(LV) + geom_point(data = businessData, aes(x = longitude, y = latitude,colour=db)) + stat_density2d(
  aes(x = longitude, y = latitude, fill = ..level.., alpha = ..level..),
  size = 2, bins = 4, data = businessData,
  geom = "polygon" 
) + scale_fill_gradient(low = "black", high = "red") 
ggmap(LV) + geom_polygon(data = dataN,aes(x=long,y=lat,group = group),colour='red',fill="red")
+ 
  geom_point(data = clustData, aes(x = longitude, y = latitude,colour=db)) 

businessDataN <- data.frame(lat = businessData$latitude,lon = businessData$longitude)
db <- dbscan(businessDataN,eps = 0.0009,MinPts = 10)
businessData$db <- as.numeric(db$cluster)
clustData <- businessData[businessData$db != 0,]
clustData <- clustData %>% select(longitude,latitude,db) 
PolyList <- list()
for(i in 1:max(clustData$db)){
  #   print(i)
  
  currentPoly <- subset(clustData,db == i) 
  
  
  if(nrow(currentPoly)>6){
    coordinates(currentPoly) <- ~longitude+latitude
    proj4string(currentPoly) <- CRS("+proj=longlat +datum=WGS84")
    dd <- adehabitatHR::mcp(currentPoly, percent=100, unin = c("m", "km"),
                            unout = c("ha", "km2", "m2"))
    dd@polygons[[1]]@ID[[1]] <- paste(i)
    PolyList <- c(PolyList,dd@polygons)            
  }  
}

nnn <- SpatialPolygons(PolyList)
proj4string(nnn) <- CRS("+proj=longlat +datum=WGS84")
dataN <- fortify(nnn)
kml_open("~/Commericial1.kml")
kml_layer.SpatialPolygons(nnn, 
                          extrude = TRUE, tessellate = FALSE, 
                          outline = TRUE, plot.labpt = FALSE, z.scale = 1, 
                          LabelScale = get("LabelScale", envir = plotKML.opts), 
                          metadata =  NULL, html.table = NULL, TimeSpan.begin = "", 
                          TimeSpan.end = "", colorMode = "random")
kml_close("~/Commericial1.kml")

