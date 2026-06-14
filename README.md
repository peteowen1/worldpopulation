# worldpopulation

> Analyze population within circles around global city centers using high-resolution satellite data

Rank cities worldwide by how much population they have N kilometers from their city center, inspired by Tom Forth's [Circle Populations](https://www.tomforth.co.uk/circlepopulations/) project.

## Overview

The `worldpopulation` package allows you to:

- 📊 **Rank cities** by population within specified radii (e.g., "top cities by population within 50km")
- 🌍 **Query population** at any point on Earth within any radius
- 📈 **Compare cities** across multiple distances to understand urban sprawl patterns
- 🔍 **Analyze density** profiles and how population decays from city centers
- 🎯 **Regional analysis** - filter to specific countries, regions, or bounding boxes

Uses **high-resolution GHS-POP data** (100m pixels) from the European Commission Joint Research Centre for accurate population estimates.

## Quick Example

```r
library(worldpopulation)

# Download data (one-time setup)
# Fast option: 480 MB (good for exploration)
download_ghspop_data(year = 2025, resolution = "30ss")

# Or high accuracy: 5 GB (best for final analysis)
# download_ghspop_data(year = 2025, resolution = "100m")

# Load built-in cities
cities <- load_world_cities()

# Rank top 20 cities by population within 50km
top_cities <- rank_cities_by_population(
  cities = cities,
  radius_km = 50,
  top_n = 20
)

print(top_cities)
#   rank        city  country  population_in_radius
# 1    1       Tokyo    Japan           37,468,302
# 2    2       Delhi    India           32,941,308
# 3    3    Shanghai    China           28,516,904
# ...
```

## Installation

```r
# Install development version from GitHub
devtools::install_github("peteo/worldpopulation")

# Or install from source
devtools::install()
```

### Setup

Run the setup script to prepare the package:

```r
source("setup_package.R")
```

This will:
1. Generate the built-in city dataset
2. Build package documentation
3. Load package functions
4. Run a quick test

## Data Requirements

### GHS-POP Raster Data (Required)

Before analyzing population, you need to download Global Human Settlement Layer data:

```r
# Fast download (recommended for getting started, ~480 MB)
download_ghspop_data(year = 2025, resolution = "30ss")

# Or highest accuracy (~5 GB, for final analysis)
download_ghspop_data(year = 2025, resolution = "100m")

# Or balanced option (~300 MB, equal-area projection)
download_ghspop_data(year = 2025, resolution = "1km")

# Or very high resolution (~12 GB, for maximum detail)
download_ghspop_data(year = 2025, resolution = "3ss")
```

**Data storage:** Files are saved to `~/Documents/worldpopulation_data/` (or `~/worldpopulation_data/` on systems without a Documents folder). You can check the location and size with `cache_info()`.

**Available years:** 1975, 1980, 1985, 1990, 1995, 2000, 2005, 2010, 2015, 2020, 2025 (projection), 2030 (projection)

See `list_available_years()` for details.

### Understanding Resolution Options

GHS-POP data is available in 4 different resolutions. Choose based on your accuracy needs and available disk space:

| Resolution | File Size | Projection | Description | When to Use |
|------------|-----------|------------|-------------|-------------|
| **100m** | ~5 GB | Mollweide (EPSG:54009) | 100-meter pixels, highest accuracy, equal-area | Final analysis, publications, when accuracy is critical |
| **1km** | ~300 MB | Mollweide (EPSG:54009) | 1-kilometer pixels, good accuracy, equal-area | Quick testing, exploration, good balance of speed/accuracy |
| **3ss** | ~12 GB | WGS84 (EPSG:4326) | 3 arc-seconds (~93m at equator) | Very high resolution, lat/lon native, large file |
| **30ss** | ~480 MB | WGS84 (EPSG:4326) | 30 arc-seconds (~930m at equator) | Fast downloads, exploration, no reprojection |

**Key Differences:**

- **Mollweide (100m, 1km):** Equal-area projection that preserves pixel areas globally. Best for population totals since every pixel represents the same ground area. Requires automatic coordinate transformation (handled by package).

- **WGS84 (3ss, 30ss):** Standard lat/lon coordinates. No reprojection needed, but pixel ground distance varies by latitude (smaller near poles). Arc-seconds are angular units, not distance.

**Recommendation for most users:**
1. Start with **30ss** (480 MB) for fast exploration
2. Upgrade to **100m** (5 GB) for final analysis if accuracy matters
3. Use **1km** (300 MB) for a good balance when disk space is limited

