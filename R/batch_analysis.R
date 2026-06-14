# Batch analysis functions for multiple cities

#' Rank cities by population within specified radius
#'
#' This is the main function for the package's core use case: ranking global cities
#' by how much population they have N kilometers from their city center.
#' Inspired by Tom Forth's Circle Populations website.
#'
#' @param cities Data.frame containing city information (default NULL loads built-in world_cities).
#'   Must have columns for latitude and longitude (see \code{lat_col} and \code{lon_col} parameters).
#'   Optionally include \code{city}, \code{country}, and \code{continent} columns.
#' @param radius_km Numeric radius in kilometers (default 30)
#' @param lat_col Character name of latitude column (default "lat")
#' @param lon_col Character name of longitude column (default "lon")
#' @param city_col Character name of city name column (default "city")
#' @param top_n Integer number of top cities to return (default 2000). Set to NULL to return all cities.
#' @param year Numeric year (default 2025)
#' @param resolution Character, one of "100m", "1km" (default), "3ss", or "30ss".
#'   See \code{\link{download_ghspop_data}} for details on each resolution option.
#'   Default "1km" provides good balance of speed and accuracy.
#' @param deduplicate_km Numeric distance in km to deduplicate nearby cities (default 40).
#'   Cities within this distance are considered duplicates; only the first/largest is kept.
#'   Set to 0 or NULL to disable deduplication. Increase to 30-50km for large metro areas.
#' @param progress Logical whether to show progress messages (default TRUE)
#' @return Data.frame with columns: rank, city (if available), country (if available in input),
#'   continent (if available in input), lat, lon, population_in_radius, sorted by population descending
#' @export
#' @examples
#' \dontrun{
#' # Simplest usage - uses all defaults (30km radius, 1km resolution, top 2000)
#' top_cities <- rank_cities_by_population()
#'
#' # Rank top 50 cities by population within 50km
#' top_50 <- rank_cities_by_population(radius_km = 50, top_n = 50)
#'
#' # Get all cities (no limit) at 25km radius
#' all_cities_25km <- rank_cities_by_population(radius_km = 25, top_n = NULL)
#'
#' # Disable deduplication to keep all cities including nearby duplicates
#' with_duplicates <- rank_cities_by_population(deduplicate_km = 0)
#'
#' # Use custom city dataset
#' my_cities <- data.frame(
#'   name = c("London", "Paris", "Berlin"),
#'   latitude = c(51.5074, 48.8566, 52.5200),
#'   longitude = c(-0.1278, 2.3522, 13.4050)
#' )
#' rank_cities_by_population(
#'   cities = my_cities,
#'   lat_col = "latitude",
#'   lon_col = "longitude",
#'   city_col = "name"
#' )
#' }
rank_cities_by_population <- function(cities = NULL,
                                       radius_km = 30,
                                       lat_col = "lat",
                                       lon_col = "lon",
                                       city_col = "city",
                                       top_n = 2000,
                                       year = 2025,
                                       resolution = "1km",
                                       deduplicate_km = 40,
                                       progress = TRUE) {
  # Load built-in cities if not provided
  if (is.null(cities)) {
    cities <- load_world_cities()
  }

  # Validate inputs
  check_radius(radius_km)
  validate_year(year)

  if (!is.data.frame(cities)) {
    stop("cities must be a data.frame", call. = FALSE)
  }

  if (!(lat_col %in% names(cities))) {
    stop("Column '", lat_col, "' not found in cities data.frame", call. = FALSE)
  }

  if (!(lon_col %in% names(cities))) {
    stop("Column '", lon_col, "' not found in cities data.frame", call. = FALSE)
  }

  # Get coordinates
  lats <- cities[[lat_col]]
  lons <- cities[[lon_col]]

  validate_coordinates(lats, lons)

  # Deduplicate nearby cities if requested
  if (!is.null(deduplicate_km) && deduplicate_km > 0) {
    if (progress) {
      message(sprintf("Checking for duplicate cities within %g km...", deduplicate_km))
    }

    # Sort by population (if available) to keep largest city in each cluster
    if ("population" %in% names(cities)) {
      sort_order <- order(cities$population, decreasing = TRUE, na.last = TRUE)
      cities <- cities[sort_order, ]
      lats <- cities[[lat_col]]
      lons <- cities[[lon_col]]
    }

    # Use sf for fast spatial operations
    if (!requireNamespace("sf", quietly = TRUE)) {
      stop("Package 'sf' is required for deduplication", call. = FALSE)
    }

    # Create sf points
    points <- lapply(seq_len(nrow(cities)), function(i) {
      sf::st_point(c(lons[i], lats[i]))
    })
    points_sf <- sf::st_sfc(points, crs = 4326)
    cities_sf <- sf::st_sf(
      idx = seq_len(nrow(cities)),
      geometry = points_sf
    )

    # Use sf to find neighbors within distance
    # Convert km to meters for sf
    neighbors <- sf::st_is_within_distance(cities_sf, dist = deduplicate_km * 1000)

    # Track which cities to keep
    keep <- rep(TRUE, nrow(cities))

    # For each city, mark its neighbors as duplicates (except itself)
    if (progress && nrow(cities) > 1000) {
      message(sprintf("  Processing %d cities...", nrow(cities)))
    }

    for (i in seq_len(nrow(cities))) {
      if (!keep[i]) next  # Already marked as duplicate

      # Show progress every 1000 cities for large datasets
      if (progress && nrow(cities) > 1000 && i %% 1000 == 0) {
        message(sprintf("    Processed %d/%d cities...", i, nrow(cities)))
      }

      # Get neighbors (excluding self)
      neighbor_indices <- neighbors[[i]]
      neighbor_indices <- neighbor_indices[neighbor_indices != i]

      # Mark all neighbors as duplicates
      if (length(neighbor_indices) > 0) {
        keep[neighbor_indices] <- FALSE
      }
    }

    n_removed <- sum(!keep)
    if (n_removed > 0) {
      cities <- cities[keep, ]
      lats <- cities[[lat_col]]
      lons <- cities[[lon_col]]

      if (progress) {
        message(sprintf("  Removed %d duplicate cities (within %g km of a larger/earlier city)",
                        n_removed, deduplicate_km))
        message(sprintf("  Analyzing %d unique cities", nrow(cities)))
      }
    } else {
      if (progress) {
        message("  No duplicates found")
      }
    }
  }

  # Get city names if available
  has_city_names <- city_col %in% names(cities)
  if (has_city_names) {
    city_names <- cities[[city_col]]
  } else {
    city_names <- paste0("City_", seq_len(nrow(cities)))
  }

  # Get country names if available
  has_country <- "country" %in% names(cities)
  if (has_country) {
    country_names <- cities[["country"]]
  } else {
    country_names <- NULL
  }

  # Get continent names if available
  has_continent <- "continent" %in% names(cities)
  if (has_continent) {
    continent_names <- cities[["continent"]]
  } else {
    continent_names <- NULL
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

  if (progress) {
    message(sprintf("Processing %d cities at %d km radius...", nrow(cities), radius_km))
  }

  # Create all points at once
  if (progress) {
    message("Step 1/3: Creating city point geometries...")
  }

  points <- lapply(seq_len(nrow(cities)), function(i) {
    sf::st_point(c(lons[i], lats[i]))
  })

  points_sf <- sf::st_sfc(points, crs = 4326)

  # Create all buffers
  if (progress) {
    message(sprintf("Step 2/3: Creating %d km radius buffers...", radius_km))
  }

  buffers <- sf::st_buffer(points_sf, dist = radius_km * 1000)

  # Create sf object
  buffers_sf <- sf::st_sf(
    city = city_names,
    lat = lats,
    lon = lons,
    geometry = buffers,
    crs = 4326
  )

  # Transform if needed
  raster_crs <- terra::crs(raster, describe = TRUE)$code
  if (!is.na(raster_crs) && raster_crs != "4326") {
    buffers_sf <- sf::st_transform(buffers_sf, crs = terra::crs(raster))
  }

  # Extract populations for all cities at once
  if (progress) {
    message(sprintf("Step 3/3: Extracting population data for %d cities...", nrow(buffers_sf)))
    message("(This may take several minutes for large datasets)")
  }

  populations <- exactextractr::exact_extract(
    raster,
    buffers_sf,
    fun = "sum",
    progress = progress
  )

  # Create results data.frame
  if (has_country && has_continent) {
    results <- data.frame(
      city = city_names,
      country = country_names,
      continent = continent_names,
      lat = lats,
      lon = lons,
      population_in_radius = as.numeric(populations),
      stringsAsFactors = FALSE
    )
  } else if (has_country) {
    results <- data.frame(
      city = city_names,
      country = country_names,
      lat = lats,
      lon = lons,
      population_in_radius = as.numeric(populations),
      stringsAsFactors = FALSE
    )
  } else if (has_continent) {
    results <- data.frame(
      city = city_names,
      continent = continent_names,
      lat = lats,
      lon = lons,
      population_in_radius = as.numeric(populations),
      stringsAsFactors = FALSE
    )
  } else {
    results <- data.frame(
      city = city_names,
      lat = lats,
      lon = lons,
      population_in_radius = as.numeric(populations),
      stringsAsFactors = FALSE
    )
  }

  # Sort by population descending
  results <- results[order(results$population_in_radius, decreasing = TRUE), ]

  # Add rank
  results$rank <- seq_len(nrow(results))

  # Reorder columns
  if (has_country && has_continent) {
    results <- results[, c("rank", "city", "country", "continent", "lat", "lon", "population_in_radius")]
  } else if (has_country) {
    results <- results[, c("rank", "city", "country", "lat", "lon", "population_in_radius")]
  } else if (has_continent) {
    results <- results[, c("rank", "city", "continent", "lat", "lon", "population_in_radius")]
  } else {
    results <- results[, c("rank", "city", "lat", "lon", "population_in_radius")]
  }

  # Filter to top_n if specified
  if (!is.null(top_n)) {
    if (!is.numeric(top_n) || top_n < 1) {
      stop("top_n must be a positive integer", call. = FALSE)
    }
    results <- results[1:min(top_n, nrow(results)), ]
  }

  # Reset row names
  rownames(results) <- NULL

  if (progress) {
    message(sprintf("\nComplete! Ranked %d cities by population within %d km",
                    nrow(results), radius_km))
  }

  results
}

#' Compare cities across multiple radii
#'
#' Analyzes multiple cities at multiple radii to compare urban agglomeration
#' patterns. Useful for understanding how cities differ in density distribution.
#'
#' @param cities Data.frame containing city information
#' @param radii_km Numeric vector of radii in kilometers
#' @param lat_col Character name of latitude column (default "lat")
#' @param lon_col Character name of longitude column (default "lon")
#' @param city_col Character name of city name column (default "city")
#' @param year Numeric year (default 2025)
#' @param resolution Character, one of "100m" (default), "1km", "3ss", or "30ss".
#'   See \code{\link{download_ghspop_data}} for details on each resolution option.
#' @param progress Logical whether to show progress messages (default TRUE)
#' @return Data.frame with columns: city, lat, lon, radius_km, population
#' @export
#' @examples
#' \dontrun{
#' # Compare major European cities
#' european_cities <- data.frame(
#'   city = c("London", "Paris", "Berlin", "Madrid", "Rome"),
#'   lat = c(51.5074, 48.8566, 52.5200, 40.4168, 41.9028),
#'   lon = c(-0.1278, 2.3522, 13.4050, -3.7038, 12.4964)
#' )
#'
#' comparison <- compare_cities(
#'   cities = european_cities,
#'   radii_km = c(10, 25, 50, 100)
#' )
#'
#' # Visualize with ggplot2
#' library(ggplot2)
#' ggplot(comparison, aes(x = radius_km, y = population, color = city)) +
#'   geom_line() +
#'   geom_point() +
#'   scale_y_log10() +
#'   labs(title = "Population vs Distance from City Center")
#' }
compare_cities <- function(cities,
                          radii_km,
                          lat_col = "lat",
                          lon_col = "lon",
                          city_col = "city",
                          year = 2025,
                          resolution = "100m",
                          progress = TRUE) {
  # Validate inputs
  check_radius(radii_km)
  validate_year(year)

  if (!is.data.frame(cities)) {
    stop("cities must be a data.frame", call. = FALSE)
  }

  if (!(lat_col %in% names(cities))) {
    stop("Column '", lat_col, "' not found in cities data.frame", call. = FALSE)
  }

  if (!(lon_col %in% names(cities))) {
    stop("Column '", lon_col, "' not found in cities data.frame", call. = FALSE)
  }

  # Get city names
  has_city_names <- city_col %in% names(cities)
  if (has_city_names) {
    city_names <- cities[[city_col]]
  } else {
    city_names <- paste0("City_", seq_len(nrow(cities)))
  }

  # Process each city
  results_list <- lapply(seq_len(nrow(cities)), function(i) {
    if (progress) {
      message(sprintf("Processing %s (%d/%d)...", city_names[i], i, nrow(cities)))
    }

    city_results <- population_in_circles(
      lat = cities[[lat_col]][i],
      lon = cities[[lon_col]][i],
      radii_km = radii_km,
      year = year,
      resolution = resolution
    )

    city_results$city <- city_names[i]
    city_results$lat <- cities[[lat_col]][i]
    city_results$lon <- cities[[lon_col]][i]

    city_results
  })

  # Combine results
  results <- do.call(rbind, results_list)

  # Reorder columns
  results <- results[, c("city", "lat", "lon", "radius_km", "population")]

  # Reset row names
  rownames(results) <- NULL

  if (progress) {
    message("Done!")
  }

  results
}

#' Find top cities within a region
#'
#' Filters cities to those within a bounding box, then ranks them by population
#' at specified radius. Useful for regional analysis.
#'
#' @param cities Data.frame containing city information
#' @param radius_km Numeric radius in kilometers
#' @param min_lat Numeric minimum latitude
#' @param max_lat Numeric maximum latitude
#' @param min_lon Numeric minimum longitude
#' @param max_lon Numeric maximum longitude
#' @param lat_col Character name of latitude column (default "lat")
#' @param lon_col Character name of longitude column (default "lon")
#' @param city_col Character name of city name column (default "city")
#' @param top_n Integer number of top cities to return (default NULL returns all)
#' @param year Numeric year (default 2025)
#' @param resolution Character, one of "100m" (default), "1km", "3ss", or "30ss".
#'   See \code{\link{download_ghspop_data}} for details on each resolution option.
#' @return Data.frame with ranked cities in the region
#' @export
#' @examples
#' \dontrun{
#' # Top cities in Western Europe
#' cities <- load_world_cities()
#' western_europe <- top_cities_in_region(
#'   cities = cities,
#'   radius_km = 50,
#'   min_lat = 42, max_lat = 54,
#'   min_lon = -5, max_lon = 15,
#'   top_n = 20
#' )
#' }
top_cities_in_region <- function(cities,
                                  radius_km,
                                  min_lat, max_lat,
                                  min_lon, max_lon,
                                  lat_col = "lat",
                                  lon_col = "lon",
                                  city_col = "city",
                                  top_n = NULL,
                                  year = 2025,
                                  resolution = "100m") {
  # Validate bounds
  validate_coordinates(c(min_lat, max_lat), c(min_lon, max_lon))

  if (min_lat >= max_lat) {
    stop("min_lat must be less than max_lat", call. = FALSE)
  }

  if (min_lon >= max_lon) {
    stop("min_lon must be less than max_lon", call. = FALSE)
  }

  # Filter cities to region
  lats <- cities[[lat_col]]
  lons <- cities[[lon_col]]

  in_region <- lats >= min_lat & lats <= max_lat & lons >= min_lon & lons <= max_lon

  if (sum(in_region) == 0) {
    stop("No cities found within specified region", call. = FALSE)
  }

  cities_subset <- cities[in_region, ]

  message(sprintf("Found %d cities in region", nrow(cities_subset)))

  # Rank filtered cities
  rank_cities_by_population(
    cities = cities_subset,
    radius_km = radius_km,
    lat_col = lat_col,
    lon_col = lon_col,
    city_col = city_col,
    top_n = top_n,
    year = year,
    resolution = resolution
  )
}
