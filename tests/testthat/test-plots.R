test_that("plotting functions return their plotted data invisibly", {
  dat <- make_test_data()
  fit <- fit_risdr(dat$X, dat$y, d = 2, d_max = 3, nslices = 5)
  predictions <- predict(fit, dat$X)
  cv <- select_dimension_cv(
    dat$X,
    dat$y,
    sdr_method = "sir",
    cov_method = "oas",
    d_max = 2,
    v = 3,
    nslices = 5,
    seed = 43
  )
  ladle <- select_dimension_ladle(
    dat$X,
    dat$y,
    sdr_method = "sir",
    cov_method = "oas",
    d_max = 2,
    B = 3,
    nslices = 5,
    seed = 43
  )

  file <- tempfile(fileext = ".pdf")
  grDevices::pdf(file)
  on.exit({
    grDevices::dev.off()
    unlink(file)
  }, add = TRUE)

  expect_length(plot_scree(fit, n_eigen = 3), 3L)
  expect_equal(nrow(plot_sufficient(fit)), nrow(dat$X))
  expect_equal(nrow(plot_sufficient2d(fit)), nrow(dat$X))
  expect_equal(nrow(plot_loadings(fit, top = 4)), ncol(dat$X))
  expect_equal(nrow(plot_prediction(dat$y, predictions)), nrow(dat$X))
  expect_equal(nrow(plot_residuals(dat$y, predictions)), nrow(dat$X))
  expect_equal(nrow(plot_dimension_selection(fit)), 3L)
  expect_equal(nrow(plot_cv_dimension(cv)), 2L)
  expect_equal(nrow(plot_ladle(ladle)), 2L)
})