```r
# Fast download for exploration
download_ghspop_data(year = 2025, resolution = "30ss")

# High accuracy for final analysis
download_ghspop_data(year = 2025, resolution = "100m")

# Check what you need with:
estimate_download_size("100m", 2025)
```

### City Data (Included)

The package includes 1,000 major world cities with coordinates and population estimates from SimpleMaps. You can also provide your own city datasets.

## Key Features

### 1. Rank Cities by Population

The main use case - find which cities have the most people within N km:

```r
# Top 50 cities by population within 50km
# Automatically removes duplicate cities within 5km (e.g., metro areas with multiple admin centers)
top_50 <- rank_cities_by_population(
  cities = load_world_cities(),
  radius_km = 50,
  top_n = 50,
  year = 2025
)

# Disable deduplication to keep all cities
all_cities <- rank_cities_by_population(
  cities = load_world_cities(),
  radius_km = 50,
  deduplicate_km = 0  # Set to 0 to disable
)
```

### 2. Single Point Queries

Calculate population around any coordinate:

```r
# Population within 25km of Central Park, NYC
pop <- population_in_circle(
  lat = 40.7829,
  lon = -73.9654,
  radius_km = 25,
  year = 2025
)
```

### 3. Multiple Radii Analysis

Compare population at different distances:

```r
# Tokyo at 10, 25, 50, 100 km
tokyo_profile <- population_in_circles(
  lat = 35.6762,
  lon = 139.6503,
  radii_km = c(10, 25, 50, 100),
  year = 2025
)
```

### 4. Ring Analysis

Population in annular rings (donuts):

```r
# Where do Londoners live?
# 0-10km, 10-25km, 25-50km, 50-100km
london_rings <- population_in_rings(
  lat = 51.5074,
  lon = -0.1278,
  radii_km = c(0, 10, 25, 50, 100)
)
```

### 5. Compare Multiple Cities

Analyze how different cities compare:

```r
cities <- data.frame(
  city = c("London", "Paris", "Berlin", "Madrid"),
  lat = c(51.5074, 48.8566, 52.5200, 40.4168),
  lon = c(-0.1278, 2.3522, 13.4050, -3.7038)
)

comparison <- compare_cities(
  cities = cities,
  radii_km = c(10, 25, 50, 75, 100)
)

# Plot with ggplot2
library(ggplot2)
ggplot(comparison, aes(x = radius_km, y = population/1e6, color = city)) +
  geom_line() +
  geom_point() +
  labs(x = "Distance (km)", y = "Population (millions)")
```

### 6. Density Profiles

Understand how density decays from center:

```r
density <- population_density_profile(
  lat = 19.0760,  # Mumbai
  lon = 72.8777,
  radii_km = seq(5, 50, by = 5)
)
```

### 7. Regional Analysis

Filter to specific regions:

```r
# Top European cities
europe_top <- top_cities_in_region(
  cities = load_world_cities(),
  radius_km = 50,
  min_lat = 35, max_lat = 71,
  min_lon = -10, max_lon = 40,
  top_n = 20
)
```

## Example Analyses

The package includes 4 ready-to-run analysis scripts in `analysis/`:

1. **`01_setup_and_download.R`** - Initial setup and data exploration
2. **`02_top_cities_ranking.R`** - Rank cities at various radii
3. **`03_compare_major_cities.R`** - Detailed city comparisons
4. **`04_visualization.R`** - Create publication-quality plots

Run them in RStudio to see the package in action!

## Documentation

- **Package overview:** `?worldpopulation`
- **Getting started vignette:** `vignette("getting-started", package = "worldpopulation")`
- **Function help:** `?function_name` (e.g., `?rank_cities_by_population`)

## Main Functions

| Function | Description |
|----------|-------------|
| `rank_cities_by_population()` | Rank cities by population at specified radius |
| `population_in_circle()` | Population within single radius around a point |
| `population_in_circles()` | Population at multiple radii (more efficient) |
| `population_in_rings()` | Population in annular rings |
| `compare_cities()` | Compare multiple cities across radii |
| `population_density_profile()` | Density vs distance analysis |
| `download_ghspop_data()` | Download GHS-POP raster data |
| `load_world_cities()` | Load built-in city dataset |
| `filter_cities_by_country()` | Filter cities by country code |
| `top_cities_in_region()` | Rank cities within bounding box |

## Performance

The package uses `exactextractr` for population extraction, which is **~7x faster** than standard methods and provides better accuracy by handling partial pixel coverage correctly.

