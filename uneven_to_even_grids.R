######################################################################
# extracting irregularly gridded data in a netcdf4 into a regular grid by Michael Sumner
# used by Pam Michael on " Future phy - Bluelink" data ~ 2015 July
# 
# *** I need to get an example dataset without sharing restictions ***
# *** I ran it on an evely spaced grid, but Temp is Kelvin, ~1 year of daily data, the plot isn't happening ***
######################################################################

# list of netcdf 4 files using an uneven grid
# I will try to run it on these data tomorrow afternoon from the office
# bluelink phytoplankton, irregular grid
setwd("//argos-cdc/sdode-data/Product422")
dp <- "//argos-cdc/sdode-data/Product422"
fs <- list.files(dp, full.names = TRUE) ##

#### but for now I'm reading in an NCEP REAN dataset to make sure the netCDF4 are up to date
setwd("C:/Users/Pamela E.Michael/Dropbox")#Dropbox/pam_stuff/QMS/data/R Projects/NEW ENVIRON DATA/NCEP NCAR not noaa quarter")
fs <-"X140.79.20.188.15.15.28.8.nc"  # random download ~ Indian Ocean, sst skin (NCEP Rean daily) 1948 through 1949

library(raster)
library(ncdf4)
library(dplyr)
library(palr)# sstPal fxn

# function to read in files and create an evenly spaced datset
# I've chaged the function so the user supplies the x & y coordinate names
fun <- function(x, grid, vname, x_coord, y_coord) {
  on.exit(nc_close(nc))
  nc <- nc_open(x)
  tlen <-(nc$dim[[1]])$len # formerly "dim.inq.nc(nc, 1)$len" pre package update ... am I requesting the same thing?
  r <- raster(x, varname = vname, stopIfNotEqualSpaced = FALSE, band = 1)/tlen
  #return(r)
  
  ## calculate entire mean
  for (i in seq(2, tlen)) {
    r <- r + raster(x, varname = vname, stopIfNotEqualSpaced = FALSE, band = i)/tlen 
  }
  lon <- ncvar_get(nc, x_coord) 
  lat <- ncvar_get(nc, y_coord) 
  ## we must reverse lat to get the orientation right
  pts <- as.matrix(expand.grid(lon, rev(lat)))
  
  celltab <- cellFromXY(grid, pts)
  
  vals <- data_frame(cell = celltab, val = values(r)) %>% 
    filter(!is.na(cell)) %>% 
    group_by(cell) %>% 
    summarize(mean = mean(val, na.rm = TRUE))
  
  grid[] <- NA_real_
  grid[vals$cell] <- vals$mean
  
  grid
}

#create a way to aggregate the cells once they are made
dummy <- raster(extent(15, 160, -80, -10), res = 5, crs = "+proj=longlat +ellps=WGS84")

#make a raster
# once I get into the office I can try it on bluelink
#phy1 <- fun(fs[1], dummy, "phy", "xt_ocean", "yt_ocean") # 

# for now, it is NCEP, temp=Kelvin, temporal = daily
phy1 <- fun(fs, dummy, "skt", "lon", "lat") # SST in kelvin..


# plot it

library(palr)
pal <- sstPal(palette = TRUE)
#par(mfrow = c(4,3)) # if there is a vector of dates, plot up a few
plot(phy1, col = pal$cols, breaks = pal$breaks, legend = FALSE) 

#if you want to save the data as a data.frame
phy1df <-data.frame(rasterToPoints(phy1))

# give it human readable names
names(phy1df)[names(phy1df)=="layer"] <- "variable_name"
names(phy1df)[names(phy1df)=="x"] <- "lon"
names(phy1df)[names(phy1df)=="y"] <- "lat"
