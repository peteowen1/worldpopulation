# Quick Start Guide - worldpopulation Package

Welcome! Your `worldpopulation` R package is ready to go. Follow these steps to get started.

## Step 1: Complete Package Setup (5 minutes)

Open RStudio and run the setup script:

```r
setwd("C:/dev/worldpopulation")
source("setup_package.R")
```

This will:
- ✅ Generate the world cities dataset (200+ cities)
- ✅ Build package documentation
- ✅ Load all functions
- ✅ Run a quick test

## Step 2: Download Population Data (One-Time)

**IMPORTANT:** You need GHS-POP raster data before analyzing populations.

Choose a resolution based on your needs. The package supports 4 options:

### Option A: Fast Start (Recommended for Beginners)
```r
library(worldpopulation)
download_ghspop_data(year = 2025, resolution = "30ss")
```
- Size: ~480 MB
- Time: 2-8 minutes
- Projection: WGS84 (lat/lon, no reprojection)
- **Best for:** Quick start, exploration, testing

### Option B: Balanced Accuracy
```r
download_ghspop_data(year = 2025, resolution = "1km")
```
- Size: ~300 MB
- Time: 1-5 minutes
- Projection: Mollweide (equal-area, automatic reprojection)
- **Best for:** Good accuracy with small file size

### Option C: Highest Accuracy
```r
download_ghspop_data(year = 2025, resolution = "100m")
```
- Size: ~5 GB
- Time: 10-30 minutes
- Projection: Mollweide (equal-area, automatic reprojection)
- **Best for:** Final analysis, publications, maximum accuracy

### Option D: Very High Resolution (Advanced)
```r
download_ghspop_data(year = 2025, resolution = "3ss")
```
- Size: ~12 GB
- Time: 30-60 minutes
- Projection: WGS84 (lat/lon, no reprojection)
- **Best for:** Maximum detail analysis (very large file!)

**Tip:** Start with 30ss for fast exploration, then upgrade to 100m for final analysis if you need higher accuracy.

**What's the difference?**
- **Mollweide (100m, 1km)**: Equal-area projection, best for population totals
- **WGS84 (3ss, 30ss)**: Standard lat/lon, pixel size varies by latitude

**Where is the data stored?**
- Windows: `C:\Users\YourName\Documents\worldpopulation_data\`
- Mac/Linux: `~/Documents/worldpopulation_data/`
- Check with: `cache_info()`
- Delete with: `clear_cache()`

## Step 3: Your First Analysis (2 minutes)

```r
library(worldpopulation)

# Load built-in cities
cities <- load_world_cities()

# Rank top 20 cities by population within 50km
results <- rank_cities_by_population(
  cities = cities,
  radius_km = 50,
  top_n = 20
)

print(results)
```

You should see a ranking like:
```
  rank        city    country  population_in_radius
1    1       Tokyo      Japan           37,468,302
2    2       Delhi      India           32,941,308
3    3    Shanghai      China           28,516,904
...
```

## Step 4: Explore the Examples

Run the pre-built analysis scripts in order:

```r
# 1. Setup and explore data
source("analysis/01_setup_and_download.R")

# 2. Rank cities at different radii
source("analysis/02_top_cities_ranking.R")

# 3. Compare specific cities in detail
source("analysis/03_compare_major_cities.R")

# 4. Create visualizations (requires ggplot2)
source("analysis/04_visualization.R")
```

## Common Tasks

### Find Population Around a Specific Point

```r
# Population within 25km of your location
pop <- population_in_circle(
  lat = YOUR_LATITUDE,
  lon = YOUR_LONGITUDE,
  radius_km = 25
)

print(paste("Population:", format(pop, big.mark = ",")))
```

### Compare Your Favorite Cities

```r
my_cities <- data.frame(
  city = c("City A", "City B", "City C"),
  lat = c(LAT1, LAT2, LAT3),
  lon = c(LON1, LON2, LON3)
)

comparison <- compare_cities(
  cities = my_cities,
  radii_km = c(10, 25, 50, 100)
)

print(comparison)
```

### Filter to Specific Countries

```r
# US cities only
us_cities <- filter_cities_by_country("US")

# Rank them
us_top <- rank_cities_by_population(
  cities = us_cities,
  radius_km = 50
)
```

### Regional Analysis

```r
# Top cities in Europe
europe <- top_cities_in_region(
  cities = load_world_cities(),
  radius_km = 50,
  min_lat = 35, max_lat = 71,
  min_lon = -10, max_lon = 40,
  top_n = 20
)
```

## Documentation

- **Package help:** `?worldpopulation`
- **Function help:** `?rank_cities_by_population`
- **Vignette:** `vignette("getting-started", package = "worldpopulation")`
- **README:** See `README.md` for full documentation

## Available Functions

### Main Functions
- `rank_cities_by_population()` - Rank cities by population at radius
- `population_in_circle()` - Population around a single point
- `population_in_circles()` - Multiple radii at once
- `compare_cities()` - Compare multiple cities
- `population_in_rings()` - Annular ring analysis
- `population_density_profile()` - Density vs distance

### Data Functions
- `download_ghspop_data()` - Download raster data
- `load_world_cities()` - Load built-in cities
- `filter_cities_by_country()` - Filter by country
- `filter_cities_by_population()` - Filter by size
- `top_cities_in_region()` - Regional ranking

### Utility Functions
- `list_available_years()` - Show available data years
- `cache_info()` - Show cached data
- `clear_cache()` - Free up disk space
- `estimate_download_size()` - Check download size

## Troubleshooting

### "GHS-POP data not found"
**Solution:** Download the data first:
```r
download_ghspop_data(year = 2025, resolution = "100m")
```

### "Package 'terra' is required but not installed"
**Solution:** Install missing dependencies:
```r
install.packages(c("terra", "sf", "exactextractr", "geosphere"))
```

### "world_cities dataset not available"
**Solution:** Run the setup script:
```r
source("setup_package.R")
```

### Download is slow or fails
**Solution:**
- Try a smaller resolution: `download_ghspop_data(year = 2025, resolution = "30ss")` (fastest, 480 MB)
- Or try: `download_ghspop_data(year = 2025, resolution = "1km")` (300 MB)
- Check internet connection
- Try again later (server may be busy)

### Package check fails
**Solution:** Make sure you've run setup first, then:
```r
devtools::document()
devtools::check()
```

## Next Steps

1. ✅ Run `setup_package.R`
2. ✅ Download GHS-POP data
3. ✅ Run example analyses
4. 🎯 Analyze your own cities of interest
5. 📊 Create custom visualizations
6. 📝 Share your findings!

## Need Help?

- **Issues:** https://github.com/peteo/worldpopulation/issues
- **Documentation:** `?worldpopulation`
- **Examples:** Check the `analysis/` folder

## What's Different from Tom Forth's Website?

| Feature | Tom Forth's Site | This Package |
|---------|------------------|--------------|
| **Interface** | Web browser | R / RStudio |
| **Speed** | Fast (API) | Very fast (local) |
| **Accuracy** | Point-based | Exact (partial pixels) |
| **Radius limits** | 3-50 km | No limits |
| **Batch analysis** | One at a time | Hundreds at once |
| **Offline use** | No | Yes |
| **Customization** | Fixed | Fully customizable |
| **Cost** | Free | Free |

---

**Enjoy exploring global urban populations!** 🌍📊

Have fun at the beach! Your package will be ready when you get back.
