test_that("response slicing handles ties, classes and absent censoring groups", {
  expect_identical(slice_response(rep(3, 12), nslices = 4)$groups, rep(1L, 12))
  y <- rep(c("b", "a", "c"), 4)
  categorical <- slice_response(y, response_type = "categorical")
  expect_identical(categorical$groups, as.integer(factor(y)))
  expect_equal(categorical$nslices, 3)
  for (status in c(0L, 1L)) {
    sliced <- slice_response(rep(5, 12), response_type = "survival",
      delta = rep(status, 12))
    expect_identical(sliced$groups, rep(1L, 12))
    expect_equal(sliced$nslices, 1)
  }
  expect_error(slice_response(1:12, nslices = 0), "positive integer")
  expect_error(slice_response(y), "numeric")
  expect_error(slice_response(c(1, NA_real_)), "missing")
  expect_error(slice_response(c("a", NA), response_type = "categorical"), "missing")
  expect_error(slice_response(y, response_type = "survival"), "numeric")
  expect_error(slice_response(1:12, response_type = "survival"), "supplied")
  expect_error(slice_response(1:12, response_type = "survival", delta = 1), "same length")
  expect_error(slice_response(1:12, response_type = "survival",
    delta = c(NA, rep(1, 11))), "complete")
  expect_error(slice_response(c(0, 2), response_type = "survival", delta = c(0, 1)),
    "strictly positive")
  expect_error(slice_response(1:12, response_type = "survival", delta = rep(2, 12)), "0/1")
})

test_that("sparse fitting rejects malformed inputs before numerical fitting", {
  dat <- thesis_coverage_data()
  fit <- function(...) fit_risdr_sparse(dat$X, dat$y, ...)
  expect_error(fit_risdr_sparse(matrix("a", 8, 2), 1:8), "numeric")
  expect_error(fit_risdr_sparse(dat$X[1:2, ], dat$y[1:2]), "three rows")
  bad <- dat$X; bad[1, 1] <- NA_real_
  expect_error(fit_risdr_sparse(bad, dat$y), "finite")
  bad[1, 1] <- Inf
  expect_error(fit_risdr_sparse(bad, dat$y), "finite")
  expect_error(fit(stabilize = FALSE), "stabilize")
  expect_error(fit(complexity = "other"), "C1F")
  expect_error(fit_risdr_sparse(dat$X, dat$y[-1L]), "Length")
  expect_error(fit_risdr_sparse(dat$X, replace(dat$y, 1, NA)), "missing")
  expect_error(fit_risdr_sparse(dat$X, replace(dat$y, 1, Inf)), "finite")
  expect_error(fit(response_type = "survival"), "delta")
  expect_error(fit(response_type = "survival", delta = dat$delta[-1]), "complete")
  expect_error(fit(response_type = "survival", delta = replace(dat$delta, 1, NA)), "complete")
  expect_error(fit(response_type = "survival", delta = rep(2, 60)), "0/1")
  expect_error(fit_risdr_sparse(dat$X, replace(dat$time, 1, 0),
    response_type = "survival", delta = dat$delta), "strictly positive")
  expect_error(fit(response_type = "categorical", sdr_method = "phd"), "restricted")
  expect_error(fit(nslices = 0), "nslices")
  expect_error(fit(d_max = 0), "d_max")
  expect_error(fit(d = 3, d_max = 2), "Explicit")
  for (grid in list(numeric(0), -1, NA_real_, Inf)) {
    expect_error(fit(lambda_grid = grid), "lambda_grid")
  }
  expect_error(fit(support_penalty = NA), "support_penalty")
  bad_names <- dat$X; colnames(bad_names)[2] <- colnames(bad_names)[1]
  expect_error(fit_risdr_sparse(bad_names, dat$y), "unique")
  colnames(bad_names)[2] <- ""
  expect_error(fit_risdr_sparse(bad_names, dat$y), "non-empty")
})

