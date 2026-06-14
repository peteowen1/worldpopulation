# 04_visualization.R
# Create visualizations of population analysis results

devtools::load_all()

# Optional but recommended for better plots
if (!require("ggplot2")) {
  cat("Installing ggplot2 for visualizations...\n")
  install.packages("ggplot2")
}
library(ggplot2)

# ==============================================================================
# Check Data Availability
# ==============================================================================

if (!is_data_available(2025, "100m") && !is_data_available(2025, "1km")) {
  stop("GHS-POP data not found. Run 01_setup_and_download.R first.")
}

resolution <- if (is_data_available(2025, "100m")) "100m" else "1km"
cat(sprintf("Using %s resolution data\n\n", resolution))

# ==============================================================================
# Plot 1: Population vs Distance for Major Cities
# ==============================================================================

cat("Creating Plot 1: Population vs Distance\n")

# Select diverse cities
cities_to_plot <- data.frame(
  city = c("Tokyo", "Delhi", "Shanghai", "São Paulo", "Mumbai",
           "Cairo", "London", "New York", "Lagos", "Paris"),
  lat = c(35.6762, 28.7041, 31.2304, -23.5505, 19.0760,
          30.0444, 51.5074, 40.7128, 6.5244, 48.8566),
  lon = c(139.6503, 77.1025, 121.4737, -46.6333, 72.8777,
          31.2357, -0.1278, -74.0060, 3.3792, 2.3522),
  stringsAsFactors = FALSE
)

comparison <- compare_cities(
  cities = cities_to_plot,
  radii_km = c(5, 10, 15, 20, 25, 35, 50, 75, 100),
  year = 2025,
  resolution = resolution
)

# Convert to millions for readability
comparison$population_millions <- comparison$population / 1e6

# Create plot
p1 <- ggplot(comparison, aes(x = radius_km, y = population_millions, color = city)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Population Within Distance from City Center",
    subtitle = sprintf("Top 10 World Cities (2025 projection, %s resolution)", resolution),
    x = "Distance from City Center (km)",
    y = "Cumulative Population (millions)",
    color = "City"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "right",
    panel.grid.minor = element_blank()
  )

print(p1)

# Save plot
ggsave("population_vs_distance.png", p1, width = 12, height = 7, dpi = 300)
cat("Saved: population_vs_distance.png\n\n")

# ==============================================================================
# Plot 2: City Rankings at Different Radii
# ==============================================================================

cat("Creating Plot 2: Rankings at Different Radii\n")

cities <- load_world_cities()

# Get rankings at different radii
radii_compare <- c(10, 25, 50, 100)
ranking_data <- data.frame()

for (r in radii_compare) {
  top_10 <- rank_cities_by_population(
    cities = cities,
    radius_km = r,
    top_n = 10,
    year = 2025,
    resolution = resolution,
    progress = FALSE
  )

  top_10$radius_km <- r
  top_10$pop_millions <- top_10$population_in_radius / 1e6

  ranking_data <- rbind(ranking_data, top_10)
}

# Create plot
p2 <- ggplot(ranking_data, aes(x = factor(radius_km), y = pop_millions, fill = city)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Top 10 Cities at Different Radii",
    subtitle = sprintf("How rankings change with distance (2025, %s)", resolution),
    x = "Radius (km)",
    y = "Population (millions)",
    fill = "City"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "right",
    panel.grid.minor = element_blank()
  )

print(p2)
ggsave("rankings_by_radius.png", p2, width = 12, height = 7, dpi = 300)
cat("Saved: rankings_by_radius.png\n\n")

# ==============================================================================
# Plot 3: Density Profile for a Single City
# ==============================================================================

cat("Creating Plot 3: Density Profile for Tokyo\n")

tokyo_density <- population_density_profile(
  lat = 35.6762,
  lon = 139.6503,
  radii_km = seq(5, 100, by = 5),
  year = 2025,
  resolution = resolution
)

p3 <- ggplot(tokyo_density, aes(x = outer_radius_km, y = density_per_km2)) +
  geom_area(fill = "steelblue", alpha = 0.5) +
  geom_line(color = "steelblue", linewidth = 1.2) +
  geom_point(color = "steelblue", size = 2.5) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Tokyo: Population Density vs Distance from Center",
    subtitle = sprintf("How density decreases with distance (2025, %s)", resolution),
    x = "Distance from City Center (km)",
    y = "Population Density (people per km²)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank()
  )

