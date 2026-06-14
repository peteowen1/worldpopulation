# Setup script for worldpopulation package
# Run this script in RStudio to complete package setup

# Install required development packages if needed
if (!require("devtools")) install.packages("devtools")
if (!require("roxygen2")) install.packages("roxygen2")
if (!require("usethis")) install.packages("usethis")

# 1. Generate world_cities dataset
message("Generating world_cities dataset...")
source("data-raw/cities.R")

# 2. Generate documentation from roxygen2 comments
message("Generating documentation...")
devtools::document()

# 3. Check if man/ directory was created
if (dir.exists("man")) {
  message("Documentation generated successfully!")
} else {
  warning("Documentation directory not created. Check for errors above.")
}

# 4. Load all package functions
message("Loading package functions...")
devtools::load_all()

# 5. Run a quick test
message("\nRunning quick test...")
message("Loading world cities...")
cities <- load_world_cities()
message(sprintf("Loaded %d cities", nrow(cities)))
message("\nTop 10 cities by population:")
print(head(cities[order(cities$population, decreasing = TRUE), c("city", "country", "population")], 10))

message("\n========================================")
message("Package setup complete!")
message("========================================")
message("\nNext steps:")
message("1. Install the package: devtools::install()")
message("2. Run tests: devtools::test()")
message("3. Check package: devtools::check()")
message("\nTo get started with analysis:")
message("1. Download GHS-POP data: download_ghspop_data(year = 2025)")
message("   (Warning: This is a ~4.8 GB download for 100m resolution)")
message("   Data will be stored in: ", get_cache_dir())
message("2. See vignettes for usage examples")
message("========================================\n")
