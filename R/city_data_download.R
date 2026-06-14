# Internal functions for downloading city data from various sources
# These are used by data-raw/cities.R to generate the world_cities dataset

#' Map ISO country codes to continents
#'
#' @param iso2 Character vector of ISO2 country codes
#' @return Character vector of continent names
#' @keywords internal
#' @noRd
map_country_to_continent <- function(iso2) {
  # Comprehensive mapping of ISO2 codes to continents
  continent_map <- c(
    # Africa
    "DZ" = "Africa", "AO" = "Africa", "BJ" = "Africa", "BW" = "Africa",
    "BF" = "Africa", "BI" = "Africa", "CM" = "Africa", "CV" = "Africa",
    "CF" = "Africa", "TD" = "Africa", "KM" = "Africa", "CG" = "Africa",
    "CD" = "Africa", "CI" = "Africa", "DJ" = "Africa", "EG" = "Africa",
    "GQ" = "Africa", "ER" = "Africa", "ET" = "Africa", "GA" = "Africa",
    "GM" = "Africa", "GH" = "Africa", "GN" = "Africa", "GW" = "Africa",
    "KE" = "Africa", "LS" = "Africa", "LR" = "Africa", "LY" = "Africa",
    "MG" = "Africa", "MW" = "Africa", "ML" = "Africa", "MR" = "Africa",
    "MU" = "Africa", "YT" = "Africa", "MA" = "Africa", "MZ" = "Africa",
    "NA" = "Africa", "NE" = "Africa", "NG" = "Africa", "RE" = "Africa",
    "RW" = "Africa", "SH" = "Africa", "ST" = "Africa", "SN" = "Africa",
    "SC" = "Africa", "SL" = "Africa", "SO" = "Africa", "ZA" = "Africa",
    "SS" = "Africa", "SD" = "Africa", "SZ" = "Africa", "TZ" = "Africa",
    "TG" = "Africa", "TN" = "Africa", "UG" = "Africa", "ZM" = "Africa",
    "ZW" = "Africa",

    # Asia
    "AF" = "Asia", "AM" = "Asia", "AZ" = "Asia", "BH" = "Asia",
    "BD" = "Asia", "BT" = "Asia", "BN" = "Asia", "KH" = "Asia",
    "CN" = "Asia", "CX" = "Asia", "CC" = "Asia", "IO" = "Asia",
    "GE" = "Asia", "HK" = "Asia", "IN" = "Asia", "ID" = "Asia",
    "IR" = "Asia", "IQ" = "Asia", "IL" = "Asia", "JP" = "Asia",
    "JO" = "Asia", "KZ" = "Asia", "KW" = "Asia", "KG" = "Asia",
    "LA" = "Asia", "LB" = "Asia", "MO" = "Asia", "MY" = "Asia",
    "MV" = "Asia", "MN" = "Asia", "MM" = "Asia", "NP" = "Asia",
    "KP" = "Asia", "OM" = "Asia", "PK" = "Asia", "PS" = "Asia",
    "PH" = "Asia", "QA" = "Asia", "SA" = "Asia", "SG" = "Asia",
    "KR" = "Asia", "LK" = "Asia", "SY" = "Asia", "TW" = "Asia",
    "TJ" = "Asia", "TH" = "Asia", "TL" = "Asia", "TR" = "Asia",
    "TM" = "Asia", "AE" = "Asia", "UZ" = "Asia", "VN" = "Asia",
    "YE" = "Asia",

    # Europe
    "AX" = "Europe", "AL" = "Europe", "AD" = "Europe", "AT" = "Europe",
    "BY" = "Europe", "BE" = "Europe", "BA" = "Europe", "BG" = "Europe",
    "HR" = "Europe", "CY" = "Europe", "CZ" = "Europe", "DK" = "Europe",
    "EE" = "Europe", "FO" = "Europe", "FI" = "Europe", "FR" = "Europe",
    "DE" = "Europe", "GI" = "Europe", "GR" = "Europe", "GG" = "Europe",
    "HU" = "Europe", "IS" = "Europe", "IE" = "Europe", "IM" = "Europe",
    "IT" = "Europe", "JE" = "Europe", "XK" = "Europe", "LV" = "Europe",
    "LI" = "Europe", "LT" = "Europe", "LU" = "Europe", "MK" = "Europe",
    "MT" = "Europe", "MD" = "Europe", "MC" = "Europe", "ME" = "Europe",
    "NL" = "Europe", "NO" = "Europe", "PL" = "Europe", "PT" = "Europe",
    "RO" = "Europe", "RU" = "Europe", "SM" = "Europe", "RS" = "Europe",
    "SK" = "Europe", "SI" = "Europe", "ES" = "Europe", "SJ" = "Europe",
    "SE" = "Europe", "CH" = "Europe", "UA" = "Europe", "GB" = "Europe",
    "VA" = "Europe",

    # North America
    "AI" = "North America", "AG" = "North America", "AW" = "North America",
    "BS" = "North America", "BB" = "North America", "BZ" = "North America",
    "BM" = "North America", "BQ" = "North America", "CA" = "North America",
    "KY" = "North America", "CR" = "North America", "CU" = "North America",
    "CW" = "North America", "DM" = "North America", "DO" = "North America",
    "SV" = "North America", "GL" = "North America", "GD" = "North America",
    "GP" = "North America", "GT" = "North America", "HT" = "North America",
    "HN" = "North America", "JM" = "North America", "MQ" = "North America",
    "MX" = "North America", "MS" = "North America", "NI" = "North America",
    "PA" = "North America", "PM" = "North America", "PR" = "North America",
    "BL" = "North America", "KN" = "North America", "LC" = "North America",
    "MF" = "North America", "VC" = "North America", "SX" = "North America",
    "TT" = "North America", "TC" = "North America", "US" = "North America",
    "VG" = "North America", "VI" = "North America",

    # South America
    "AR" = "South America", "BO" = "South America", "BR" = "South America",
    "CL" = "South America", "CO" = "South America", "EC" = "South America",
    "FK" = "South America", "GF" = "South America", "GY" = "South America",
    "PY" = "South America", "PE" = "South America", "SR" = "South America",
    "UY" = "South America", "VE" = "South America",

    # Oceania
    "AS" = "Oceania", "AU" = "Oceania", "CK" = "Oceania", "FJ" = "Oceania",
    "PF" = "Oceania", "GU" = "Oceania", "KI" = "Oceania", "MH" = "Oceania",
    "FM" = "Oceania", "NR" = "Oceania", "NC" = "Oceania", "NZ" = "Oceania",
    "NU" = "Oceania", "NF" = "Oceania", "MP" = "Oceania", "PW" = "Oceania",
    "PG" = "Oceania", "PN" = "Oceania", "WS" = "Oceania", "SB" = "Oceania",
    "TK" = "Oceania", "TO" = "Oceania", "TV" = "Oceania", "VU" = "Oceania",
    "WF" = "Oceania",

    # Antarctica
    "AQ" = "Antarctica", "BV" = "Antarctica", "GS" = "Antarctica",
    "HM" = "Antarctica", "TF" = "Antarctica"
  )

  # Map the ISO2 codes to continents
  continents <- continent_map[iso2]

  # Replace NA with "Unknown"
  continents[is.na(continents)] <- "Unknown"

  return(as.character(continents))
}

