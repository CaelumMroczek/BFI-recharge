ecohydro <- "https://cran.r-project.org/src/contrib/Archive/EcoHydRology/EcoHydRology_0.4.12.1.tar.gz"
install.packages(ecohydro, repos=NULL, type="source")

install.packages('remotes')
library('remotes')

remotes::install_github("mikejohnson51/AOI")
#remotes::install_github("mikejohnson51/climateR") Problem causer on Mac

# Create a vector of all the package names
packages <- c("AOI", "data.table", "dataRetrieval", "dplyr","exactextractr",
              "ggplot2", "here", "lubridate", "raster", "readr",
              "renv", "rmarkdown", "sf", "sp", "stringr", "tidyverse", "terra",
              "elevatr", "boot", "xgboost", "caret", "ggthemes", "hydroGOF")

# Install packages that are not already installed
install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

# Apply the function to all packages
invisible(lapply(packages, install_if_missing))

# Load all the packages
lapply(packages, library, character.only = TRUE)
