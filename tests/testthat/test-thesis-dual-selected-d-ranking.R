# Generated from the frozen permanent regression tests.

test_that("dual explicit-d ranking uses selected sparse mapped directions", {
    set.seed(20260828)
    n <- 90L
    p <- 24L
    X <- matrix(stats::rnorm(n * p), nrow = n, ncol = p)
    colnames(X) <- paste0("G", seq_len(p))
    y <- 1.5 * X[, 1L] - 0.8 * X[, 2L] + 0.6 * X[, 3L]^2 + stats::rnorm(n, sd = 0.5)
    fit <- fit_risdr_dual(X = X, y = y, response_type = "continuous", dual_rank = 8L, d = 2L,
        d_max = 4L, nslices = 4L, sdr_method = "sir", cov_method = "oas", selector = "cicomp",
        lambda_grid = c(0, 0.05, 0.1), adapt_weights = TRUE, weight_mode = "c1f", support_penalty = FALSE,
        standardize_dual = TRUE, gene_select_top = 10L, verbose = FALSE)
    expect_equal(fit$requested_d, 2L)
    expect_equal(fit$d, 2L)
    expect_equal(fit$fit_dual$d, 2L)
    expect_equal(dim(fit$selected_gene_directions), c(p, 2L))
    expect_equal(dim(fit$reduced_predictors), c(n, 2L))
    expect_equal(unname(fit$reduced_predictors), unname(fit$fit_dual$reduced_predictors),
        tolerance = 1e-12)
    inner_scale <- if (isTRUE(fit$fit_dual$standardize)) {
        as.numeric(fit$fit_dual$scale)
    }
    else {
        rep(1, nrow(fit$fit_dual$directions))
    }
    B_selected_input <- sweep(as.matrix(fit$fit_dual$directions), 1L, inner_scale, "/")
    expected_selected_gene <- fit$dual$loadings %*% B_selected_input
    expect_equal(unname(fit$selected_gene_directions), unname(expected_selected_gene), tolerance = 1e-12)
    expected_norm <- sqrt(rowSums(expected_selected_gene^2))
    expected_top <- order(expected_norm, decreasing = TRUE)[seq_len(10L)]
    expect_identical(as.integer(fit$selected_variables$index), as.integer(expected_top))
    expect_equal(as.numeric(fit$selected_variables$loading_norm), as.numeric(expected_norm[expected_top]),
        tolerance = 1e-12)
})

test_that("dual automatic d and lambda propagate CICOMP selection consistently", {
    set.seed(20260829)
    n <- 90L
    p <- 24L
    X <- matrix(stats::rnorm(n * p), nrow = n, ncol = p)
    colnames(X) <- paste0("G", seq_len(p))
    y <- 1.2 * X[, 1L] - 0.9 * X[, 2L] + stats::rnorm(n, sd = 0.5)
    fit <- fit_risdr_dual(X = X, y = y, response_type = "continuous", dual_rank = 8L, d = NULL,
        d_max = 4L, nslices = 4L, sdr_method = "sir", cov_method = "oas", selector = "cicomp",
        lambda_grid = c(0, 0.05, 0.1), adapt_weights = TRUE, weight_mode = "c1f", support_penalty = FALSE,
        standardize_dual = TRUE, gene_select_top = 10L, verbose = FALSE)
    expect_null(fit$requested_d)
    expect_equal(fit$d, fit$fit_dual$d)
    expect_equal(fit$best_lambda, fit$fit_dual$best_lambda)
    expect_equal(fit$d, unname(fit$fit_dual$criterion_dimensions["CICOMP"]))
    expect_equal(fit$best_lambda, unname(fit$fit_dual$criterion_lambdas["CICOMP"]), tolerance = 1e-14)
    expect_equal(ncol(fit$selected_gene_directions), fit$d)
    expect_equal(ncol(fit$reduced_predictors), fit$d)
    expect_equal(unname(fit$reduced_predictors), unname(fit$fit_dual$reduced_predictors),
        tolerance = 1e-12)
})