test_that("PCA scores reconstruct the retained subspace and variance threshold", {
  X <- rbind(cbind(large = c(-3, 3, -3, 3), small = c(-1, -1, 1, 1)),
             cbind(large = c(-3, 3, -3, 3), small = c(-1, -1, 1, 1)))
  full <- dual_pca_scores(X, scale_X = FALSE)
  expect_equal(full$dual_rank, 2L)
  expect_equal(X %*% full$loadings, full$scores, tolerance = 1e-10,
               ignore_attr = TRUE)
  expect_equal(crossprod(full$loadings), diag(2), tolerance = 1e-10,
               ignore_attr = TRUE)
  expect_equal(full$scores %*% t(full$loadings), X, tolerance = 1e-10,
               ignore_attr = TRUE)
  selected <- dual_pca_scores(X, variance_explained = 0.85, scale_X = FALSE)
  expect_equal(selected$dual_rank, 1L)
  expect_equal(sum(selected$eigenvalues) / sum(full$eigenvalues), 0.9,
               tolerance = 1e-10)
  raw <- dual_pca_scores(X + 2, dual_rank = 2, center = FALSE, scale_X = FALSE)
  expect_equal(raw$center, c(0, 0))
  expect_equal(raw$scale, c(1, 1))
  expect_equal((X + 2) %*% raw$loadings, raw$scores, tolerance = 1e-10,
               ignore_attr = TRUE)
  constant_column <- dual_pca_scores(cbind(X, constant = 5))
  expect_equal(unname(constant_column$scale[3]), 1)
  expect_error(dual_pca_scores(matrix("a", 6, 2)), "numeric")
  expect_error(dual_pca_scores(matrix(0, 6, 2)), "No positive")
  expect_error(dual_pca_scores(X, variance_explained = 0), "variance_explained")
})

test_that("dual fitting cleans outcomes and supports unscaled quantile ranking", {
  dat <- thesis_coverage_data()
  y <- dat$y; y[3] <- NA_real_
  messages <- capture.output(
    fit <- fit_risdr_dual(dat$X, y, dual_rank = 4, d_max = 2,
      sdr_method = "sir", cov_method = "sample", nslices = 3,
      lambda_grid = c(0, 0.03), standardize_dual = FALSE,
      scale_X = FALSE, gene_select_quantile = 0.5, verbose = TRUE),
    type = "message")
  expect_true(any(grepl("completed", messages)))
  expect_identical(fit$kept_rows, !is.na(y))
  expect_equal(nrow(fit$reduced_predictors), 59L)
  expect_match(fit$gene_direction_scale, "centred")
  expect_equal(fit$selected_dual_directions_input_scale, fit$fit_dual$directions)
  expect_equal(unname(predict(fit, dat$X[-3, ], type = "scores")),
               unname(fit$reduced_predictors), tolerance = 1e-10)
  cutoff <- stats::quantile(sqrt(rowSums(fit$selected_gene_directions^2)), 0.5)
  expect_true(all(fit$selected_variables$loading_norm >= cutoff))
  capture.output(returned <- print(fit))
  expect_identical(returned, fit)
  capture.output(returned <- summary(fit, top_n = 2))
  expect_identical(returned, fit)
  expect_error(fit_risdr_dual(matrix("a", 8, 2), 1:8), "numeric")
  expect_error(fit_risdr_dual(dat$X, dat$y[-1]), "Length")
  unnamed <- dat$X; colnames(unnamed) <- NULL
  expect_error(fit_risdr_dual(unnamed, dat$y), "predictor names")
  expect_error(fit_risdr_dual(dat$X, dat$time, response_type = "survival"), "delta")
  expect_error(fit_risdr_dual(dat$X, dat$y, gene_select_top = 0), "positive integer")
  expect_error(fit_risdr_dual(dat$X, dat$y, gene_select_quantile = 2), "gene_select_quantile")
  expect_error(fit_risdr_dual(dat$X, rep(NA_real_, 60), verbose = FALSE), "Too few")
})

