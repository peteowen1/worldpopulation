# Process world cities data for package
# This script creates the built-in world_cities dataset
# Downloads from multiple sources with SimpleMaps as default

# Load package functions (including download helpers in R/city_data_download.R)
devtools::load_all()

# ==============================================================================
# Configuration
# ==============================================================================

# Choose data source: "simplemaps", "geonames", or "naturalearth"
# Set to NULL to auto-select (tries SimpleMaps first, then others as fallback)
DATA_SOURCE <- NULL  # Auto-select (default: SimpleMaps)
# DATA_SOURCE <- "simplemaps"  # Force SimpleMaps
# DATA_SOURCE <- "geonames"    # Force GeoNames
# DATA_SOURCE <- "naturalearth" # Force Natural Earth

# Number of cities to include (sorted by population)
MAX_CITIES <- 2000

# ==============================================================================
# Main Script
# ==============================================================================

message("\n========================================")
message("World Cities Data Download")
message("========================================\n")

# Determine which source to use
if (!is.null(DATA_SOURCE)) {
  message(sprintf("Using specified source: %s\n", DATA_SOURCE))
  sources <- DATA_SOURCE
} else {
  message("Auto-selecting data source (trying SimpleMaps first)...\n")
  sources <- c("simplemaps", "geonames", "naturalearth")
}

# Try each source in order
world_cities <- NULL
for (source in sources) {
  if (!is.null(world_cities)) break

  world_cities <- switch(source,
    simplemaps = download_simplemaps(MAX_CITIES),
    geonames = download_geonames(MAX_CITIES),
    naturalearth = download_naturalearth(MAX_CITIES),
    stop("Unknown data source: ", source)
  )
}

# Check if we got data
if (is.null(world_cities)) {
  stop("Failed to download city data from any source!")
}

# Final cleanup
world_cities$admin_name[world_cities$admin_name == ""] <- NA
world_cities$iso2[world_cities$iso2 == "" | world_cities$iso2 == "-99"] <- NA
world_cities$iso3[world_cities$iso3 == "" | world_cities$iso3 == "-99"] <- NA

# Show summary
message("\n========================================")
message("Dataset Summary")
message("========================================")
message(sprintf("Total cities: %d", nrow(world_cities)))
message(sprintf("Countries: %d", length(unique(world_cities$country))))
message(sprintf("Population range: %s - %s",
                format(min(world_cities$population, na.rm = TRUE), big.mark = ","),
                format(max(world_cities$population, na.rm = TRUE), big.mark = ",")))
message("\nTop 10 cities by population:")
print(head(world_cities[, c("city", "country", "population")], 10))
message("========================================\n")

# Save to package data
message("Saving to package data...")
usethis::use_data(world_cities, overwrite = TRUE)

message("\n✓ world_cities dataset created successfully!")
message(sprintf("  Source: %s", if(is.null(DATA_SOURCE)) "SimpleMaps (auto-selected)" else DATA_SOURCE))
message(sprintf("  Cities: %d", nrow(world_cities)))
message("\nTo use a different source, edit DATA_SOURCE at the top of this script.")
