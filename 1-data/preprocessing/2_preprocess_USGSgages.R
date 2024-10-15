#################################################
## USGS streamgage BFI for AZ gauges
## Data source: USGS
## Timeframe: 1901-2023
#################################################

# Get discharge data for all AZ streamgages
sites_init <- dataRetrieval::whatNWISsites(stateCd = "AZ", #Only sites in AZ
                            parameterCd = "00060",  #discharge
                            service="dv")

# Preprocessing retrieved streamgages
sites <- filter(sites_init, site_tp_cd %in% c('ST')) #only sites that are a Stream
sites <- sites[,-c(1,4,7,8)] #remove unwanted columns
colnames(sites) = c('Site_Num', 'Station_Name', 'Latitude', 'Longitude')
sites <- sites[c(1:254,256:478),] #hard code remove specific problem site

#################################################
## Remove Colorado River gauges
#################################################

# Find indices where "Colorado River" appears in the Station_Name column
colorado_sites_indices <- grep("Colorado River", sites$Station_Name, ignore.case = TRUE)

little_colorado_sites_indices <- grep("Little Colorado River", sites$Station_Name, ignore.case = TRUE)

# Exclude "Little Colorado River" from the indices of "Colorado River"
final_colorado_sites_indices <- setdiff(colorado_sites_indices, little_colorado_sites_indices)

sites_noCO <- sites[-final_colorado_sites_indices, ]

#################################################
## Run annualUSGS_preprocessing function
#################################################

# Get filtered annual BFI for gauged sites
USGSsites = annualUSGS_preprocessing(sites_noCO)
yearly_bfi <- USGSsites$results

#################################################
# Add lat/long to each site
#################################################
for (i in 1:nrow(yearly_bfi)){
  site_no <- yearly_bfi$Site_Num[i]
  this_site <- which(sites$Site_Num == site_no)

  yearly_bfi$Long[i] <- sites$Longitude[this_site]
  yearly_bfi$Lat[i] <- sites$Latitude[this_site]
}

#################################################
# Assign HUC to each site by lat/long
#################################################

#HUC8 shapefile in correct crs
huc8_shape <- st_read(here("1-data/raw/shapefile/huc8.shp"))
huc8_shape <- st_transform(huc8_shape, crs = "+proj=longlat +datum=WGS84 +no_defs")

# Convert streamgage dataframe (sites_noCO) into an sf object
sites_sf <- st_as_sf(sites_noCO, coords = c("Longitude", "Latitude"), crs = 4326) #WGS 84

# Perform a spatial join to assign each site to the corresponding HUC basin
sites_with_huc <- st_join(sites_sf, huc8_shape, left = FALSE)

# Assign HUC to sites
for (i in 1:nrow(yearly_bfi)){
  this.site <- yearly_bfi$Site_Num[i]
  which.site <- which(sites_with_huc$Site_Num == this.site)

  yearly_bfi$HUC8[i] <- sites_with_huc$HUC8[which.site]
}

# Reorder columns
annual_USGSsites <- yearly_bfi[,c(6,1,4,5,2,3)]

#################################################
## Run assignVariables_preprocessing function
## input - annual_USGSsites
#################################################

trainingData <- assignVariables_preprocessing(annual_USGSsites)

write.csv(trainingData, here('1-data/instrumented_all-predictors.csv'), row.names = FALSE)
write.csv(trainingData, here('2-experiments/models/data/instrumented_all-predictors.csv'), row.names = FALSE)