print(p3)
ggsave("tokyo_density_profile.png", p3, width = 10, height = 6, dpi = 300)
cat("Saved: tokyo_density_profile.png\n\n")

# ==============================================================================
# Plot 4: Ring Distribution
# ==============================================================================

cat("Creating Plot 4: Population Distribution in Rings\n")

# Compare ring distributions for several cities
cities_for_rings <- data.frame(
  city = c("Tokyo", "Delhi", "New York", "London"),
  lat = c(35.6762, 28.7041, 40.7128, 51.5074),
  lon = c(139.6503, 77.1025, -74.0060, -0.1278),
  stringsAsFactors = FALSE
)

ring_data <- data.frame()

for (i in 1:nrow(cities_for_rings)) {
  rings <- population_in_rings(
    lat = cities_for_rings$lat[i],
    lon = cities_for_rings$lon[i],
    radii_km = c(0, 10, 25, 50, 75, 100),
    year = 2025,
    resolution = resolution
  )

  rings$city <- cities_for_rings$city[i]
  rings$ring_label <- sprintf("%d-%d km", rings$inner_radius_km, rings$outer_radius_km)
  rings$pop_millions <- rings$population / 1e6

  ring_data <- rbind(ring_data, rings)
}

p4 <- ggplot(ring_data, aes(x = city, y = pop_millions, fill = ring_label)) +
  geom_col(position = "stack") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Population Distribution in Concentric Rings",
    subtitle = sprintf("Where do people live relative to city center? (2025, %s)", resolution),
    x = "City",
    y = "Population (millions)",
    fill = "Distance Ring"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "right",
    panel.grid.minor = element_blank()
  )

print(p4)
ggsave("ring_distribution.png", p4, width = 10, height = 6, dpi = 300)
cat("Saved: ring_distribution.png\n\n")

# ==============================================================================
# Plot 5: Regional Comparison
# ==============================================================================

cat("Creating Plot 5: Regional Top Cities\n")

# Get top 5 from each region
regions <- list(
  Europe = list(min_lat = 35, max_lat = 71, min_lon = -10, max_lon = 40),
  Asia = list(min_lat = -10, max_lat = 55, min_lon = 60, max_lon = 150),
  Americas = list(min_lat = -60, max_lat = 70, min_lon = -170, max_lon = -30)
)

regional_data <- data.frame()

for (region_name in names(regions)) {
  region <- regions[[region_name]]

  top_cities <- top_cities_in_region(
    cities = cities,
    radius_km = 50,
    min_lat = region$min_lat,
    max_lat = region$max_lat,
    min_lon = region$min_lon,
    max_lon = region$max_lon,
    top_n = 5,
    year = 2025,
    resolution = resolution
  )

  top_cities$region <- region_name
  top_cities$pop_millions <- top_cities$population_in_radius / 1e6

  regional_data <- rbind(regional_data, top_cities)
}

p5 <- ggplot(regional_data, aes(x = reorder(city, pop_millions), y = pop_millions, fill = region)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Top 5 Cities by Region (50km radius)",
    subtitle = sprintf("Population within 50km of city center (2025, %s)", resolution),
    x = NULL,
    y = "Population (millions)",
    fill = "Region"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

print(p5)
ggsave("regional_comparison.png", p5, width = 10, height = 8, dpi = 300)
cat("Saved: regional_comparison.png\n\n")

# ==============================================================================
# Summary
# ==============================================================================

cat("=== Visualization Complete ===\n")
cat("\nGenerated plots:\n")
cat("1. population_vs_distance.png - Population growth curves for major cities\n")
cat("2. rankings_by_radius.png - How rankings change with radius\n")
cat("3. tokyo_density_profile.png - Density decay from city center\n")
cat("4. ring_distribution.png - Where people live (rings)\n")
cat("5. regional_comparison.png - Top cities by region\n")

cat("\nNext steps:\n")
cat("- Customize plots for your specific cities of interest\n")
cat("- Try different radii and years\n")
cat("- Create plots for specific countries or regions\n")
cat("- Export data to CSV for further analysis in other tools\n")
