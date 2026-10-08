survival_example <- function(n = 80, p = 8) {
  set.seed(2026)
  X <- matrix(stats::rnorm(n * p), n)
  colnames(X) <- paste0("G", seq_len(p))
  event <- stats::rexp(n, rate = exp(0.5 * X[, 1]))
  censor <- stats::rexp(n, rate = 0.5)
  list(X = X, time = pmin(event, censor), delta = as.integer(event <= censor))
}

test_that("sparse predictions reproduce training scores and downstream Cox risks", {
  dat <- survival_example()
  fit <- fit_risdr_sparse(dat$X, dat$time, delta = dat$delta,
    response_type = "survival", sdr_method = "sir", cov_method = "oas",
    nslices = 4, d_max = 3, lambda_grid = c(0, 0.05))
  expect_equal(unname(predict(fit, dat$X, type = "scores")),
               unname(fit$reduced_predictors), tolerance = 1e-12)
  expect_equal(unname(predict(fit, dat$X, type = "risk")),
               unname(stats::predict(fit$downstream_fit, type = "risk")), tolerance = 1e-12)
  one <- dat$X[1, rev(seq_len(ncol(dat$X))), drop = FALSE]
  expect_equal(unname(predict(fit, one, type = "risk")),
               unname(predict(fit, dat$X[1, , drop = FALSE], type = "risk")))
  wrong <- one; colnames(wrong)[1] <- "unknown"
  expect_error(predict(fit, wrong), "names")
  expect_error(predict(fit, one, type = "class"), "Survival")
})

test_that("dual predictions reproduce selected training coordinates", {
  dat <- survival_example()
  fit <- fit_risdr_dual(dat$X, dat$time, delta = dat$delta,
    response_type = "survival", dual_rank = 5, d_max = 3,
    sdr_method = "sir", cov_method = "oas", lambda_grid = c(0, 0.05), verbose = FALSE)
  expect_equal(unname(predict(fit, dat$X, type = "scores")),
               unname(fit$reduced_predictors), tolerance = 1e-10)
  expect_equal(unname(predict(fit, dat$X, type = "risk")),
               unname(stats::predict(fit$fit_dual$downstream_fit, type = "risk")),
               tolerance = 1e-10)
})

test_that("the sparse engine predicts continuous and categorical outcomes", {
  dat <- survival_example()
  args <- list(X = dat$X, sdr_method = "sir", cov_method = "oas", d = 1,
               d_max = 2, lambda_grid = c(0, 0.05))
  continuous <- do.call(fit_risdr_sparse, c(args, list(y = dat$X[, 1] + stats::rnorm(80))))
  expect_equal(unname(predict(continuous, dat$X)),
               unname(stats::predict(continuous$downstream_fit)), tolerance = 1e-12)
  binary <- do.call(fit_risdr_sparse, c(args, list(y = factor(dat$delta), response_type = "categorical")))
  probability <- predict(binary, dat$X, type = "probs")
  expect_true(all(probability >= 0 & probability <= 1))
  expect_s3_class(predict(binary, dat$X, type = "class"), "factor")
  multiclass <- do.call(fit_risdr_sparse, c(args,
    list(y = factor(rep(c("a", "b", "c", "b"), 20)), response_type = "categorical")))
  expect_equal(rowSums(predict(multiclass, dat$X, type = "probs")), rep(1, 80),
               tolerance = 1e-10, ignore_attr = TRUE)
})
