# Helper functions for calculating distances between cities

#' Calculate distance between two cities
#'
#' Calculates the great circle distance between two geographic points using
#' the Haversine formula. Useful for checking if cities should be considered
#' duplicates or for general distance queries.
#'
#' @param lat1 Latitude of first point (decimal degrees)
#' @param lon1 Longitude of first point (decimal degrees)
#' @param lat2 Latitude of second point (decimal degrees)
#' @param lon2 Longitude of second point (decimal degrees)
#' @return Numeric distance in kilometers
#' @export
#' @examples
#' # Distance between Delhi and Delhi Cantonment
#' city_distance(28.61, 77.23, 28.60, 77.13)
#'
#' # Distance between London and Paris
#' city_distance(51.5074, -0.1278, 48.8566, 2.3522)
city_distance <- function(lat1, lon1, lat2, lon2) {
  # Validate coordinates
  validate_coordinates(c(lat1, lat2), c(lon1, lon2))

  # Calculate distance using geosphere
  if (!requireNamespace("geosphere", quietly = TRUE)) {
    stop("Package 'geosphere' is required but not installed", call. = FALSE)
  }

  dist_m <- geosphere::distGeo(c(lon1, lat1), c(lon2, lat2))
  dist_km <- dist_m / 1000

  return(dist_km)
}

#' Find cities within a specified distance of a target city
#'
#' Searches a cities dataset to find all cities within a specified distance
#' of a target city. Useful for identifying potential duplicates or nearby cities.
#'
#' @param cities Data.frame containing city information
#' @param target_lat Latitude of target city (decimal degrees)
#' @param target_lon Longitude of target city (decimal degrees)
#' @param max_distance_km Maximum distance in kilometers
#' @param lat_col Character name of latitude column (default "lat")
#' @param lon_col Character name of longitude column (default "lon")
#' @param city_col Character name of city name column (default "city")
#' @return Data.frame with nearby cities and their distances, sorted by distance
#' @export
#' @examples
#' \dontrun{
#' cities <- load_world_cities()
#'
#' # Find all cities within 20km of Delhi
#' nearby <- find_nearby_cities(
#'   cities,
#'   target_lat = 28.61,
#'   target_lon = 77.23,
#'   max_distance_km = 20
#' )
#' }
find_nearby_cities <- function(cities,
                               target_lat,
                               target_lon,
                               max_distance_km,
                               lat_col = "lat",
                               lon_col = "lon",
                               city_col = "city") {
  # Validate inputs
  if (!is.data.frame(cities)) {
    stop("cities must be a data.frame", call. = FALSE)
  }

  validate_coordinates(target_lat, target_lon)

  if (!(lat_col %in% names(cities))) {
    stop("Column '", lat_col, "' not found in cities data.frame", call. = FALSE)
  }

  if (!(lon_col %in% names(cities))) {
    stop("Column '", lon_col, "' not found in cities data.frame", call. = FALSE)
  }

  # Get coordinates
  lats <- cities[[lat_col]]
  lons <- cities[[lon_col]]

  # Check if geosphere is available
  if (!requireNamespace("geosphere", quietly = TRUE)) {
    stop("Package 'geosphere' is required but not installed", call. = FALSE)
  }

  # Calculate distances to all cities
  distances_km <- sapply(seq_len(nrow(cities)), function(i) {
    dist_m <- geosphere::distGeo(c(target_lon, target_lat), c(lons[i], lats[i]))
    dist_m / 1000
  })

  # Filter to those within max distance
  nearby_idx <- which(distances_km <= max_distance_km)

  if (length(nearby_idx) == 0) {
    message("No cities found within ", max_distance_km, " km")
    return(data.frame())
  }

  # Create result dataframe
  result <- cities[nearby_idx, ]
  result$distance_km <- distances_km[nearby_idx]

  # Sort by distance
  result <- result[order(result$distance_km), ]

  # Reset row names
  rownames(result) <- NULL

  return(result)
}