#' Download and process SimpleMaps World Cities Database
#'
#' @param max_cities Maximum number of cities to return (sorted by population)
#' @return Data.frame with city data, or NULL if download fails
#' @keywords internal
#' @noRd
download_simplemaps <- function(max_cities = 10000) {
  message("Downloading SimpleMaps World Cities Database...")

  tryCatch({
    # SimpleMaps basic (free) version
    url <- "https://simplemaps.com/static/data/world-cities/basic/simplemaps_worldcities_basicv1.77.zip"
    temp_zip <- tempfile(fileext = ".zip")
    temp_dir <- tempdir()

    download.file(url, temp_zip, mode = "wb", quiet = FALSE)
    unzip(temp_zip, exdir = temp_dir)

    # Find the CSV file
    csv_file <- list.files(temp_dir, pattern = "worldcities\\.csv$", full.names = TRUE)[1]

    if (is.na(csv_file)) {
      stop("Could not find worldcities.csv in downloaded archive")
    }

    # Read and process
    cities_raw <- read.csv(csv_file, stringsAsFactors = FALSE)

    # Standardize column names
    cities <- data.frame(
      city = cities_raw$city,
      lat = cities_raw$lat,
      lon = cities_raw$lng,
      country = cities_raw$country,
      iso2 = cities_raw$iso2,
      iso3 = cities_raw$iso3,
      admin_name = cities_raw$admin_name,
      population = as.numeric(cities_raw$population),
      stringsAsFactors = FALSE
    )

    # Add continent based on ISO2 code
    cities$continent <- map_country_to_continent(cities$iso2)

    # Filter to cities with population data and sort
    cities <- cities[!is.na(cities$population) & cities$population > 0, ]
    cities <- cities[order(cities$population, decreasing = TRUE), ]

    # Take top N
    cities <- head(cities, max_cities)

    message(sprintf("SimpleMaps: Successfully loaded %d cities", nrow(cities)))
    return(cities)

  }, error = function(e) {
    message(sprintf("SimpleMaps download failed: %s", e$message))
    return(NULL)
  })
}

