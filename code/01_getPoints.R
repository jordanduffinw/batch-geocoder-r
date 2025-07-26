## ---------------------------
##
## Script name: 01_getPoints.R
##
## Purpose of script: This script extracts point-pattern data for use in batch geocoding.
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

##### MAKE POINT DATA #####
## This loads the data, processes to point a Rda, and exports
raw_points <- read_sf(dsn = "../data/_raw/S_USA.Fire_Occurrence_FIRESTAT_YRLY/S_USA.Fire_Occurrence_FIRESTAT_YRLY.shp")
raw_points$ID <- c(1:nrow(raw_points))

pointData <- raw_points %>%
  # filter(STATE_CODE == 30) %>%
  select(ID, geometry) %>% 
  st_transform(crs = 26915)
save(pointData, file = "../data/01_pointData/pointData.Rda")

##### DONE! #####
end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)