test_that("screened wrapper supports categorical aliases and unnamed predictors", {
  dat <- thesis_coverage_data()
  X <- dat$X; colnames(X) <- NULL
  for (response in c("continuous", "binary", "multiclass")) {
    y <- switch(response, continuous = dat$y, binary = dat$binary,
                multiclass = dat$category)
    y[2] <- NA
    fit <- fit_risdr_sparse_realdata(X, y, response_type = response,
      variance_quantile = 0.1, sdr_method = "sir", cov_method = "oas",
      d_max = 2, nslices = 3, lambda_grid = c(0, 0.03))
    expect_identical(fit$kept_rows, !is.na(y))
    expect_equal(nrow(fit$reduced_predictors), 59L)
    expect_true(all(grepl("^X", fit$kept_variables)))
    expect_identical(fit$core_response_type,
      if (response == "continuous") "continuous" else "categorical")
    capture.output(returned <- print(fit))
    expect_identical(returned, fit)
    capture.output(returned <- print(fit$fit))
    expect_identical(returned, fit$fit)
    report <- summary(fit$fit)
    expect_s3_class(report, "summary.risdr_sparse")
    expect_equal(report$selected_dimension, fit$fit$d)
    eig <- eigen(fit$fit$Sigma, symmetric = TRUE, only.values = TRUE)$values
    expect_equal(report$covariance_diagnostics$condition_number, max(eig) / min(eig))
    expect_equal(report$covariance_diagnostics$effective_rank, sum(eig > 1e-6))
    capture.output(returned <- print(report))
    expect_identical(returned, report)
  }
  expect_error(fit_risdr_sparse_realdata(matrix("a", 8, 2), 1:8), "numeric")
  expect_error(fit_risdr_sparse_realdata(X, dat$y[-1]), "Length")
  expect_error(fit_risdr_sparse_realdata(X, dat$y, variance_quantile = 1), "variance_quantile")
  expect_error(fit_risdr_sparse_realdata(X, rep(NA_real_, 60)), "Too few")
  colnames(X) <- rep("same", ncol(X))
  expect_error(fit_risdr_sparse_realdata(X, dat$y), "unique")
})

test_that("sparse grid supports historical kernels and weight normalisation", {
  V <- matrix(c(0.8, 0.6, 0, 0, 0.6, 0.8), nrow = 3)
  direct <- fit_sparse_grid(directions = V, d = 2, lambda_grid = c(0, 0.2))
  expect_equal(fit_sparse_grid(kernel_obj = list(directions = V), d = 2,
    lambda_grid = c(0, 0.2))$fits, direct$fits)
  expect_equal(fit_sparse_grid(kernel_obj = list(vectors = V), d = 2,
    lambda_grid = c(0, 0.2))$fits, direct$fits)
  expect_warning(fallback <- fit_sparse_grid(directions = V, d = 2,
    lambda_grid = c(0, 0.2), adapt_weights = TRUE), "uniform weights")
  expect_equal(fallback$fits, direct$fits)
  weighted <- fit_sparse_grid(directions = V, d = 2, lambda_grid = 0.2,
    penalty_weights = 2)
  expect_equal(weighted$penalty_weights, rep(1, 3))
  expect_equal(weighted_soft_threshold(c(-2, 0.2, 3), 0.5), c(-1.5, 0, 2.5))
  expect_equal(weighted_soft_threshold(c(-2, 0.2, 3), 0,
    weights = numeric(0)), c(-2, 0.2, 3))
  expect_equal(weighted_soft_threshold(c(-2, 0.2, 3), 0,
    weights = c(1, 2)), c(-2, 0.2, 3))
  fallback_dense <- weighted_sparsify_directions(V, lambda = 100)
  expect_equal(colSums(fallback_dense^2), c(1, 1))
  expect_equal(weighted_sparsify_directions(matrix(0, 3, 1), lambda = 1),
               matrix(0, 3, 1))
  expect_error(fit_sparse_grid(), "Supply")
  expect_error(fit_sparse_grid(kernel_obj = list()), "recognised")
  expect_error(fit_sparse_grid(directions = V, d = 3), "dimension")
  expect_error(fit_sparse_grid(directions = V, lambda_grid = -1), "lambda_grid")
  expect_error(weighted_soft_threshold(1:3, -1), "lambda")
  expect_error(weighted_sparsify_directions(matrix("a", 3, 2), 0.1), "numeric")
})
