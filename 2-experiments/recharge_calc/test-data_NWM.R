# Initialize input datasets
dataset <- #Year huc8 lat long

temperature <- read.csv(here("1-data/NWM_T_WY.csv"), check.names = FALSE)
precipitation <- read.csv(here("1-data/NWM_P_WY.csv"), check.names = FALSE)
actualET <- read.csv(here("1-data/NWM_ET_WY.csv"), check.names = FALSE)
spatialVariables <- read.csv(here("1-data/huc8_spatial-variables.csv"), check.names = FALSE)

# Initialize variable dataframe
variables <- as.data.frame(matrix(nrow = nrow(dataset), ncol = 46))
colnames(variables) <- c("Temp_C", "Precip_MM", "AET_MM", "Elevation_M", colnames(spatialVariables[3:44]))

pb <- progress::progress_bar$new(total = nrow(dataset))

# Loop to add temp, precip, aet, elevation
for(i in 1:nrow(dataset)){
  # Get HUC and year for index
  huc.site <- dataset$HUC8[i]
  year.site <- dataset$Year[i] #year needs to be character

  # Get indices for the streamgage HUC from variable datasets
  huc.temp <- which(temperature$HUC8 == huc.site)
  huc.precip <- which(precipitation$HUC8 == huc.site)
  huc.aet <- which(actualET$HUC8 == huc.site)
  huc.vars <- which(spatialVariables$HUC8 == huc.site)

  variables$Temp_C[i] <- temperature[huc.temp, year.site]
  variables$Precip_MM[i] <- precipitation[huc.precip, year.site]
  variables$AET_MM[i] <- actualET[huc.aet, year.site]
  variables[i,5:46] <- spatialVariables[huc.vars,3:44]

  # Extract elevation for point
  coords <- dataset[i,3:4]
  colnames(coords) <- c("x", "y")

  suppressMessages(elev <- get_elev_point(coords, prj = 4326)) #wgs 84 proj
  variables$Elevation_M[i] <- elev$elevation
  pb$tick()
}

# Combine dataset with variables
results <- cbind(dataset, variables)

