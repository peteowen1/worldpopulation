# Functions for accessing built-in city data

#' World Cities Dataset
#'
#' A dataset containing information about 1000 major world cities including
#' coordinates, country codes, and population estimates. This dataset provides
#' a convenient starting point for analyzing global urban populations.
#'
#' @format A data frame with 1000 rows and 8 variables:
#' \describe{
#'   \item{city}{City name}
#'   \item{lat}{Latitude in decimal degrees}
#'   \item{lon}{Longitude in decimal degrees}
#'   \item{country}{Country name}
#'   \item{iso2}{ISO 3166-1 alpha-2 country code}
#'   \item{iso3}{ISO 3166-1 alpha-3 country code}
#'   \item{admin_name}{Administrative division name (state/province)}
#'   \item{population}{Metropolitan area population estimate}
#' }
#' @source Compiled from multiple public domain sources including Natural Earth,
#'   GeoNames, and national statistical agencies. Population estimates are
#'   approximate metropolitan area figures.
#'
#' @examples
#' # Load the dataset
#' data(world_cities)
#'
#' # View structure
#' str(world_cities)
#'
#' # Top 10 cities by population
#' head(world_cities[order(world_cities$population, decreasing = TRUE), ], 10)
"world_cities"

#' Load world cities dataset
#'
#' Loads the built-in dataset of 1000 major world cities. This dataset includes
#' city names, coordinates, country codes, and population estimates from
#' SimpleMaps World Cities Database (or fallback sources).
#'
#' @return Data.frame with columns:
#' \describe{
#'   \item{city}{City name}
#'   \item{lat}{Latitude in decimal degrees}
#'   \item{lon}{Longitude in decimal degrees}
#'   \item{country}{Country name}
#'   \item{iso2}{ISO 3166-1 alpha-2 country code}
#'   \item{iso3}{ISO 3166-1 alpha-3 country code}
#'   \item{admin_name}{Admin division name (state/province)}
#'   \item{population}{City population estimate}
#' }
#' @export
#' @examples
#' # Load all cities
#' cities <- load_world_cities()
#'
#' # View first few rows
#' head(cities)
#'
#' # Filter to specific country
#' uk_cities <- cities[cities$iso2 == "GB", ]
#'
#' # Filter to large cities (>1 million)
#' major_cities <- cities[cities$population > 1e6, ]
load_world_cities <- function() {
  # Load from package data
  # The dataset will be created in data-raw/cities.R and saved to data/world_cities.rda

  if (!exists("world_cities")) {
    # Try to load the data
    data("world_cities", package = "worldpopulation", envir = environment())
  }

  world_cities
}

#' Filter cities by country
#'
#' Convenience function to filter the world cities dataset by country.
#'
#' @param country_code Character ISO 2 or ISO 3 country code(s), or country name(s)
#' @return Data.frame of filtered cities
#' @export
#' @examples
#' # Get US cities
#' us_cities <- filter_cities_by_country("US")
#'
#' # Get multiple countries
#' europe <- filter_cities_by_country(c("GB", "FR", "DE", "IT", "ES"))
#'
#' # By country name
#' japan_cities <- filter_cities_by_country("Japan")
filter_cities_by_country <- function(country_code) {
  cities <- load_world_cities()

  # Check which column to match against
  matches <- cities$iso2 %in% country_code |
             cities$iso3 %in% country_code |
             cities$country %in% country_code

  if (sum(matches) == 0) {
    warning("No cities found for specified country code(s)", call. = FALSE)
  }

  cities[matches, ]
}

#' Filter cities by minimum population
#'
#' Convenience function to filter cities by population threshold.
#'
#' @param min_population Numeric minimum population
#' @return Data.frame of filtered cities
#' @export
#' @examples
#' # Cities over 1 million
#' major_cities <- filter_cities_by_population(1e6)
#'
#' # Cities over 500k
#' large_cities <- filter_cities_by_population(500000)
filter_cities_by_population <- function(min_population) {
  cities <- load_world_cities()

  if (!is.numeric(min_population) || min_population < 0) {
    stop("min_population must be a positive number", call. = FALSE)
  }

  filtered <- cities[cities$population >= min_population, ]

  if (nrow(filtered) == 0) {
    warning("No cities found with population >= ", min_population, call. = FALSE)
  }

  filtered
}

#' Get top N cities by population
#'
#' Returns the N largest cities by population estimate.
#'
#' @param n Integer number of cities to return
#' @return Data.frame of top N cities sorted by population
#' @export
#' @examples
#' # Top 100 cities by population
#' top_100 <- get_top_cities(100)
#'
#' # Top 50 cities
#' top_50 <- get_top_cities(50)
get_top_cities <- function(n = 100) {
  cities <- load_world_cities()

  if (!is.numeric(n) || n < 1) {
    stop("n must be a positive integer", call. = FALSE)
  }

  # Sort by population descending
  cities_sorted <- cities[order(cities$population, decreasing = TRUE), ]

  # Return top n
  cities_sorted[1:min(n, nrow(cities_sorted)), ]
}
