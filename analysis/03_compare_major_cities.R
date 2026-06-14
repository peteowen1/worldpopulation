# 03_compare_major_cities.R
# Compare specific cities across multiple radii to understand
# how their population distribution differs

devtools::load_all()

# NOTE: This script requires GHS-POP data to be downloaded first

# ==============================================================================
# Check Data Availability
# ==============================================================================

if (!is_data_available(2025, "100m") && !is_data_available(2025, "1km")) {
  stop("GHS-POP data not found. Run 01_setup_and_download.R first.")
}

resolution <- if (is_data_available(2025, "100m")) "100m" else "1km"
cat(sprintf("Using %s resolution data\n\n", resolution))

# ==============================================================================
# Define Cities to Compare
# ==============================================================================

# Selection of major world cities with diverse characteristics
major_cities <- data.frame(
  city = c(
    # Asian megacities
    "Tokyo", "Delhi", "Shanghai", "Mumbai", "Beijing", "Dhaka",

    # European capitals
    "London", "Paris", "Moscow", "Istanbul",

    # American cities
    "New York", "São Paulo", "Mexico City", "Los Angeles",

    # African cities
    "Cairo", "Lagos",

    # Middle East
    "Tehran",

    # Oceania
    "Sydney"
  ),
  lat = c(
    35.6762, 28.7041, 31.2304, 19.0760, 39.9042, 23.8103,
    51.5074, 48.8566, 55.7558, 41.0082,
    40.7128, -23.5505, 19.4326, 34.0522,
    30.0444, 6.5244,
    35.6892,
    -33.8688
  ),
  lon = c(
    139.6503, 77.1025, 121.4737, 72.8777, 116.4074, 90.4125,
    -0.1278, 2.3522, 37.6173, 28.9784,
    -74.0060, -46.6333, -99.1332, -118.2437,
    31.2357, 3.3792,
    51.3890,
    151.2093
  ),
  stringsAsFactors = FALSE
)

cat(sprintf("Comparing %d major cities\n", nrow(major_cities)))
cat("Cities:", paste(major_cities$city, collapse = ", "), "\n\n")

# ==============================================================================
# Compare Across Multiple Radii
# ==============================================================================

cat("=== Comparing Cities at Multiple Distances ===\n")
cat("(This will take a few minutes...)\n\n")

radii <- c(5, 10, 25, 50, 75, 100)

comparison <- compare_cities(
  cities = major_cities,
  radii_km = radii,
  year = 2025,
  resolution = resolution
)

# ==============================================================================
# View Results
# ==============================================================================

cat("\n=== Comparison Results ===\n")
print(comparison)

# ==============================================================================
# Analyze Specific Comparisons
# ==============================================================================

# Compare at 50km (Tom Forth's standard)
cat("\n\n=== Population within 50km ===\n")
pop_50km <- comparison[comparison$radius_km == 50, ]
pop_50km <- pop_50km[order(pop_50km$population, decreasing = TRUE), ]
pop_50km$rank <- 1:nrow(pop_50km)
print(pop_50km[, c("rank", "city", "population")])

# City center density (10km)
cat("\n\n=== City Center Density (10km) ===\n")
pop_10km <- comparison[comparison$radius_km == 10, ]
pop_10km <- pop_10km[order(pop_10km$population, decreasing = TRUE), ]
pop_10km$rank <- 1:nrow(pop_10km)
print(pop_10km[, c("rank", "city", "population")])

# Metropolitan reach (100km)
cat("\n\n=== Metropolitan Reach (100km) ===\n")
pop_100km <- comparison[comparison$radius_km == 100, ]
pop_100km <- pop_100km[order(pop_100km$population, decreasing = TRUE), ]
pop_100km$rank <- 1:nrow(pop_100km)
print(pop_100km[, c("rank", "city", "population")])

# ==============================================================================
# Growth Patterns
# ==============================================================================

cat("\n\n=== Population Growth from 10km to 100km ===\n")

growth_analysis <- data.frame(
  city = character(),
  pop_10km = numeric(),
  pop_100km = numeric(),
  growth_factor = numeric(),
  stringsAsFactors = FALSE
)

for (city_name in major_cities$city) {
  city_data <- comparison[comparison$city == city_name, ]
  p10 <- city_data$population[city_data$radius_km == 10]
  p100 <- city_data$population[city_data$radius_km == 100]

  growth_analysis <- rbind(growth_analysis, data.frame(
    city = city_name,
    pop_10km = p10,
    pop_100km = p100,
    growth_factor = p100 / p10,
    stringsAsFactors = FALSE
  ))
}

growth_analysis <- growth_analysis[order(growth_analysis$growth_factor, decreasing = TRUE), ]
cat("Cities ranked by sprawl (100km/10km ratio):\n")
print(growth_analysis)

cat("\nMost compact (lowest ratio):", growth_analysis$city[nrow(growth_analysis)], "\n")
cat("Most sprawling (highest ratio):", growth_analysis$city[1], "\n")

# ==============================================================================
# Detailed Profile: Single City
# ==============================================================================

cat("\n\n=== Detailed Profile: Tokyo ===\n")

tokyo_profile <- population_in_circles(
  lat = 35.6762,
  lon = 139.6503,
  radii_km = seq(5, 100, by = 5),
  year = 2025,
  resolution = resolution
)

print(tokyo_profile)

# Population density profile
cat("\n\n=== Tokyo Density Profile ===\n")
tokyo_density <- population_density_profile(
  lat = 35.6762,
  lon = 139.6503,
  radii_km = seq(10, 100, by = 10),
  year = 2025,
  resolution = resolution
)

print(tokyo_density)

# ==============================================================================
# Ring Analysis: Where Do People Live?
# ==============================================================================

cat("\n\n=== Ring Analysis: Mumbai ===\n")
cat("How population is distributed in concentric rings:\n\n")

mumbai_rings <- population_in_rings(
  lat = 19.0760,
  lon = 72.8777,
  radii_km = c(0, 10, 20, 30, 50, 75, 100),
  year = 2025,
  resolution = resolution
)

mumbai_rings$percent <- round(100 * mumbai_rings$population / sum(mumbai_rings$population), 1)
print(mumbai_rings)

cat("\nInterpretation:\n")
cat(sprintf("- %s%% of population lives within 10km\n",
            mumbai_rings$percent[mumbai_rings$outer_radius_km == 10]))
cat(sprintf("- %s%% lives between 10-20km\n",
            mumbai_rings$percent[mumbai_rings$inner_radius_km == 10 &
                                  mumbai_rings$outer_radius_km == 20]))

# ==============================================================================
# Summary
# ==============================================================================

cat("\n\n=== Analysis Summary ===\n")
cat(sprintf("Winner at 50km: %s with %s people\n",
            pop_50km$city[1],
            format(pop_50km$population[1], big.mark = ",")))

cat(sprintf("Densest center (10km): %s with %s people\n",
            pop_10km$city[1],
            format(pop_10km$population[1], big.mark = ",")))

cat(sprintf("Largest metro (100km): %s with %s people\n",
            pop_100km$city[1],
            format(pop_100km$population[1], big.mark = ",")))

cat("\nNext steps:\n")
cat("- Run 04_visualization.R to create plots of these comparisons\n")
cat("- Add your own cities of interest\n")
cat("- Compare cities from the same region\n")
cat("- Analyze how rankings change over time (try different years)\n")
