## ---------------------------
##
## Script name: 03_calcDistances.R
##
## Purpose of script: This script geolocates cleaned voterfiles: specifically, it creates the distance calculation.
##
## Author: Jordan Duffin Wong
##
## Date Created: 2025-07-04
##
## Copyright (c) Jordan Duffin Wong, 2025
## Email: jordanduffinw@gmail.com
##
## ---------------------------
##
## Notes: Made with R 4.4.0
##
## ---------------------------

##### Timer #####
## This (and code at the very end) measure the time elapsed for running the script in one go.
start.time <- Sys.time()

##### LIBRARIES #####
## For shapefile manipulation
library(sf)
library(terra)
library(nngeo)

## For general tidyverse operations
library(tidyverse)

##### READ IN CENSUS GEOGRAPHIES #####
## Import Shapefiles
load("../data/_raw/place_shapes.Rda")   # Place shapes

##### READ IN POINT DATA #####
load("../data/01_pointData/pointData.Rda")

### Project shapes
place_shapes <- st_transform(place_shapes, crs = 26915) %>%
  # filter(STATEFP20 == "30") %>% 
  select(GEOID20, NAME20, geometry)

pointData <- st_transform(pointData, crs = 26915)

### Function for distance calculation
getDistance <- function(points, shapes){
  
  filename = paste0("pointDist_", unique(points$group))
  
  lines = st_union(shapes) %>% st_cast("POLYGON") %>% st_cast("LINESTRING") %>% st_as_sf()
  
  nearest_shapes = st_nearest_feature(x = points, y = shapes)
  
  nearest_lines = st_nearest_feature(x = points, y = lines)
  
  dist = st_distance(x = points, y = lines[nearest_lines,], by_element = TRUE) # this is the bottleneck
  
  near_placeName <- shapes[nearest_shapes,]$NAME20  # Gets name of nearest municipality
  near_placeID <- shapes[nearest_shapes,]$GEOID20 # Gets FIPS of nearest municipality --- need to 
  
  output <- cbind(points, near_placeName, near_placeID, lines[nearest_lines,]) %>%
    mutate(dist_meters_abs = dist %>% as.numeric(),
           dist_miles_abs = dist_meters_abs * 0.000621371,
           withinMile = case_when(
             dist_miles_abs < 1 ~ 1,
             dist_miles_abs > 1 ~ 0) %>% as.factor()
    ) %>% 
    select(ID, near_placeName, near_placeID, dist_meters_abs, dist_miles_abs, withinMile) %>%
    as.data.frame()
  
  assign(filename, output, envir = .GlobalEnv)
}

##### CALCULATE DISTANCE #####
### Partition
pointData$group <- 1:nrow(pointData) %% floor(round(nrow(pointData), digits = -4) / 10000) + 1
pointGroups <- split.data.frame(x = pointData, f = pointData$group)

pointList <- vector("list")

start.time.loop <- Sys.time()
for (i in sort(unique(pointData$group))) {
  print(paste(i,"/", max(pointData$group), "::", "Time elapsed is", Sys.time() - start.time.loop, sep = " "))
  pointList[[i]] <- getDistance(points = pointGroups[[i]], shapes = place_shapes)
}

distanceData = do.call(rbind, pointList)

save(distanceData, file = "../data/03_distanceData/distanceData.Rda")

##### DONE! #####
end.time <- Sys.time()
time.taken <- end.time - start.time
print(paste("Done! It took", time.taken))