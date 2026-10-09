test_that("MEC covariance is translation and scale equivariant for full-rank slices", {
  dat <- thesis_coverage_data()
  cases <- list(
    continuous = list(y = dat$y, delta = NULL),
    categorical = list(y = dat$category, delta = NULL),
    survival = list(y = dat$time, delta = rep(c(0L, 1L), 30L))
  )
  for (response in names(cases)) {
    args <- c(cases[[response]], list(response_type = response, nslices = 3L))
    S <- do.call(risdr:::.thesis_cov_mec, c(list(X = dat$X), args))
    shifted <- do.call(risdr:::.thesis_cov_mec, c(list(X = dat$X + 7), args))
    scaled <- do.call(risdr:::.thesis_cov_mec, c(list(X = 2 * dat$X), args))
    expect_equal(as.vector(shifted), as.vector(S), tolerance = 1e-10)
    expect_equal(as.vector(scaled), 4 * as.vector(S), tolerance = 1e-9)
    expect_equal(S, t(S), ignore_attr = TRUE, tolerance = 1e-12)
    expect_gt(min(eigen(S, symmetric = TRUE, only.values = TRUE)$values), 0)
    expect_equal(sum(attr(S, "slice_counts")), nrow(dat$X))
    expect_equal(length(attr(S, "slice_entropy")), attr(S, "realised_slices"))
    expect_identical(attr(S, "response_type"), response)
    fit <- fit_risdr_sparse(dat$X, y = cases[[response]]$y,
      delta = cases[[response]]$delta, response_type = response,
      sdr_method = "sir", cov_method = "mec", nslices = 3L,
      d_max = 2L, lambda_grid = c(0, 0.03))
    expect_identical(attr(fit$Sigma, "method"), "mec")
    expect_true(all(fit$selection_grid$valid))
    expect_true(all(is.finite(predict(fit, dat$X, type = "scores"))))
  }
})

test_that("MEC handles singleton slices and rejects unidentifiable slice covariance", {
  dat <- thesis_coverage_data()
  groups <- factor(c("singleton", rep("large", nrow(dat$X) - 1L)))
  S <- risdr:::.thesis_cov_mec(dat$X, groups, response_type = "categorical")
  expect_true(all(is.finite(S)))
  expect_true(any(attr(S, "slice_counts") == 1L))
  expect_error(risdr:::.thesis_cov_mec(dat$X, dat$y[-1L]), "Length")
  expect_error(risdr:::.thesis_cov_mec(dat$X, seq_len(nrow(dat$X)),
    nslices = nrow(dat$X)), "Too few observations")
  expect_error(risdr:::.thesis_cov_mec(matrix(0, 20L, 3L), 1:20,
    nslices = 2L), "positive-eigenvalue")
})

test_that("covariance dispatch preserves sample, ridge, LW and user conventions", {
  dat <- thesis_coverage_data()
  sample <- risdr:::.thesis_estimate_cov(dat$X, method = "sample")
  ridge <- risdr:::.thesis_estimate_cov(dat$X, method = "ridge", shrinkage = 0.2)
  expect_equal(as.vector(sample), as.vector(stats::cov(dat$X)), tolerance = 1e-10)
  expect_equal(as.vector(ridge), as.vector(stats::cov(dat$X) + 0.2 * diag(6)),
               tolerance = 1e-10)
  lw <- risdr:::.thesis_estimate_cov(dat$X, method = "lw")
  lw_shifted <- risdr:::.thesis_estimate_cov(dat$X + 5, method = "lw")
  expect_equal(as.vector(lw), as.vector(lw_shifted), tolerance = 1e-10)
  expect_true(attr(lw, "rho") >= 0 && attr(lw, "rho") <= 1)
  expect_gt(min(eigen(lw, symmetric = TRUE, only.values = TRUE)$values), 0)
  zero <- risdr:::.thesis_cov_lw(matrix(0, 12, 3))
  expect_equal(attr(zero, "rho"), 1)
  expect_equal(as.vector(zero), rep(0, 9))
  for (stabilization in c("eigenfloor", "ridge", "nearest_pd")) {
    user <- risdr:::.thesis_estimate_cov(dat$X, method = "user",
      cov_fun = function(X, ...) diag(ncol(X)), stabilization = stabilization,
      shrinkage = 0.2)
    expected <- if (stabilization == "ridge") 1.2 else 1
    expect_equal(diag(user), rep(expected, 6), tolerance = 1e-8)
    expect_identical(attr(user, "method"), "user")
    expect_true(is.na(attr(user, "rho")))
  }
  expect_error(risdr:::.thesis_estimate_cov(dat$X, method = "user"), "cov_fun")
  expect_error(risdr:::.thesis_estimate_cov(dat$X, method = "user",
    cov_fun = function(...) 1), "return a matrix")
  singular <- matrix(c(1, 2, 2, 1), 2)
  repaired <- risdr:::.thesis_stabilize_cov(singular, method = "nearest_pd")
  expect_equal(diag(repaired), diag(singular), tolerance = 1e-8)
  expect_gt(min(eigen(repaired, symmetric = TRUE, only.values = TRUE)$values), 0)
  expect_error(risdr:::.thesis_stabilize_ridge(diag(2), lambda = -1), "lambda")
  expect_error(risdr:::.thesis_stabilize_eigenfloor(diag(2), eps = 0), "eps")
})

