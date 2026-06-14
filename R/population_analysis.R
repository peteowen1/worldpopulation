# Core population analysis functions

#' Calculate population within a circle
#'
#' Calculates the total population within a specified radius around a geographic
#' point using high-resolution GHS-POP data. This is the core function for all
#' population queries.
#'
#' @param lat Numeric latitude in decimal degrees (-90 to 90)
#' @param lon Numeric longitude in decimal degrees (-180 to 180)
#' @param radius_km Numeric radius in kilometers
#' @param year Numeric year (default 2025). Use \code{\link{list_available_years}}
#'   to see available options.
#' @param resolution Character, one of "100m" (default), "1km", "3ss", or "30ss".
#'   See \code{\link{download_ghspop_data}} for details on each resolution option.
#' @return Numeric total population within the circle
#' @export
#' @examples
#' \dontrun{
#' # Population within 50km of London
#' population_in_circle(lat = 51.5074, lon = -0.1278, radius_km = 50)
#'
#' # Population within 25km of Tokyo in 2020
#' population_in_circle(lat = 35.6762, lon = 139.6503, radius_km = 25, year = 2020)
#'
#' # Using 1km resolution for faster processing
#' population_in_circle(lat = 40.7128, lon = -74.0060, radius_km = 30, resolution = "1km")
#' }
population_in_circle <- function(lat, lon, radius_km, year = 2025, resolution = "100m") {
  # Validate inputs
  validate_coordinates(lat, lon)
  check_radius(radius_km)
  validate_year(year)

  # Ensure single values
  if (length(lat) != 1 || length(lon) != 1 || length(radius_km) != 1) {
    stop("lat, lon, and radius_km must be single values. ",
         "For multiple queries, use batch functions.",
         call. = FALSE)
  }

  # Load raster
  raster <- load_ghspop_raster(year = year, resolution = resolution)

  # Check if required packages are available
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required but not installed", call. = FALSE)
  }
  if (!requireNamespace("exactextractr", quietly = TRUE)) {
    stop("Package 'exactextractr' is required but not installed", call. = FALSE)
  }

  # Create point geometry
  point <- sf::st_point(c(lon, lat))
  point_sf <- sf::st_sfc(point, crs = 4326)

  # Create buffer (radius in meters)
  buffer <- sf::st_buffer(point_sf, dist = radius_km * 1000)

  # Transform to raster CRS if needed
  raster_crs <- terra::crs(raster, describe = TRUE)$code

  if (!is.na(raster_crs) && raster_crs != "4326") {
    buffer <- sf::st_transform(buffer, crs = terra::crs(raster))
  }

  # Extract population within buffer
  # exactextractr is much faster and more accurate than terra::extract
  pop_sum <- exactextractr::exact_extract(
    raster,
    buffer,
    fun = "sum",
    progress = FALSE
  )

  # Return total population
  as.numeric(pop_sum)
}

#' Calculate population within multiple radii
#'
#' Calculates population within multiple radii around a single point.
#' More efficient than calling \code{population_in_circle} multiple times.
#'
#' @param lat Numeric latitude in decimal degrees
#' @param lon Numeric longitude in decimal degrees
#' @param radii_km Numeric vector of radii in kilometers
#' @param year Numeric year (default 2025)
#' @param resolution Character, one of "100m" (default), "1km", "3ss", or "30ss".
#'   See \code{\link{download_ghspop_data}} for details on each resolution option.
#' @return Data.frame with columns: radius_km, population
#' @export
#' @examples
#' \dontrun{
#' # Population at multiple distances from Paris
#' population_in_circles(
#'   lat = 48.8566,
#'   lon = 2.3522,
#'   radii_km = c(10, 25, 50, 100)
#' )
#' }
population_in_circles <- function(lat, lon, radii_km, year = 2025, resolution = "100m") {
  # Validate inputs
  validate_coordinates(lat, lon)
  check_radius(radii_km)
  validate_year(year)

  if (length(lat) != 1 || length(lon) != 1) {
    stop("lat and lon must be single values", call. = FALSE)
  }

  # Load raster once
  raster <- load_ghspop_raster(year = year, resolution = resolution)

  # Check packages
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required but not installed", call. = FALSE)
  }
  if (!requireNamespace("exactextractr", quietly = TRUE)) {
    stop("Package 'exactextractr' is required but not installed", call. = FALSE)
  }

  # Create point
  point <- sf::st_point(c(lon, lat))
  point_sf <- sf::st_sfc(point, crs = 4326)

  # Create buffers for all radii
  buffers <- lapply(radii_km, function(r) {
    sf::st_buffer(point_sf, dist = r * 1000)
  })

  # Combine into single sf object
  buffers_sf <- sf::st_sf(
    radius_km = radii_km,
    geometry = do.call(c, buffers),
    crs = 4326
  )

  # Transform if needed
  raster_crs <- terra::crs(raster, describe = TRUE)$code
  if (!is.na(raster_crs) && raster_crs != "4326") {
    buffers_sf <- sf::st_transform(buffers_sf, crs = terra::crs(raster))
  }

  # Extract all at once
  populations <- exactextractr::exact_extract(
    raster,
    buffers_sf,
    fun = "sum",
    progress = FALSE
  )

  # Return results
  data.frame(
    radius_km = radii_km,
    population = as.numeric(populations),
    stringsAsFactors = FALSE
  )
}

