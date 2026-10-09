test_that("real-data wrapper cleans outcomes before screening and preserves core scores", {

  set.seed(20260830)

  n <- 100L
  p <- 16L

  X <- matrix(
    stats::rnorm(n * p),
    nrow = n,
    ncol = p
  )

  colnames(X) <- paste0("Gene", seq_len(p))

  X[, 15L] <- 0.001 * stats::rnorm(n)
  X[, 16L] <- 0.002 * stats::rnorm(n)

  eta <-
    0.8 * X[, 1L] -
    0.6 * X[, 2L] +
    0.4 * X[, 3L]

  time <- exp(
    5 +
    0.30 * eta +
    stats::rnorm(n, sd = 0.40)
  )

  delta <- as.integer(
    eta + stats::rnorm(n, sd = 0.70) > stats::median(eta)
  )

  time[c(3L, 11L)] <- NA_real_
  delta[25L] <- NA_integer_

  expected_complete <- stats::complete.cases(time, delta)

  fit <- fit_risdr_realdata(
    X = X,
    y = time,
    delta = delta,
    response_type = "survival",
    variance_quantile = 0.20,
    sdr_method = "sir",
    cov_method = "oas",
    nslices = 4L,
    d = NULL,
    d_max = 3L,
    selector = "cicomp",
    lambda_grid = c(0, 0.05, 0.10),
    adapt_weights = TRUE,
    weight_mode = "c1f",
    support_penalty = FALSE,
    standardize = TRUE,
    stabilize = TRUE
  )

  expect_identical(
    as.logical(fit$kept_rows),
    as.logical(expected_complete)
  )

  expect_equal(nrow(fit$filtered_predictors), sum(expected_complete))
  expect_identical(
    as.character(fit$kept_variables),
    colnames(fit$filtered_predictors)
  )
  expect_equal(
    unname(fit$reduced_predictors),
    unname(fit$fit$reduced_predictors),
    tolerance = 1e-12
  )

  B <- as.matrix(fit$fit$directions)
  expected_norm <- sqrt(rowSums(B^2))
  active <- which(expected_norm > 1e-8)
  expected_order <- active[
    order(expected_norm[active], decreasing = TRUE)
  ]

  expect_identical(
    as.integer(fit$selected_variables$index),
    as.integer(expected_order)
  )

  expect_equal(
    as.numeric(fit$selected_variables$loading_norm),
    as.numeric(expected_norm[expected_order]),
    tolerance = 1e-12
  )
})