test_that("C1F weighting handles equal spectra and all documented modes", {
  empty <- C1F(c(0, -1))
  expect_equal(empty$c1f, 0)
  expect_equal(empty$weights, 1)
  expect_length(empty$evals, 0L)
  expect_equal(C1F(rep(2, 4))$weights, rep(0.25, 4))
  expect_equal(C1F(c(5, 3, 1), cumulative = FALSE)$c1f, 2 / 9)
  expect_equal(C1F(c(-1, 1), positive_only = FALSE, cumulative = FALSE)$c1f, 0)
  S <- diag(c(5, 3, 1))
  w <- compute_penalty_weights(S, mode = "c1f")
  inverse <- compute_penalty_weights(S, mode = "inverse_c1f")
  expect_equal(mean(w), 1)
  expect_equal(mean(inverse), 1)
  expect_equal(inverse, (1 / w) / mean(1 / w), tolerance = 1e-12)
  expect_equal(compute_penalty_weights(S, "uniform"), rep(1, 3))
  expect_equal(compute_penalty_weights(matrix(0, 3, 3)), rep(1, 3))
  expect_error(compute_penalty_weights(matrix(1, 2, 3)), "square")
  expect_error(risdr:::.thesis_c1f_variable_contributions(matrix(1, 2, 3)), "square")
})

test_that("criterion selectors agree with likelihoods and active-support penalties", {
  dat <- thesis_coverage_data()
  Z <- dat$X[, 1:2, drop = FALSE]
  values <- compute_ic_values(dat$y, Z)
  fit <- stats::lm(dat$y ~ Z)
  ll <- as.numeric(stats::logLik(fit))
  expect_equal(unname(values["logLik"]), ll, tolerance = 1e-12)
  expect_equal(unname(values["k_eff"]), 3)
  expect_equal(unname(values["AIC"]), -2 * ll + 6)
  expect_equal(unname(values["BIC"]), -2 * ll + log(60) * 3)
  expect_equal(unname(values["CAIC"]), -2 * ll + (log(60) + 1) * 3)
  for (criterion in c("aic", "bic", "caic", "icomp", "cicomp")) {
    expect_equal(compute_ic(dat$y, Z, criterion), unname(values[toupper(criterion)]))
  }
  penalised <- compute_ic_values(dat$y, Z, support_penalty = TRUE, n_active = 4)
  expect_equal(unname(penalised["k_eff"]), 7)
  expect_equal(unname(penalised["AIC"] - values["AIC"]), 8)
  expect_equal(unname(penalised["C1F"]), unname(values["C1F"]))
  zero <- compute_ic_values(dat$y, matrix(0, 60, 1))
  expect_equal(unname(zero["C1F"]), 0)
  degenerate <- compute_ic_values(dat$y, matrix(0, 60, 2))
  expect_equal(unname(degenerate["C1F"]), 0)
  expect_error(compute_ic_values(dat$y[-1], Z), "Length")
  expect_error(compute_ic_values(dat$y, Z, n_active = -1,
    support_penalty = TRUE), "non-negative")
  expect_error(compute_ic_values(rep("a", 60), Z,
    response_type = "categorical"), "at least two classes")
  expect_error(compute_ic_values(dat$time, Z, response_type = "survival"), "delta")
  expect_error(compute_ic_values(dat$time, Z, response_type = "survival",
    delta = dat$delta[-1]), "length")
  expect_error(compute_ic_values(dat$time, Z, response_type = "survival",
    delta = rep(2L, 60)), "0/1")
})

test_that("pHd scores and equal-width kernels obey the documented projection", {
  dat <- thesis_coverage_data()
  S <- stats::cov(dat$X)
  phd <- risdr:::.thesis_compute_sdr(dat$X, dat$y, method = "phd")
  Z <- risdr:::.thesis_standardize_by_cov(dat$X, S)$Z
  reference <- crossprod(Z, sweep(Z, 1, dat$y - mean(dat$y), "*")) / 60
  expect_equal(phd$kernel, reference, tolerance = 1e-10, ignore_attr = TRUE)
  expect_true(all(diff(abs(phd$eigenvalues)) <= 1e-10))
  expect_equal(phd$scores, sweep(dat$X, 2, colMeans(dat$X), "-") %*% phd$directions,
               tolerance = 1e-10)
  fit <- fit_risdr_sparse(dat$X, dat$y, sdr_method = "phd", cov_method = "lw",
    d = 1L, d_max = 2L, standardize = FALSE, adapt_weights = FALSE,
    lambda_grid = c(0, 0.03))
  expect_equal(unname(predict(fit, dat$X, type = "scores")),
               unname(fit$reduced_predictors), tolerance = 1e-10)
  for (method in c("sir", "save", "dr")) {
    kernel <- risdr:::.thesis_compute_sdr(dat$X, dat$y, method = method,
      nslices = 3, slice_type = "equal_width")
    expect_equal(kernel$kernel, t(kernel$kernel), tolerance = 1e-12)
    expect_true(all(is.finite(kernel$scores)))
  }
  expect_error(risdr:::.thesis_compute_sdr(dat$X, dat$category,
    method = "phd", response_type = "categorical"), "restricted")
})
