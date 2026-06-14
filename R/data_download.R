# Functions for downloading and caching GHS-POP data

#' List available years for GHS-POP data
#'
#' Shows the years for which Global Human Settlement Layer Population data
#' is available, including both historical census data and future projections.
#'
#' @return Numeric vector of available years
#' @export
#' @examples
#' list_available_years()
list_available_years <- function() {
  years <- c(1975, 1980, 1985, 1990, 1995, 2000, 2005, 2010, 2015, 2020, 2025, 2030)

  message("Available GHS-POP years:")
  message("  Census data: 1975-2020 (every 5 years)")
  message("  Projections: 2025, 2030")
  message("\nRecommended: 2020 (most recent census) or 2025 (current projection)")

  invisible(years)
}

#' Download GHS-POP raster data
#'
#' Downloads Global Human Settlement Layer Population raster data from the
#' European Commission Joint Research Centre and caches it locally for future use.
#' This is a one-time setup step required before using population analysis functions.
#'
#' @param year Numeric year (1975, 1980, 1985, 1990, 1995, 2000, 2005, 2010, 2015,
#'   2020, 2025, 2030). Default is 2025.
#' @param resolution Character, one of:
#'   \itemize{
#'     \item "100m" (default, ~5 GB) - 100m Mollweide, highest accuracy, equal-area
#'     \item "1km" (~300 MB) - 1km Mollweide, good accuracy, equal-area
#'     \item "3ss" (~12 GB) - 3 arc-second WGS84, very high resolution
#'     \item "30ss" (~480 MB) - 30 arc-second WGS84, fast download
#'   }
#'   See Details for explanation of Mollweide vs WGS84.
#' @param overwrite Logical, whether to re-download if file already exists
#' @return Character path to downloaded file (invisibly)
#'
#' @details
#' \strong{Choosing a Resolution:}
#'
#' \strong{Mollweide Projection (100m, 1km):}
#' \itemize{
#'   \item Equal-area projection - pixel areas are consistent globally
#'   \item Best for population totals and area-based analysis
#'   \item Shapes are distorted, especially near poles
#'   \item Requires CRS transformation from lat/lon (handled automatically)
#' }
#'
#' \strong{WGS84 Lat/Lon (3ss, 30ss):}
#' \itemize{
#'   \item Standard geographic coordinates (latitude/longitude)
#'   \item No reprojection needed when working with lat/lon coordinates
#'   \item Pixel ground distance varies by latitude:
#'     - 30ss at equator ≈ 930m, at 60° ≈ 465m
#'     - 3ss at equator ≈ 93m, at 60° ≈ 46m
#'   \item Pixel areas are NOT equal (larger near equator)
#' }
#'
#' \strong{Recommendation:}
#' \itemize{
#'   \item For most users: Start with "30ss" (fast, 480 MB)
#'   \item For high accuracy: Use "100m" (5 GB, equal-area)
#'   \item For very detailed analysis: Use "3ss" (12 GB, but large!)
#'   \item For quick testing: Use "1km" (300 MB, equal-area)
#' }
#'
#' \strong{Download Performance:}
#'
#' The function automatically sets a 10-minute timeout to handle large files.
#' If download fails due to slow connection, try again or use a smaller resolution.
#'
#' @export
#' @examples
#' \dontrun{
#' # Download 100m resolution data for 2025 (default, Mollweide)
#' download_ghspop_data()
#'
#' # Download fast 30 arc-second data (WGS84)
#' download_ghspop_data(year = 2025, resolution = "30ss")
#'
#' # Download 1km Mollweide data for 2020
#' download_ghspop_data(year = 2020, resolution = "1km")
#'
#' # Download very high resolution 3 arc-second (large!)
#' download_ghspop_data(year = 2025, resolution = "3ss")
#' }
download_ghspop_data <- function(year = 2025, resolution = "100m", overwrite = FALSE) {
  validate_year(year)

  valid_resolutions <- c("100m", "1km", "3ss", "30ss")
  if (!(resolution %in% valid_resolutions)) {
    stop("Resolution must be one of: ", paste(valid_resolutions, collapse = ", "),
         call. = FALSE)
  }

  # Increase timeout for large file downloads
  # Default 60s is too short for multi-GB files
  old_timeout <- getOption("timeout")
  options(timeout = max(600, old_timeout))  # At least 10 minutes
  on.exit(options(timeout = old_timeout), add = TRUE)

  # Construct file path and URL
  cache_dir <- get_cache_dir()
  filename <- sprintf("GHS_POP_%d_%s.tif", year, resolution)
  filepath <- file.path(cache_dir, filename)

  # Check if already exists
  if (file.exists(filepath) && !overwrite) {
    message("File already exists: ", filepath)
    message("Use overwrite = TRUE to re-download")
    return(invisible(filepath))
  }

  # Construct download URL
  # Note: These URLs are based on GHS-POP R2023A structure
  base_url <- "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A"

  # Map resolution to dataset specification
  if (resolution == "100m") {
    # 100m Mollweide (EPSG:54009)
    dataset_name <- sprintf("GHS_POP_E%d_GLOBE_R2023A_54009_100", year)
  } else if (resolution == "1km") {
    # 1km Mollweide (EPSG:54009)
    dataset_name <- sprintf("GHS_POP_E%d_GLOBE_R2023A_54009_1000", year)
  } else if (resolution == "3ss") {
    # 3 arc-second WGS84 (EPSG:4326)
    dataset_name <- sprintf("GHS_POP_E%d_GLOBE_R2023A_4326_3ss", year)
  } else {  # 30ss
    # 30 arc-second WGS84 (EPSG:4326)
    dataset_name <- sprintf("GHS_POP_E%d_GLOBE_R2023A_4326_30ss", year)
  }

  # Construct full URL with V1-0 directory
  url <- sprintf("%s/%s/V1-0/%s_V1_0.zip", base_url, dataset_name, dataset_name)

  # Show download info
  message("\n========================================")
  message("Downloading GHS-POP data")
  message("========================================")
  message("Year:       ", year)
  message("Resolution: ", resolution)
  estimate_download_size(resolution, year)
  message("Source:     EC JRC GHS-POP R2023A")
  message("Destination:", filepath)
  message("\nThis may take several minutes...")
  message("========================================\n")

  # Download zip file
  temp_zip <- tempfile(fileext = ".zip")

  tryCatch({
    utils::download.file(
      url = url,
      destfile = temp_zip,
      mode = "wb",
      quiet = FALSE
    )
  }, error = function(e) {
    stop(
      "Failed to download GHS-POP data. Please check:\n",
      "  1. Internet connection\n",
      "  2. URL availability: ", url, "\n",
      "  3. Year and resolution are correct\n\n",
      "You may need to manually download from:\n",
      "  https://ghsl.jrc.ec.europa.eu/download.php\n\n",
      "Original error: ", e$message,
      call. = FALSE
    )
  })

  # Extract TIF file from zip
  message("\nExtracting...")

  temp_dir <- tempfile()
  dir.create(temp_dir)

  tryCatch({
    utils::unzip(temp_zip, exdir = temp_dir)

    # Find the .tif file
    tif_files <- list.files(temp_dir, pattern = "\\.tif$", full.names = TRUE, recursive = TRUE)

    if (length(tif_files) == 0) {
      stop("No .tif file found in downloaded archive", call. = FALSE)
    }

    # Move to cache location
    file.copy(tif_files[1], filepath, overwrite = TRUE)

    # Clean up
    unlink(temp_zip)
    unlink(temp_dir, recursive = TRUE)

    message("\nDownload complete!")
    message("Cached at: ", filepath)
    message("Size: ", round(file.size(filepath) / 1024^3, 2), " GB")

  }, error = function(e) {
    stop(
      "Failed to extract downloaded file: ", e$message, "\n",
      "You may need to manually extract the .tif file from the downloaded zip.",
      call. = FALSE
    )
  })

  invisible(filepath)
}

