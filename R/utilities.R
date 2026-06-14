# Utility functions for validation and helpers

#' Validate geographic coordinates
#'
#' @param lat Numeric latitude value(s)
#' @param lon Numeric longitude value(s)
#' @return Logical indicating if coordinates are valid
#' @keywords internal
#' @noRd
validate_coordinates <- function(lat, lon) {
  if (!is.numeric(lat) || !is.numeric(lon)) {
    stop("Latitude and longitude must be numeric values", call. = FALSE)
  }

  if (any(is.na(lat)) || any(is.na(lon))) {
    stop("Latitude and longitude cannot contain NA values", call. = FALSE)
  }

  if (any(lat < -90 | lat > 90)) {
    stop("Latitude must be between -90 and 90 degrees", call. = FALSE)
  }

  if (any(lon < -180 | lon > 180)) {
    stop("Longitude must be between -180 and 180 degrees", call. = FALSE)
  }

  TRUE
}

#' Check radius and issue warnings if needed
#'
#' @param radius_km Numeric radius in kilometers
#' @return Invisible TRUE
#' @keywords internal
#' @noRd
check_radius <- function(radius_km) {
  if (!is.numeric(radius_km) || any(is.na(radius_km))) {
    stop("Radius must be a numeric value", call. = FALSE)
  }

  if (any(radius_km <= 0)) {
    stop("Radius must be greater than 0", call. = FALSE)
  }

  # Warning for very small radii (< 0.5 km)
  if (any(radius_km < 0.5)) {
    warning(
      "Radius < 0.5 km may be less accurate due to 100m pixel resolution. ",
      "Results represent population in approximately 1-2 pixels.",
      call. = FALSE
    )
  }

  # Warning for very large radii (> 100 km)
  if (any(radius_km > 100)) {
    warning(
      "Radius > 100 km may take longer to process and may exceed typical ",
      "urban agglomeration sizes. Consider whether such a large radius is needed.",
      call. = FALSE
    )
  }

  # Warning for extremely large radii (> 500 km)
  if (any(radius_km > 500)) {
    warning(
      "Radius > 500 km is very large and will take significant time to process. ",
      "Results may be more representative of regional population than urban area.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Validate year parameter
#'
#' @param year Numeric year value
#' @return Invisible TRUE
#' @keywords internal
#' @noRd
validate_year <- function(year) {
  valid_years <- c(1975, 1980, 1985, 1990, 1995, 2000, 2005, 2010, 2015, 2020, 2025, 2030)

  if (!is.numeric(year) || length(year) != 1) {
    stop("Year must be a single numeric value", call. = FALSE)
  }

  if (!(year %in% valid_years)) {
    stop(
      "Year must be one of: ", paste(valid_years, collapse = ", "), "\n",
      "Use list_available_years() to see available datasets.",
      call. = FALSE
    )
  }

  if (year >= 2025) {
    message("Note: Year ", year, " is a projection, not census data.")
  }

  invisible(TRUE)
}

#' Estimate download size for GHS-POP data
#'
#' @param resolution Character, one of: "100m", "1km", "3ss", "30ss"
#' @param year Numeric year
#' @return Character describing file size
#' @export
#' @examples
#' \dontrun{
#' estimate_download_size("100m", 2025)
#' estimate_download_size("30ss", 2020)
#' estimate_download_size("3ss", 2025)
#' }
estimate_download_size <- function(resolution = "100m", year = 2025) {
  validate_year(year)

  size_info <- list(
    "100m" = "~5 GB (100m Mollweide, highest accuracy, equal-area)",
    "1km"  = "~300 MB (1km Mollweide, good accuracy, equal-area)",
    "3ss"  = "~12 GB (3 arc-second WGS84, very high resolution)",
    "30ss" = "~480 MB (30 arc-second WGS84, fast download)"
  )

  if (!(resolution %in% names(size_info))) {
    stop("Resolution must be one of: ", paste(names(size_info), collapse = ", "),
         call. = FALSE)
  }

  message("Download size for ", resolution, " resolution, year ", year, ":")
  message("  ", size_info[[resolution]])

  invisible(size_info[[resolution]])
}

#' Format large numbers for display
#'
#' @param x Numeric value(s)
#' @param digits Number of significant digits for rounding
#' @return Character vector of formatted numbers
#' @keywords internal
#' @noRd
format_population <- function(x, digits = 3) {
  ifelse(
    x >= 1e6,
    paste0(round(x / 1e6, digits), "M"),
    ifelse(
      x >= 1e3,
      paste0(round(x / 1e3, digits), "K"),
      as.character(round(x, 0))
    )
  )
}

#' Get package data directory
#'
#' Returns the directory where worldpopulation stores downloaded GHS-POP data.
#' Data is stored in ~/Documents/worldpopulation_data (or ~/worldpopulation_data
#' if Documents folder doesn't exist). On first use, this directory will be
#' created if it doesn't exist.
#'
#' @return Character path to data directory
#' @export
#' @examples
#' get_cache_dir()
get_cache_dir <- function() {
  # Try Documents folder first (most common location)
  docs_path <- path.expand("~/Documents")

  if (dir.exists(docs_path)) {
    data_dir <- file.path(docs_path, "worldpopulation_data")
  } else {
    # Fall back to home directory if Documents doesn't exist
    data_dir <- path.expand("~/worldpopulation_data")
  }

  if (!dir.exists(data_dir)) {
    dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
    message("Created data directory: ", data_dir)
    message("GHS-POP files (~4.8 GB) will be stored here.")
  }

  data_dir
}

#' Clear GHS-POP data
#'
#' Removes all GHS-POP raster files from the worldpopulation_data directory.
#' This can free up several GB of disk space.
#'
#' @param ask Logical, whether to ask for confirmation before deleting
#' @return Invisible NULL
#' @export
#' @examples
#' \dontrun{
#' # Clear cache with confirmation
#' clear_cache()
#'
#' # Clear cache without confirmation
#' clear_cache(ask = FALSE)
#' }
clear_cache <- function(ask = TRUE) {
  data_dir <- get_cache_dir()
  files <- list.files(data_dir, pattern = "\\.tif$", full.names = TRUE)

  if (length(files) == 0) {
    message("No GHS-POP files found.")
    return(invisible(NULL))
  }

  total_size <- sum(file.size(files)) / 1024^3  # Size in GB

  if (ask) {
    response <- readline(
      prompt = sprintf(
        "This will delete %d GHS-POP file(s) (%.2f GB) from:\n  %s\nContinue? (y/n): ",
        length(files), total_size, data_dir
      )
    )
    if (tolower(response) != "y") {
      message("Files not deleted.")
      return(invisible(NULL))
    }
  }

  file.remove(files)

  # Also clear any cached rasters from package environment
  pkg_env <- get_pkg_env()
  rm(list = ls(pkg_env), envir = pkg_env)

  message(sprintf("Deleted %d file(s) (%.2f GB)", length(files), total_size))
  invisible(NULL)
}

#' Get information about stored GHS-POP data
#'
#' @return Data.frame with information about stored files
#' @export
#' @examples
#' cache_info()
cache_info <- function() {
  data_dir <- get_cache_dir()
  files <- list.files(data_dir, pattern = "\\.tif$", full.names = TRUE)

  if (length(files) == 0) {
    message("No GHS-POP files found in: ", data_dir)
    return(invisible(NULL))
  }

  info <- data.frame(
    file = basename(files),
    size_mb = round(file.size(files) / 1024^2, 2),
    modified = file.mtime(files),
    stringsAsFactors = FALSE
  )

  message("Data directory: ", data_dir)
  message(sprintf("Total: %d file(s), %.2f GB",
                  nrow(info), sum(info$size_mb) / 1024))

  info
}