#' Download and process GeoNames Cities
#'
#' @param max_cities Maximum number of cities to return (sorted by population)
#' @return Data.frame with city data, or NULL if download fails
#' @keywords internal
#' @noRd
download_geonames <- function(max_cities = 10000) {
  message("Downloading GeoNames Cities Database...")

  tryCatch({
    # Use cities1000 (cities with population > 1000)
    # For larger dataset, use cities5000 or cities15000
    url <- "https://download.geonames.org/export/dump/cities1000.zip"
    temp_zip <- tempfile(fileext = ".zip")
    temp_dir <- tempdir()

    download.file(url, temp_zip, mode = "wb", quiet = FALSE)
    unzip(temp_zip, exdir = temp_dir)

    txt_file <- file.path(temp_dir, "cities1000.txt")

    # GeoNames format: tab-delimited, no header
    # Columns: geonameid, name, asciiname, alternatenames, lat, lon, feature_class,
    #          feature_code, country_code, cc2, admin1, admin2, admin3, admin4,
    #          population, elevation, dem, timezone, modification_date
    cities_raw <- read.delim(txt_file, header = FALSE, stringsAsFactors = FALSE,
                             quote = "", sep = "\t")

    # Also download country info for ISO3 codes
    country_url <- "https://download.geonames.org/export/dump/countryInfo.txt"
    country_file <- tempfile()
    download.file(country_url, country_file, quiet = TRUE)

    # Read country info (skip comments)
    country_lines <- readLines(country_file)
    country_lines <- country_lines[!grepl("^#", country_lines)]
    country_df <- read.delim(textConnection(country_lines), header = FALSE,
                             stringsAsFactors = FALSE)
    country_map <- setNames(country_df$V1, country_df$V5)  # ISO3 by ISO2

    # Standardize column names
    cities <- data.frame(
      city = cities_raw$V2,  # name
      lat = as.numeric(cities_raw$V5),
      lon = as.numeric(cities_raw$V6),
      country = cities_raw$V9,  # Will need to map to full names
      iso2 = cities_raw$V9,
      iso3 = country_map[cities_raw$V9],
      admin_name = cities_raw$V11,  # admin1
      population = as.numeric(cities_raw$V15),
      stringsAsFactors = FALSE
    )

    # Add continent based on ISO2 code
    cities$continent <- map_country_to_continent(cities$iso2)

    # Filter and sort
    cities <- cities[!is.na(cities$population) & cities$population > 0, ]
    cities <- cities[order(cities$population, decreasing = TRUE), ]

    # Take top N
    cities <- head(cities, max_cities)

    message(sprintf("GeoNames: Successfully loaded %d cities", nrow(cities)))
    return(cities)

  }, error = function(e) {
    message(sprintf("GeoNames download failed: %s", e$message))
    return(NULL)
  })
}

#' Download and process Natural Earth Populated Places
#'
#' @param max_cities Maximum number of cities to return (sorted by population)
#' @return Data.frame with city data, or NULL if download fails
#' @keywords internal
#' @noRd
download_naturalearth <- function(max_cities = 10000) {
  message("Downloading Natural Earth Populated Places...")

  tryCatch({
    # Check if sf is available
    if (!requireNamespace("sf", quietly = TRUE)) {
      stop("Package 'sf' required for Natural Earth data")
    }

    # Natural Earth populated places (simple, medium scale)
    url <- "https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_populated_places_simple.zip"
    temp_zip <- tempfile(fileext = ".zip")
    temp_dir <- tempdir()

    download.file(url, temp_zip, mode = "wb", quiet = FALSE)
    unzip(temp_zip, exdir = temp_dir)

    # Find shapefile
    shp_file <- list.files(temp_dir, pattern = "\\.shp$", full.names = TRUE)[1]

    # Read with sf
    cities_sf <- sf::st_read(shp_file, quiet = TRUE)

    # Extract coordinates
    coords <- sf::st_coordinates(cities_sf)

    # Standardize column names
    cities <- data.frame(
      city = cities_sf$name,
      lat = coords[, 2],
      lon = coords[, 1],
      country = cities_sf$sov0name,
      iso2 = cities_sf$iso_a2,
      iso3 = cities_sf$adm0_a3,
      admin_name = cities_sf$adm1name,
      population = as.numeric(cities_sf$pop_max),
      stringsAsFactors = FALSE
    )

    # Add continent based on ISO2 code
    cities$continent <- map_country_to_continent(cities$iso2)

    # Filter and sort
    cities <- cities[!is.na(cities$population) & cities$population > 0, ]
    cities <- cities[order(cities$population, decreasing = TRUE), ]

    # Take top N
    cities <- head(cities, max_cities)

    message(sprintf("Natural Earth: Successfully loaded %d cities", nrow(cities)))
    return(cities)

  }, error = function(e) {
    message(sprintf("Natural Earth download failed: %s", e$message))
    return(NULL)
  })
}
