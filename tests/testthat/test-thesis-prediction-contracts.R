test_that("prediction aliases and rejected types follow each outcome model", {
  dat <- thesis_coverage_data()
  args <- list(X = dat$X, sdr_method = "sir", cov_method = "oas",
               d = 1, d_max = 2, lambda_grid = c(0, 0.03))
  continuous <- do.call(fit_risdr_sparse, c(args, list(y = dat$y)))
  expect_equal(predict(continuous, dat$X, type = "link"), predict(continuous, dat$X))
  expect_error(predict(continuous, dat$X, type = "probs"), "Continuous")
  survival <- do.call(fit_risdr_sparse, c(args,
    list(y = dat$time, delta = dat$delta, response_type = "survival")))
  expect_equal(predict(survival, dat$X), predict(survival, dat$X, type = "risk"))
  expect_equal(unname(predict(survival, dat$X, type = "link")),
               unname(stats::predict(survival$downstream_fit, type = "lp")),
               tolerance = 1e-12)
  binary <- do.call(fit_risdr_sparse, c(args,
    list(y = dat$binary, response_type = "categorical")))
  link <- predict(binary, dat$X, type = "link")
  probability <- predict(binary, dat$X, type = "probs")
  expect_equal(unname(stats::plogis(link)), unname(probability), tolerance = 1e-12)
  expect_error(predict(binary, dat$X, type = "risk"), "categorical")
  multiclass <- do.call(fit_risdr_sparse, c(args,
    list(y = dat$category, response_type = "categorical")))
  expect_identical(predict(multiclass, dat$X), predict(multiclass, dat$X, type = "class"))
  expect_error(predict(multiclass, dat$X, type = "link"), "Multiclass")
})

test_that("prediction validates complete columns and retains unnamed column order", {
  dat <- thesis_coverage_data()
  fit <- fit_risdr_sparse(dat$X, dat$y, sdr_method = "sir", cov_method = "oas",
    d = 1, d_max = 2, lambda_grid = 0)
  X <- dat$X[1:3, , drop = FALSE]
  unnamed <- X; colnames(unnamed) <- NULL
  expect_equal(predict(fit, unnamed), predict(fit, X))
  expect_equal(predict(fit, as.data.frame(X)), predict(fit, X))
  expect_error(predict(fit, X[, -1, drop = FALSE]), "all training")
  duplicate <- X; colnames(duplicate)[2] <- colnames(duplicate)[1]
  expect_error(predict(fit, duplicate), "names")
  for (bad in list(matrix("a", 3, 6), matrix(NA_real_, 3, 6),
                  matrix(Inf, 3, 6), matrix(numeric(0), 0, 6))) {
    expect_error(predict(fit, bad), "finite numeric")
  }
})
