test_that("predictor and response validation rejects invalid inputs", {
  dat <- make_test_data()

  expect_error(cov_sample(dat$X[, 1L, drop = FALSE]), "at least 2")
  expect_error(cov_sample(dat$X[1:4, , drop = FALSE]), "at least 5")

  X_na <- dat$X
  X_na[1L, 1L] <- NA_real_
  expect_error(cov_sample(X_na), "missing")

  expect_error(
    fit_risdr(dat$X, dat$y, d = 1.5, d_max = 3),
    "positive integer"
  )
  expect_error(
    fit_risdr(dat$X, dat$y, nslices = 3.5, d_max = 3),
    "positive integer"
  )
  expect_error(
    fit_risdr(dat$X, dat$y, unknown_control = 2, d_max = 3),
    "Unused argument"
  )
})

test_that("quantile and equal-width slicing return valid labels", {
  y <- seq_len(60)

  quantile_slices <- make_slices(y, nslices = 6, type = "quantile")
  width_slices <- make_slices(y, nslices = 6, type = "equal_width")

  expect_length(quantile_slices, length(y))
  expect_setequal(unique(quantile_slices), 1:6)
  expect_setequal(unique(width_slices), 1:6)

  summary_table <- slice_summary(y, quantile_slices)
  expect_equal(sum(summary_table$n), length(y))
  expect_equal(sum(summary_table$proportion), 1)

  expect_error(make_slices(rep(1, 20), nslices = 4), "fewer unique")
})

test_that("slice moments and proportions agree with direct calculations", {
  dat <- make_test_data(n = 60)
  slices <- make_slices(dat$y, nslices = 4)

  means <- slice_means(dat$X, slices)
  covariances <- slice_covariances(dat$X, slices)
  proportions <- slice_proportions(slices)

  expect_equal(nrow(means), 4L)
  expect_length(covariances, 4L)
  expect_equal(sum(proportions), 1)
  expect_true(all(vapply(covariances, is.matrix, logical(1))))

  expect_error(slice_means(dat$X, slices[-1L]), "expected length")
})

test_that("fold allocation is reproducible and balanced", {
  folds_1 <- make_cv_folds(53, v = 5, seed = 11)
  folds_2 <- make_cv_folds(53, v = 5, seed = 11)

  expect_identical(folds_1, folds_2)
  expect_lte(max(table(folds_1)) - min(table(folds_1)), 1)
  expect_error(make_cv_folds(20.5, v = 5), "integer")
})
