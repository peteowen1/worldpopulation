# Tests for city data functions

test_that("load_world_cities returns expected structure", {
  skip_if_not(exists("world_cities"), "world_cities dataset not available")

  cities <- load_world_cities()

  expect_s3_class(cities, "data.frame")
  expect_true(nrow(cities) > 0)

  # Check required columns
  expected_cols <- c("city", "lat", "lon", "country", "iso2", "iso3", "population")
  expect_true(all(expected_cols %in% names(cities)))

  # Check data types
  expect_type(cities$city, "character")
  expect_type(cities$lat, "double")
  expect_type(cities$lon, "double")
  expect_type(cities$population, "double")

  # Check coordinate ranges
  expect_true(all(cities$lat >= -90 & cities$lat <= 90))
  expect_true(all(cities$lon >= -180 & cities$lon <= 180))

  # Check population is positive
  expect_true(all(cities$population > 0))
})

test_that("filter_cities_by_country works", {
  skip_if_not(exists("world_cities"), "world_cities dataset not available")

  # Filter by ISO2 code
  us_cities <- filter_cities_by_country("US")
  expect_s3_class(us_cities, "data.frame")
  if (nrow(us_cities) > 0) {
    expect_true(all(us_cities$iso2 == "US"))
  }

  # Filter by multiple countries
  cities <- filter_cities_by_country(c("GB", "FR", "DE"))
  if (nrow(cities) > 0) {
    expect_true(all(cities$iso2 %in% c("GB", "FR", "DE")))
  }

  # Warn if no cities found
  expect_warning(filter_cities_by_country("ZZZ"))
})

test_that("filter_cities_by_population works", {
  skip_if_not(exists("world_cities"), "world_cities dataset not available")

  # Filter cities over 1 million
  big_cities <- filter_cities_by_population(1e6)
  expect_s3_class(big_cities, "data.frame")

  if (nrow(big_cities) > 0) {
    expect_true(all(big_cities$population >= 1e6))
  }

  # Filter cities over 10 million
  mega_cities <- filter_cities_by_population(10e6)
  if (nrow(mega_cities) > 0) {
    expect_true(all(mega_cities$population >= 10e6))
    expect_true(nrow(mega_cities) <= nrow(big_cities))
  }

  # Should error on invalid input
  expect_error(filter_cities_by_population(-1000))
  expect_error(filter_cities_by_population("text"))
})

test_that("get_top_cities works", {
  skip_if_not(exists("world_cities"), "world_cities dataset not available")

  # Get top 10
  top_10 <- get_top_cities(10)
  expect_s3_class(top_10, "data.frame")
  expect_equal(nrow(top_10), min(10, nrow(load_world_cities())))

  # Should be sorted by population descending
  expect_true(all(diff(top_10$population) <= 0))

  # Get top 50
  top_50 <- get_top_cities(50)
  expect_equal(nrow(top_50), min(50, nrow(load_world_cities())))

  # Should error on invalid input
  expect_error(get_top_cities(-10))
  expect_error(get_top_cities("text"))
})
