test_that("continuous fit_risdr core returns the unified object contract", {

  set.seed(123)

  n <- 60L
  p <- 10L

  X <- matrix(
    stats::rnorm(n * p),
    nrow = n,
    ncol = p
  )

  colnames(X) <- paste0("X", seq_len(p))

  y <-
    X[, 1L] -
    X[, 2L] +
    0.4 * X[, 3L]^2 +
    stats::rnorm(n, sd = 0.5)

  lambda_grid <- c(0, 0.05, 0.10)

  fit <- fit_risdr(
    X = X,
    y = y,
    response_type = "continuous",
    sdr_method = "sir",
    cov_method = "oas",
    nslices = 4L,
    d = NULL,
    d_max = 3L,
    selector = "cicomp",
    lambda_grid = lambda_grid,
    adapt_weights = TRUE,
    weight_mode = "c1f",
    support_penalty = FALSE,
    standardize = TRUE,
    stabilize = TRUE
  )

  expect_s3_class(fit, "risdr")
  expect_identical(as.integer(fit$d_candidates), 1:3)
  expect_equal(nrow(fit$selection_grid), 3L * length(lambda_grid))
  expect_equal(nrow(fit$d_table), 3L)
  expect_true(length(fit$best_lambda) == 1L)
  expect_true(fit$best_lambda %in% lambda_grid)
  expect_equal(fit$d, unname(fit$criterion_dimensions["CICOMP"]))
  expect_equal(
    fit$best_lambda,
    unname(fit$criterion_lambdas["CICOMP"]),
    tolerance = 1e-14
  )
  expect_equal(ncol(fit$directions), fit$d)
  expect_equal(ncol(fit$reduced_predictors), fit$d)
  expect_equal(nrow(fit$reduced_predictors), n)
  expect_s3_class(fit$downstream_fit, "lm")
})
