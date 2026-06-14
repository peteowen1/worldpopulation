# Tests for utility functions

test_that("validate_coordinates works correctly", {
  # Valid coordinates should pass
  expect_true(worldpopulation:::validate_coordinates(51.5, -0.1))
  expect_true(worldpopulation:::validate_coordinates(0, 0))
  expect_true(worldpopulation:::validate_coordinates(-90, -180))
  expect_true(worldpopulation:::validate_coordinates(90, 180))

  # Invalid coordinates should error
  expect_error(worldpopulation:::validate_coordinates(91, 0))  # lat too high
  expect_error(worldpopulation:::validate_coordinates(-91, 0))  # lat too low
  expect_error(worldpopulation:::validate_coordinates(0, 181))  # lon too high
  expect_error(worldpopulation:::validate_coordinates(0, -181))  # lon too low
  expect_error(worldpopulation:::validate_coordinates(NA, 0))  # NA values
  expect_error(worldpopulation:::validate_coordinates("text", 0))  # non-numeric
})

test_that("check_radius works correctly", {
  # Valid radii should pass
  expect_true(worldpopulation:::check_radius(10))
  expect_true(worldpopulation:::check_radius(50))

  # Invalid radii should error
  expect_error(worldpopulation:::check_radius(0))  # zero
  expect_error(worldpopulation:::check_radius(-10))  # negative
  expect_error(worldpopulation:::check_radius(NA))  # NA
  expect_error(worldpopulation:::check_radius("text"))  # non-numeric

  # Should warn for very small radii
  expect_warning(worldpopulation:::check_radius(0.1))

  # Should warn for very large radii
  expect_warning(worldpopulation:::check_radius(150))
  expect_warning(worldpopulation:::check_radius(600))
})

test_that("validate_year works correctly", {
  # Valid years should pass
  expect_true(worldpopulation:::validate_year(2020))
  expect_true(worldpopulation:::validate_year(2025))

  # Should message for projection years
  expect_message(worldpopulation:::validate_year(2025))
  expect_message(worldpopulation:::validate_year(2030))

  # Invalid years should error
  expect_error(worldpopulation:::validate_year(2021))  # not available
  expect_error(worldpopulation:::validate_year(1950))  # too old
  expect_error(worldpopulation:::validate_year(2040))  # too far in future
  expect_error(worldpopulation:::validate_year(c(2020, 2025)))  # multiple values
})

test_that("format_population works correctly", {
  expect_equal(worldpopulation:::format_population(500), "500")
  expect_equal(worldpopulation:::format_population(1500), "1.5K")
  expect_equal(worldpopulation:::format_population(1500000), "1.5M")
  expect_equal(worldpopulation:::format_population(15000000), "15M")
})

test_that("get_cache_dir returns a valid path", {
  cache_dir <- get_cache_dir()
  expect_type(cache_dir, "character")
  expect_true(dir.exists(cache_dir))
})

test_that("estimate_download_size works", {
  expect_message(estimate_download_size("100m", 2025))
  expect_message(estimate_download_size("1km", 2020))
  expect_error(estimate_download_size("50m", 2025))  # invalid resolution
})