**Typical performance:**
- Single city query: ~8-9 milliseconds
- 50 cities at one radius: ~2-3 seconds
- 200 cities at one radius: ~5-10 seconds

**Tips:**
- Use 1km resolution for exploration, 100m for final analysis
- Batch functions (`rank_cities_by_population`, `compare_cities`) are much faster than loops
- Raster data is cached in memory after first load

## Data Sources

### Population Data
- **Source:** Global Human Settlement Layer (GHS-POP) from EC Joint Research Centre
- **License:** Open access with attribution required
- **URL:** https://ghsl.jrc.ec.europa.eu/
- **Citation:** Schiavina M., Freire S., MacManus K. (2023): GHS-POP R2023A - GHS population grid multitemporal (1975-2030). European Commission, Joint Research Centre (JRC) [Dataset]

### City Coordinates
- **Source:** Compiled from multiple public domain sources
- **Includes:** Natural Earth, GeoNames, national statistical agencies
- **Coverage:** 200+ major world cities
- **License:** Public domain / Open data

## Inspiration

This package is inspired by Tom Forth's excellent [Circle Populations](https://www.tomforth.co.uk/circlepopulations/) project, which provides an interactive web interface for exploring UK and global cities.

The R package provides:
- **Local processing** - No server required, runs on your machine
- **Higher accuracy** - Uses 100m resolution data with exact pixel coverage
- **Batch analysis** - Process hundreds of cities at once
- **Reproducibility** - Full control over data and analysis
- **Extensibility** - Integrate with other R spatial packages
- **Historical analysis** - Access data from 1975-2030

## Advantages Over Web-Based Tools

1. **More accurate:** Uses `exactextractr` for partial pixel coverage
2. **No limits:** No radius restrictions (Tom Forth limits 3-50km)
3. **Batch processing:** Analyze hundreds of cities at once
4. **Offline capable:** Works without internet after data download
5. **Reproducible:** Script your analyses, share your methods
6. **Customizable:** Access raw data, create custom visualizations
7. **Free:** No server costs, open source

## Package Structure

```
worldpopulation/
├── R/                          # Package functions
│   ├── worldpopulation-package.R
│   ├── data_download.R         # GHS-POP data management
│   ├── population_analysis.R   # Core population functions
│   ├── batch_analysis.R        # Multi-city ranking/comparison
│   ├── city_data.R             # Built-in city dataset
│   ├── utilities.R             # Validation and helpers
│   └── globals.R               # Package environment
├── data/                       # Built-in datasets
│   └── world_cities.rda
├── data-raw/                   # Data processing scripts
│   └── cities.R
├── analysis/                   # Example analysis scripts
│   ├── 01_setup_and_download.R
│   ├── 02_top_cities_ranking.R
│   ├── 03_compare_major_cities.R
│   └── 04_visualization.R
├── vignettes/                  # Documentation
│   └── getting-started.Rmd
├── tests/                      # Unit tests
│   └── testthat/
├── man/                        # Generated documentation
├── DESCRIPTION                 # Package metadata
├── NAMESPACE                   # Exported functions
├── LICENSE                     # MIT License
├── README.md                   # This file
└── setup_package.R             # Initial setup script
```

## Development

### Running Tests

```r
devtools::test()
```

### Building Documentation

```r
devtools::document()
```

### Checking Package

```r
devtools::check()
```

## Contributing

Contributions are welcome! Please feel free to:

- Report bugs or issues
- Suggest new features
- Submit pull requests
- Improve documentation

## License

MIT License - see LICENSE file for details

## Citation

If you use this package in your research, please cite both the package and the underlying GHS-POP data:

**Package:**
```
Pete O. (2025). worldpopulation: Analyze Population Within Circles Around Global City Centers.
R package version 0.1.0. https://github.com/peteo/worldpopulation
```

**GHS-POP Data:**
```
Schiavina M., Freire S., MacManus K. (2023). GHS-POP R2023A - GHS population grid
multitemporal (1975-2030). European Commission, Joint Research Centre (JRC).
DOI: 10.2905/D6D86A90-4351-4508-99C1-CB074B022C4A
```

## Contact

- **Issues:** https://github.com/peteo/worldpopulation/issues
- **Email:** pete@example.com

## Acknowledgments

- **Tom Forth** for the original Circle Populations concept and inspiration
- **EC Joint Research Centre** for the GHS-POP data
- **Natural Earth** and **GeoNames** for city coordinate data
- The R spatial community (`terra`, `sf`, `exactextractr` authors)

---

**Note:** This package is for research and personal use. For commercial applications, please review the GHS-POP data license terms.
