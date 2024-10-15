#################################################
## Function to get discharge for USGS streamgages and calculate
## BFI for each year
##
## Data source: USGS
#################################################

annualUSGS_preprocessing <- function(dataset){

  dataset <- as.data.frame(cbind(dataset, BFI = 0)) # Create BFI column in dataset
  errors <- c() # Initialize an empty vector to store error indices

  # Initialize an empty dataframe to store the final results
  results <- data.frame(Site_Num = character(), Year = character(), BFI = numeric(), stringsAsFactors = FALSE)

  # Initialize progress bar with total rows in the dataset
  pb <- progress::progress_bar$new(total = nrow(dataset))

  for (i in 1:nrow(dataset)){
    # Retrieve site number for each row
    site_no <- as.character(dataset[i, 1])

    # Retrieve data from USGS streamgage for each site number
    gauge <- dataRetrieval::readNWISdv(
      siteNumbers = toString(site_no),
      parameterCd = "00060",
      statCd = "00003",
      endDate = "2023-12-31"
    )

    # Remove missing values from the gauge data
    gauge <- na.omit(gauge)

    # Convert Date column to Date format and extract year
    gauge$Date <- as.Date(gauge$Date)
    gauge$Year <- format(gauge$Date, "%Y")

    # Initialize a dataframe to store BFI calculations for each valid year of the streamgage
    yearly_bfi <- data.frame(Site_Num = character(), Year = character(), BFI = numeric(), stringsAsFactors = FALSE)

    if (nrow(gauge) != 0){
      # Loop through each unique year in the gauge data
      for (year in unique(gauge$Year)){
        year_data <- gauge[gauge$Year == year, ]

        # Check if the year has more than 335 days of data
        if (nrow(year_data) > 335){
          # Perform baseflow separation for this year's data
          bf <- EcoHydRology::BaseflowSeparation(year_data$X_00060_00003, passes = 3)

          BFsum <- sum(bf$bt)
          Tsum <- sum(bf$qft) + sum(bf$bt)
          bfi <- BFsum / Tsum

          # Store the streamgage, year, and BFI value if BFI is not NaN and >= 0
          if (!is.nan(bfi) & bfi >= 0 & bfi <= 1){
            yearly_bfi <- rbind(yearly_bfi, data.frame(Site_Num = site_no, Year = year, BFI = bfi, stringsAsFactors = FALSE))
          }
        }
      }

      # If the streamgage has 10 or more valid years (with non-NaN and BFI >= 0), add it to the results
      if (nrow(yearly_bfi) >= 10){
        results <- rbind(results, yearly_bfi)
      } else {
        errors <- append(errors, i) # Store the index if not enough valid years
      }
    } else {
      errors <- append(errors, i) # Store the index of the error if no data
    }
    pb$tick()
  }

  # Remove any streamgages stored in errors from the results
  if (length(errors) > 0) {
    # Retrieve the Site_Num for the rows that correspond to the error indices
    invalid_sites <- dataset$Site_Num[errors]
    results <- results[!results$Site_Num %in% invalid_sites, ]
  }

  # Return the final results dataframe and error indices
  output <- list('results' = results, 'errors' = errors)
  return(output)
}


#################################################
## Function to assign precip, temp, aet, elevation, spatial variables
## to each observation of yearly_bfi (training data)
##
## Data source: USGS
#################################################

assignVariables_preprocessing <- function(dataset){
  # Load datasets
  temperature <- read.csv(here("1-data/huc8_temperature.csv"), check.names = FALSE)
  precipitation <- read.csv(here("1-data/huc8_precip.csv"), check.names = FALSE)
  actualET <- read.csv(here("1-data/huc8_aet.csv"), check.names = FALSE)
  spatialVariables <- read.csv(here("1-data/huc8_spatial-variables.csv"), check.names = FALSE)

  # Initialize variable dataframe
  variables <- as.data.frame(matrix(nrow = nrow(dataset), ncol = 46))
  colnames(variables) <- c("Temp_C", "Precip_MM", "AET_MM", "Elevation_M", colnames(spatialVariables[3:44]))

  pb <- progress::progress_bar$new(total = nrow(dataset))

  # Loop to add temp, precip, aet, elevation
  for(i in 1:nrow(dataset)){
    # Get HUC and year for index
    huc.site <- dataset$HUC8[i]
    year.site <- dataset$Year[i]

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
  return(results)
}