#' Calculate population in annular rings
#'
#' Calculates population in concentric rings (annuli) around a point.
#' Each ring represents the population between two radii.
#'
#' @param lat Numeric latitude in decimal degrees
#' @param lon Numeric longitude in decimal degrees
#' @param radii_km Numeric vector of radii defining ring boundaries (in kilometers).
#'   Must be in ascending order. Population is calculated between consecutive radii.
#' @param year Numeric year (default 2025)
#' @param resolution Character, one of "100m" (default), "1km", "3ss", or "30ss".
#'   See \code{\link{download_ghspop_data}} for details on each resolution option.
#' @return Data.frame with columns: inner_radius_km, outer_radius_km, population
#' @export
#' @examples
#' \dontrun{
#' # Population in rings around New York City
#' # 0-10km, 10-25km, 25-50km
#' population_in_rings(
#'   lat = 40.7128,
#'   lon = -74.0060,
#'   radii_km = c(0, 10, 25, 50)
#' )
#' }
population_in_rings <- function(lat, lon, radii_km, year = 2025, resolution = "100m") {
  # Validate inputs
  validate_coordinates(lat, lon)
  check_radius(radii_km[radii_km > 0])  # Don't check 0
  validate_year(year)

  if (length(lat) != 1 || length(lon) != 1) {
    stop("lat and lon must be single values", call. = FALSE)
  }

  if (length(radii_km) < 2) {
    stop("radii_km must contain at least 2 values to define rings", call. = FALSE)
  }

  if (is.unsorted(radii_km)) {
    stop("radii_km must be in ascending order", call. = FALSE)
  }

  if (radii_km[1] != 0) {
    radii_km <- c(0, radii_km)
  }

  # Get cumulative populations
  circles <- population_in_circles(
    lat = lat,
    lon = lon,
    radii_km = radii_km[radii_km > 0],
    year = year,
    resolution = resolution
  )

  # Calculate ring populations by subtraction
  ring_pops <- diff(c(0, circles$population))

  # Create result data.frame
  result <- data.frame(
    inner_radius_km = radii_km[-length(radii_km)],
    outer_radius_km = radii_km[-1],
    population = ring_pops,
    stringsAsFactors = FALSE
  )

  result
}

#' Calculate population density profile
#'
#' Calculates average population density at various distances from a point.
#' Useful for understanding how density decays with distance from city center.
#'
#' @param lat Numeric latitude in decimal degrees
#' @param lon Numeric longitude in decimal degrees
#' @param radii_km Numeric vector of radii (in kilometers)
#' @param year Numeric year (default 2025)
#' @param resolution Character, one of "100m" (default), "1km", "3ss", or "30ss".
#'   See \code{\link{download_ghspop_data}} for details on each resolution option.
#' @return Data.frame with columns: radius_km, population, area_km2, density_per_km2
#' @export
#' @examples
#' \dontrun{
#' # Density profile for Mumbai
#' density_profile <- population_density_profile(
#'   lat = 19.0760,
#'   lon = 72.8777,
#'   radii_km = seq(5, 50, by = 5)
#' )
#' }
population_density_profile <- function(lat, lon, radii_km, year = 2025, resolution = "100m") {
  # Get ring populations
  if (!0 %in% radii_km) {
    radii_km <- c(0, radii_km)
  }

  rings <- population_in_rings(
    lat = lat,
    lon = lon,
    radii_km = radii_km,
    year = year,
    resolution = resolution
  )

  # Calculate ring areas (area of annulus)
  rings$area_km2 <- pi * (rings$outer_radius_km^2 - rings$inner_radius_km^2)

  # Calculate density
  rings$density_per_km2 <- rings$population / rings$area_km2

  rings
}
