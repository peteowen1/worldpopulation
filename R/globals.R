# Global variables and package environment

# Package environment for caching loaded rasters
.pkg_env <- new.env(parent = emptyenv())

#' Get package cache environment
#' @keywords internal
#' @noRd
get_pkg_env <- function() {
  .pkg_env
}

# Prevent R CMD check NOTEs about undefined global variables from dplyr/data.table usage
utils::globalVariables(c(
  "city", "lat", "lon", "lng", "latitude", "longitude",
  "country", "continent", "population", "iso2", "iso3",
  "radius_km", "population_in_radius", "rank",
  "world_cities",
  ".", "where"
))
