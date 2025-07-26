## ---------------------------
##
## Script name: 05_joinData.R
##
## Purpose of script: This script joins the outputs from 01_getPoints.R, 02_makeGeos.R, 03_calcDistances.R, and 04_getVoterData.R
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
## For reading in .tab files and "large" files
library(data.table)
library(readr)

## For general tidyverse operations
library(tidyverse)

### For spatial operations 
library(sf)

##### IMPORT DATA #####
load("../data/01_pointData/pointData.Rda")
load("../data/02_geometryData/geometryData.Rda")
load("../data/03_distanceData/distanceData.Rda")
load("../data/04_otherData/otherData.Rda")

pointData <- as.data.frame(pointData)
geometryData <- as.data.frame(geometryData)
distanceData <- as.data.frame(distanceData)
otherData <- as.data.frame(otherData)

##### MERGE AND OUTPUT #####
joinedData <- left_join(
  x = pointData,
  y = otherData,
  by = "ID") %>% 
  left_join(
    x = .,
    y = geometryData %>% select(-geometry),
    by = "ID") %>% 
  left_join(
    x = .,
    y = distanceData %>% as.data.frame() %>% select(-geometry),
    by = "ID"
  ) %>% 
  mutate(incorp = case_when(
    !is.na(place_id) ~ 1,
    is.na(place_id) ~ 0
  )) %>% 
  select(-geometry.y) %>% 
  rename(geometry = geometry.x) %>% 
  st_as_sf() %>% 
  filter(dist_miles_abs < 200)

save(joinedData, file = "../data/05_joinedData/joinedData.Rda")

##### TEST PLOT #####
load("../data/_raw/state_shapes.Rda")   # State shapes
load("../data/_raw/place_shapes.Rda")   # Place shapes

state_shapes <- st_transform(state_shapes, crs = 5070) %>% 
  filter(STATEFP20 == "30")

place_shapes <- st_transform(place_shapes, crs = 5070) %>%
  filter(STATEFP20 == "30") %>% 
  select(GEOID20, NAME20, geometry)

ggplot()+
  geom_sf(data = state_shapes,
          fill = NA,
          lwd = 1)+
  geom_sf(data = place_shapes, fill = "gray")+
  geom_sf(data = sample_n(joinedData, 300) %>% st_transform(crs = 5070),
          aes(color = as.factor(STATISTICA), shape = as.factor(incorp)))+
  scale_shape_manual(values = c(3, 16),
                     labels = c("Unincorporated", "Incorporated"))+
  labs(color = "Cause", shape = "Location")+
  theme_bw()

ggsave(filename = "../viz/montana_fires.png",
       plot = last_plot(),
       width = 8, height = 6)

##### DONE! #####
end.time <- Sys.time()
time.taken <- end.time - start.time
print(paste("Done! It took", time.taken))