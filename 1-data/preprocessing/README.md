---
output:
  pdf_document: default
  html_document: default
---
# Preprocessing

### 0_preprocess_ET.R

-   HUC8 Mean Annual Actual Evapotranspiration (AET)
-   Data source: TerraClimate
-   Timeframe: 1901-2023 (years before 1958 replaced with basin mean over period of record)
-   Unit: mm

### 0_preprocess_precip.R

-   HUC8 Mean Annual Precipitation
-   Data source: PRISM
-   Timeframe: 1901-2023
-   Unit: mm

### 0_preprocess_temperature.R

-   HUC8 Mean Annual Temperature
-   Data source: PRISM
-   Timeframe: 1901-2023
-   Unit: degrees C

### 1_preprocess_fx.R

**annualUSGS_preprocessing function**

INPUT: dataframe where column 1 is USGS streamgage number

OUTPUT: list of `results` dataframe and `errors` indices

`results` is a dataframe with 3 columns: Site_Num, Year, BFI

`errors` contains the indices of observations that do not fit the filter criteria

-   filters through period of record of streamgage and for years with \>335 day coverage calculates BFI
-   filters through years with BFI to ensure \>10 years with positive BFI (some errors produce negative BFI)
-   adds filtered sites to results dataframe and error indices to errors list

**assignVariables_preprocessing function**

INPUT: dataframe where col 1 is HUC8, col 2 is Site_Num, col 3 is Longitude, col 4 is Latitude, col 5 is Year

OUTPUT: dataframe equivalent to input dataframe with associated temperature, precipitation, actual ET, elevation, and spatial data to each year/HUC observation

-   Hard coded to access csv files produced in `0_preprocess_ET`, `0_preprocess_precip`, and `0_preprocess_temperature`

### 2_preprocess_USGSgages.R

Script to load specifics to this study.

-   USGS streamgages in AZ (only streams)
-   remove Colorado River sites
-   feed desired datasets into functions from `1_preprocess_fx`
