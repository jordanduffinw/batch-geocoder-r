## ---------------------------
##
## Script name: 02_makeGeos.R
##
## Purpose of script: This script maps point-pattern data into appropriate geographies. The output from this script only tells you which shapes the points intersect. There is no additional geometric information.
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
## For general tidyverse operations
library(tidyverse)

### For spatial operations 
library(sf)

##### READ IN CENSUS GEOGRAPHIES #####
## Import Shapefiles
load("../data/_raw/state_shapes.Rda")   # State shapes
load("../data/_raw/county_shapes.Rda")  # County shapes
load("../data/_raw/place_shapes.Rda")   # Place shapes
load("../data/_raw/tract_shapes.Rda")   # Census tract shapes
load("../data/_raw/bg10_shapes.Rda")    # 2010 Census block group shapes

##### READ IN POINT DATA #####
load("../data/01_pointData/pointData.Rda")

##### GEO INTERPOLATION #####
### Project shapes
state_shapes <- st_transform(state_shapes, crs = 26915) #%>% filter(STATEFP20 == "30")
county_shapes <- st_transform(county_shapes, crs = 26915) #%>% filter(STATEFP20 == "30")
place_shapes <- st_transform(place_shapes, crs = 26915) #%>% filter(STATEFP20 == "30")
tract_shapes <- st_transform(tract_shapes, crs = 26915) #%>% filter(STATEFP20 == "30")
bg10_shapes <- st_transform(bg10_shapes, crs = 26915) #%>% filter(STATEFP10 == "30")

pointData <- st_transform(pointData, crs = 26915)

### Function for geolocating points to shapes
geolocate <- function(points, shape1, shape2, shape3, shape4, shape5, outputname){
  
  pointdata <- points
  
  joined <- st_join(x = points, y = shape1) %>% select(ID, geometry, GEOID20, STUSPS20) %>% rename(state_fips = GEOID20, state = STUSPS20) %>% 
            st_join(x = ., y = shape2) %>% select(ID, geometry, state_fips, state, GEOID20, NAMELSAD20) %>% rename(county_fips = GEOID20, county = NAMELSAD20) %>% 
            st_join(x = ., y = shape3) %>% select(ID, geometry, state_fips, state, county_fips, county, GEOID20, NAMELSAD20, LSAD20) %>% rename(place_id = GEOID20, place = NAMELSAD20, place_type = LSAD20) %>% 
            st_join(x = ., y = shape4) %>% select(ID, geometry, state_fips, state, county_fips, county, place_id, place, place_type, GEOID20) %>% rename(tract_id = GEOID20) %>% 
            st_join(x = ., y = shape5) %>% select(ID, geometry, state_fips, state, county_fips, county, place_id, place, place_type, tract_id, GEOID10) %>% rename(bg_id = GEOID10)
  
  assign(paste0(outputname), joined, envir = .GlobalEnv)
}

### Chunking and geolocating
pointData$group <- 1:nrow(pointData) %% floor(round(nrow(pointData), digits = -4) / 10000) + 1
pointGroups <- split.data.frame(pointData, pointData$group)
pointList <- vector("list")

start.time.loop <- Sys.time()

for (i in sort(unique(pointData$group))) {
  print(paste(i,"/", max(pointData$group), "::", "Time elapsed is", Sys.time() - start.time.loop, sep = " "))
  
  pointList[[i]] <- geolocate(points = pointGroups[[i]], shape1 = state_shapes, shape2 = county_shapes, shape3 = place_shapes, shape4 = tract_shapes, shape5 = bg10_shapes, outputname = "geometryData")
}

geometryData = do.call(rbind, pointList) %>% as.data.frame()

save(geometryData, file = "../data/02_geometryData/geometryData.Rda")

##### DONE! #####
end.time <- Sys.time()
time.taken <- end.time - start.time
print(paste("Done! It took", time.taken))