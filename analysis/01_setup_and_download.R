# 01_setup_and_download.R
# Initial setup: Download GHS-POP data and explore built-in city dataset

devtools::load_all()

# ==============================================================================
# Step 1: Check Available Years
# ==============================================================================

cat("\n=== Available GHS-POP Years ===\n")
list_available_years()

# ==============================================================================
# Step 2: Estimate Download Size
# ==============================================================================

cat("\n=== Estimating Download Size ===\n")
estimate_download_size("100m", 2025)
estimate_download_size("1km", 2025)

# ==============================================================================
# Step 3: Download GHS-POP Data
# ==============================================================================

# IMPORTANT: Uncomment the appropriate line below to download data
# This will download ~4.8 GB for 100m resolution or ~300 MB for 1km resolution

# Option 1: High resolution (recommended for accurate analysis)
# WARNING: This is a large download (~4.8 GB)
# download_ghspop_data(year = 2025, resolution = "100m")

# Option 2: Lower resolution (faster download, good for testing)
download_ghspop_data(year = 2025, resolution = "1km", overwrite = TRUE)

# Option 3: Download historical data
# download_ghspop_data(year = 2020, resolution = "100m")

# ==============================================================================
# Step 4: Check What's Cached
# ==============================================================================

cat("\n=== Cached Data ===\n")
cache_info()

# ==============================================================================
# Step 5: Explore Built-in City Dataset
# ==============================================================================

cat("\n=== Loading World Cities ===\n")
cities <- load_world_cities()

cat(sprintf("Total cities in dataset: %d\n", nrow(cities)))
cat("\nDataset structure:\n")
str(cities)

cat("\n=== Cities by Country (Top 15) ===\n")
country_counts <- sort(table(cities$country), decreasing = TRUE)
print(head(country_counts, 15))

cat("\n=== Top 20 Cities by Population ===\n")
top_cities <- cities[order(cities$population, decreasing = TRUE), ]
print(head(top_cities[, c("rank" = seq_len(nrow(top_cities)), "city", "country", "population")], 20))

# ==============================================================================
# Step 6: Filter Cities Examples
# ==============================================================================

cat("\n=== Filtering Examples ===\n")

# Get cities over 10 million
mega_cities <- filter_cities_by_population(10e6)
cat(sprintf("\nCities over 10 million: %d\n", nrow(mega_cities)))
print(mega_cities[, c("city", "country", "population")])

# Get US cities
us_cities <- filter_cities_by_country("US")
cat(sprintf("\nUS cities in dataset: %d\n", nrow(us_cities)))
print(us_cities[order(us_cities$population, decreasing = TRUE), c("city", "population")])

# Get European cities
europe_codes <- c("GB", "FR", "DE", "IT", "ES", "NL", "BE", "CH", "AT", "SE",
                  "NO", "DK", "FI", "PL", "CZ", "HU", "PT", "GR", "IE")
europe_cities <- filter_cities_by_country(europe_codes)
cat(sprintf("\nEuropean cities in dataset: %d\n", nrow(europe_cities)))

# ==============================================================================
# Step 7: Create Custom City Datasets
# ==============================================================================

cat("\n=== Custom City Dataset Example ===\n")

# Example: Create a dataset of tech hub cities
tech_hubs <- data.frame(
  city = c("San Francisco", "Seattle", "Austin", "Boston", "Bangalore",
           "Tel Aviv", "Singapore", "Shenzhen", "Berlin", "London"),
  lat = c(37.7749, 47.6062, 30.2672, 42.3601, 12.9716,
          32.0853, 1.3521, 22.5431, 52.5200, 51.5074),
  lon = c(-122.4194, -122.3321, -97.7431, -71.0589, 77.5946,
          34.7818, 103.8198, 114.0579, 13.4050, -0.1278),
  stringsAsFactors = FALSE
)

cat("Tech hub cities:\n")
print(tech_hubs)

# ==============================================================================
# Summary
# ==============================================================================

cat("\n=== Setup Summary ===\n")
cat("1. Downloaded GHS-POP data (if uncommented above)\n")
cat("2. Explored built-in city dataset\n")
cat("3. Learned how to filter and create custom city datasets\n")
cat("\nNext steps:\n")
cat("- Run 02_top_cities_ranking.R to rank cities by population\n")
cat("- Run 03_compare_major_cities.R to compare specific cities\n")
cat("- Run 04_visualization.R to create plots\n")