#' Load GHS-POP raster data
#'
#' Loads a cached GHS-POP raster file. If the file doesn't exist locally,
#' prompts the user to download it first.
#'
#' @param year Numeric year
#' @param resolution Character, either "100m" or "1km"
#' @return SpatRaster object from terra package
#' @keywords internal
#' @noRd
load_ghspop_raster <- function(year = 2025, resolution = "100m") {
  validate_year(year)

  # Check package environment cache first
  pkg_env <- get_pkg_env()
  cache_key <- sprintf("raster_%d_%s", year, resolution)

  if (exists(cache_key, envir = pkg_env)) {
    return(get(cache_key, envir = pkg_env))
  }

  # Check file exists
  cache_dir <- get_cache_dir()
  filename <- sprintf("GHS_POP_%d_%s.tif", year, resolution)
  filepath <- file.path(cache_dir, filename)

  if (!file.exists(filepath)) {
    stop(
      "GHS-POP data not found for year ", year, " at ", resolution, " resolution.\n",
      "Please download the data first using:\n",
      "  download_ghspop_data(year = ", year, ", resolution = \"", resolution, "\")",
      call. = FALSE
    )
  }

  # Load raster
  message("Loading GHS-POP raster for year ", year, " (", resolution, ")...")

  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Package 'terra' is required but not installed", call. = FALSE)
  }

  raster <- terra::rast(filepath)

  # Cache in package environment
  assign(cache_key, raster, envir = pkg_env)

  message("Raster loaded successfully")

  raster
}

#' Get path to cached GHS-POP data
#'
#' Returns the file path to a cached GHS-POP raster, or NULL if not cached.
#'
#' @param year Numeric year
#' @param resolution Character, either "100m" or "1km"
#' @return Character path or NULL
#' @export
#' @examples
#' get_cached_data_path(2025, "100m")
get_cached_data_path <- function(year = 2025, resolution = "100m") {
  validate_year(year)

  cache_dir <- get_cache_dir()
  filename <- sprintf("GHS_POP_%d_%s.tif", year, resolution)
  filepath <- file.path(cache_dir, filename)

  if (file.exists(filepath)) {
    return(filepath)
  } else {
    return(NULL)
  }
}

#' Check if GHS-POP data is available locally
#'
#' @param year Numeric year
#' @param resolution Character, either "100m" or "1km"
#' @return Logical indicating if data is cached
#' @export
#' @examples
#' is_data_available(2025, "100m")
is_data_available <- function(year = 2025, resolution = "100m") {
  !is.null(get_cached_data_path(year, resolution))
}
