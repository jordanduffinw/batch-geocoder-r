## ---------------------------
##
## Script name: 04_getOtherData.R
##
## Purpose of script: This script extracts relevant relevant data from points, to be joined with geographic data later.
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

otherData <- raw_points %>% filter(STATE_CODE == 30) %>%
  select(ID, geometry, STATISTICA, IGNITION, DISCOVERY, FIRE_OUT, TOTAL_ACRE, WIND_SPEED, ELEVATION) %>% 
  st_transform(crs = 26915)

save(otherData, file = "../data/04_otherData/otherData.Rda")

##### DONE! #####
end.time <- Sys.time()
time.taken <- end.time - start.time
print(paste("Done! It took", time.taken))