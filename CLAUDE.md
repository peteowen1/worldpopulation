# CLAUDE.md

`worldpopulation` — R package for analyzing population within circles around global city centers using GHS-POP satellite data. Ranks cities by how much population is within N km of their center.

See `ARCHITECTURE.md` for module details, implementation notes, and maintenance guides.

## Core Commands

```r
devtools::load_all()    # Load package for development
devtools::document()    # Generate docs (never edit NAMESPACE manually)
devtools::check()       # Full package check
devtools::test()        # Run tests
source("data-raw/cities.R")  # Regenerate world_cities dataset
```


## Key Functions

- `population_in_circle(lat, lon, radius_km)` — atomic operation
- `rank_cities_by_population(cities, radius_km)` — main use case
- `compare_cities(cities, radii)` — multi-city, multi-radius profiles
- `download_ghspop_data(year, resolution)` — download rasters to user directory

**Note**: `R/hello.R` is leftover usethis boilerplate (`hello()` stub) — safe to delete.

## Data Storage

- **GHS-POP rasters**: `~/Documents/worldpopulation_data/` (300 MB to 12 GB depending on resolution)
- **Never in package** — CRAN packages must be < 5 MB
- **Built-in cities**: ~1,000 cities in `data/world_cities.rda`
- Users download rasters via `download_ghspop_data()` on first use

## Key Constraints

### CRS Handling
- User inputs: WGS84 (EPSG:4326) lat/lon
- GHS-POP uses two projections:
  - **Mollweide (54009)**: 100m, 1km — equal-area, best for population totals
  - **WGS84 (4326)**: 3ss, 30ss — standard lat/lon, pixel size varies by latitude
- Functions auto-detect raster CRS and transform buffers as needed

### Performance
- Use `exactextractr` over `terra::extract()` (7x faster, exact pixel coverage)
- Batch: create all sf buffers at once, single `exact_extract()` call
- Rasters cached in `.pkg_env` to avoid reloading

### R Package Rules
- Never manually edit NAMESPACE (roxygen2 generates it)
- All exported functions need roxygen2 docs with `@export`
- Use `@importFrom` for external functions in worldpopulation-package.R
- Functions belong in `R/` — even if only used by data-raw scripts (`@keywords internal @noRd`)
- Global variables in `globals.R` to avoid R CMD check NOTEs

### Testing
Tests focus on validation and data structure (no actual population extraction — requires 4.8 GB download). Use mocks and structure checks.
