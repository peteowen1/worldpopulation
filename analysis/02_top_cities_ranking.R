# 02_top_cities_ranking.R
# Rank cities worldwide by population within specified radii
# This demonstrates the main use case of the package

library(tidyverse)
devtools::load_all()

# NOTE: This script requires GHS-POP data to be downloaded first
# Run 01_setup_and_download.R and uncomment the download line

# ==============================================================================
# Check if Data is Available
# ==============================================================================

if (!is_data_available(2025, "100m") && !is_data_available(2025, "1km")) {
  stop(
    "GHS-POP data not found. Please run:\n",
    "  download_ghspop_data(year = 2025, resolution = '100m')\n",
    "Or use 1km resolution for faster processing:\n",
    "  download_ghspop_data(year = 2025, resolution = '1km')"
  )
}

# Determine which resolution to use
resolution <- if (is_data_available(2025, "100m")) "100m" else "1km"
cat(sprintf("\nUsing %s resolution data\n", resolution))

# ==============================================================================
# Load Cities
# ==============================================================================

cities <- load_world_cities()
cat(sprintf("Loaded %d cities\n\n", nrow(cities)))

# ==============================================================================
# Example 1: Rank Cities at 30km
# ==============================================================================

cat("=== Top 20 Cities by Population within 30km ===\n")
cat("(This may take a few minutes on first run...)\n\n")

top_30km <- rank_cities_by_population(
  cities = cities,
  radius_km = 30,
  top_n = 2000,
  year = 2025,
  resolution = resolution
)

print(top_30km)

cat("\n")

# ==============================================================================
# Example 2: Compare Rankings at Different Radii
# ==============================================================================

cat("\n=== How Rankings Change with Distance ===\n")
cat("Comparing top 10 at 25km, 50km, and 100km\n\n")

# Get top 10 at each radius
radii_to_test <- c(25, 50, 100)

for (radius in radii_to_test) {
  cat(sprintf("\n--- Top 10 at %dkm ---\n", radius))

  top_n <- rank_cities_by_population(
    cities = cities,
    radius_km = radius,
    top_n = 10,
    year = 2025,
    resolution = resolution,
    progress = FALSE
  )

  print(top_n[, c("rank", "city", "country", "population_in_radius")])
}

# ==============================================================================
# Example 3: Regional Rankings
# ==============================================================================

cat("\n\n=== Regional Rankings ===\n")

# Europe
cat("\nTop 10 European Cities (30km radius):\n")
europe_top <- top_cities_in_region(
  cities = cities,
  radius_km = 30,
  min_lat = 35, max_lat = 71,
  min_lon = -10, max_lon = 40,
  top_n = 10,
  year = 2025,
  resolution = resolution
)
print(europe_top[, c("rank", "city", "country", "population_in_radius")])

# Asia
cat("\nTop 10 Asian Cities (30km radius):\n")
asia_top <- top_cities_in_region(
  cities = cities,
  radius_km = 30,
  min_lat = -10, max_lat = 55,
  min_lon = 60, max_lon = 150,
  top_n = 10,
  year = 2025,
  resolution = resolution
)
print(asia_top[, c("rank", "city", "country", "population_in_radius")])

# Americas
cat("\nTop 10 American Cities (30km radius):\n")
americas_top <- top_cities_in_region(
  cities = cities,
  radius_km = 30,
  min_lat = -60, max_lat = 70,
  min_lon = -170, max_lon = -30,
  top_n = 10,
  year = 2025,
  resolution = resolution
)
print(americas_top[, c("rank", "city", "country", "population_in_radius")])

# ==============================================================================
# Example 4: Country-Specific Rankings
# ==============================================================================

cat("\n\n=== Country-Specific Rankings ===\n")

# United States
cat("\nTop 10 US Cities (30km radius):\n")
us_cities <- filter_cities_by_country("US")
us_top <- rank_cities_by_population(
  cities = us_cities,
  radius_km = 30,
  top_n = 10,
  year = 2025,
  resolution = resolution,
  progress = FALSE
)
print(us_top[, c("rank", "city", "population_in_radius")])

# China
cat("\nTop 10 Chinese Cities (30km radius):\n")
china_cities <- filter_cities_by_country("CN")
china_top <- rank_cities_by_population(
  cities = china_cities,
  radius_km = 30,
  top_n = 10,
  year = 2025,
  resolution = resolution,
  progress = FALSE
)
print(china_top[, c("rank", "city", "population_in_radius")])

# India
cat("\nTop 10 Indian Cities (30km radius):\n")
india_cities <- filter_cities_by_country("IN")
india_top <- rank_cities_by_population(
  cities = india_cities,
  radius_km = 30,
  top_n = 10,
  year = 2025,
  resolution = resolution,
  progress = FALSE
)
print(india_top[, c("rank", "city", "population_in_radius")])

# ==============================================================================
# Example 5: Small vs Large Radii
# ==============================================================================

cat("\n\n=== Comparing City Centers (10km) vs Metropolitan Areas (100km) ===\n")

# Dense city centers
cat("\nTop 10 by city center density (10km radius):\n")
top_10km <- rank_cities_by_population(
  cities = cities,
  radius_km = 10,
  top_n = 10,
  year = 2025,
  resolution = resolution,
  progress = FALSE
)
print(top_10km[, c("rank", "city", "country", "population_in_radius")])

# Large metropolitan areas
cat("\nTop 10 by metropolitan area (100km radius):\n")
top_100km <- rank_cities_by_population(
  cities = cities,
  radius_km = 100,
  top_n = 10,
  year = 2025,
  resolution = resolution,
  progress = FALSE
)
print(top_100km[, c("rank", "city", "country", "population_in_radius")])


###########

# Join the ranking results back to world_cities using tidyverse
library(dplyr)

comparison <- cities %>%
  left_join(
    top_30km %>% select(city, lat, lon, rank, population_in_radius),
    by = c("city", "lat", "lon")
  ) %>%
  mutate(
    population_delta = population_in_radius - population,
    population_ratio = population_in_radius / population
  ) %>%
  arrange(desc(population)) %>%
  select(rank, city, country, continent, population, population_in_radius,
         population_delta, population_ratio, lat, lon)

# Show the comparison
View(comparison)

# ==============================================================================
# Summary
# ==============================================================================

cat("\n\n=== Analysis Complete ===\n")
cat("Key findings:\n")
cat(sprintf("- #1 city at 30km: %s (%s) with %s people\n",
            top_30km$city[1],
            top_30km$country[1],
            format(top_30km$population_in_radius[1], big.mark = ",")))

cat("\nNext steps:\n")
cat("- Run 03_compare_major_cities.R for detailed city comparisons\n")
cat("- Run 04_visualization.R to create plots\n")
cat("- Try different radii to see how rankings change\n")
cat("- Analyze specific regions or countries\n")
