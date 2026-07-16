test_that("covariance estimators return finite symmetric matrices", {
  dat <- make_test_data()

  estimators <- list(
    sample = cov_sample(dat$X),
    ridge = cov_ridge(dat$X, lambda = 0.15),
    oas = cov_oas(dat$X),
    lw = cov_lw(dat$X),
    mec = cov_mec(dat$X, dat$y, nslices = 5)
  )

  for (estimate in estimators) {
    expect_symmetric_matrix(estimate)
    expect_true(all(is.finite(estimate)))
  }

  expect_true(attr(estimators$oas, "shrinkage") >= 0)
  expect_true(attr(estimators$oas, "shrinkage") <= 1)
  expect_true(attr(estimators$lw, "shrinkage") >= 0)
  expect_true(attr(estimators$lw, "shrinkage") <= 1)
  expect_true(attr(estimators$mec, "alpha") >= 0)
  expect_true(attr(estimators$mec, "alpha") <= 1)
})

test_that("covariance dispatcher covers every public method", {
  dat <- make_test_data()

  expect_equal(estimate_cov(dat$X, method = "sample"), cov_sample(dat$X))
  expect_equal(
    estimate_cov(dat$X, method = "ridge", lambda = 0.2),
    cov_ridge(dat$X, lambda = 0.2)
  )
  expect_equal(estimate_cov(dat$X, method = "oas"), cov_oas(dat$X))
  expect_equal(estimate_cov(dat$X, method = "lw"), cov_lw(dat$X))
  expect_error(estimate_cov(dat$X, method = "mec"), "must be supplied")
})

test_that("MEC accepts categorical and event-weighted survival responses", {
  dat <- make_test_data()
  group <- factor(rep(c("A", "B", "C"), length.out = nrow(dat$X)))
  event <- rep(c(0, 1), length.out = nrow(dat$X))
  time <- seq_len(nrow(dat$X))

  categorical <- cov_mec(
    dat$X,
    group,
    response_type = "categorical"
  )
  survival <- cov_mec(
    dat$X,
    time,
    response_type = "survival",
    delta = event,
    nslices = 4
  )

  expect_symmetric_matrix(categorical)
  expect_symmetric_matrix(survival)
  expect_error(
    cov_mec(dat$X, time, response_type = "survival"),
    "delta"
  )
})

test_that("stabilisation and covariance diagnostics are coherent", {
  Sigma <- matrix(c(1, 2, 2, 1), nrow = 2)

  eigenfloor <- stabilize_eigenfloor(Sigma, eps = 0.01)
  ridge <- stabilize_ridge(Sigma, lambda = 2)
  nearest <- stabilize_nearest_pd(Sigma)

  expect_gt(min(eigen(eigenfloor, symmetric = TRUE)$values), 0)
  expect_gt(min(eigen(ridge, symmetric = TRUE)$values), 0)
  expect_gt(min(eigen(nearest, symmetric = TRUE)$values), 0)

  diagnostics <- cov_diagnostics(eigenfloor)
  expect_named(
    diagnostics,
    c(
      "min_eigenvalue", "max_eigenvalue", "condition_number",
      "effective_rank", "eigenvalues"
    )
  )
  expect_equal(
    stabilize_cov(Sigma, method = "eigenfloor", eps = 0.01),
    eigenfloor
  )
})
