make_test_data <- function(n = 90L, p = 8L, seed = 2026L) {
  set.seed(seed)
  X <- matrix(stats::rnorm(n * p), nrow = n, ncol = p)
  colnames(X) <- paste0("x", seq_len(p))
  y <- X[, 1L] - 0.8 * X[, 2L] + 0.5 * X[, 3L]^2 +
    stats::rnorm(n, sd = 0.4)

  list(X = X, y = as.numeric(y))
}

expect_symmetric_matrix <- function(x, tolerance = 1e-8) {
  expect_true(is.matrix(x))
  expect_equal(nrow(x), ncol(x))
  expect_equal(x, t(x), tolerance = tolerance)
}
