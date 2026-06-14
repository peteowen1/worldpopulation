# Tests for data download functions

test_that("list_available_years returns expected values", {
  years <- list_available_years()

  expect_type(years, "double")
  expect_true(length(years) > 0)

  # Should include specific years
  expect_true(2020 %in% years)
  expect_true(2025 %in% years)

  # Should be in ascending order
  expect_equal(years, sort(years))
})

test_that("get_cached_data_path returns correct format", {
  # Should return NULL for non-existent data
  path <- get_cached_data_path(2025, "100m")
  expect_true(is.null(path) || file.exists(path))

  # Should return character path if exists
  if (!is.null(path)) {
    expect_type(path, "character")
    expect_true(grepl("\\.tif$", path))
  }
})

test_that("is_data_available returns logical", {
  result <- is_data_available(2025, "100m")
  expect_type(result, "logical")
  expect_length(result, 1)

  result2 <- is_data_available(2020, "1km")
  expect_type(result2, "logical")
  expect_length(result2, 1)
})

test_that("download_ghspop_data validates inputs", {
  # Should error on invalid year
  expect_error(download_ghspop_data(year = 2021, resolution = "100m"))

  # Should error on invalid resolution
  expect_error(download_ghspop_data(year = 2025, resolution = "50m"))

  # Note: We don't actually test the download here as it would take too long
  # and require internet connection. That's tested manually.
})

test_that("cache_info runs without error", {
  # Should run even if no cache exists
  expect_message(info <- cache_info())
})
