thesis_coverage_data <- function(n = 60L, p = 6L) {
  withr::local_seed(8042026)
  X <- matrix(stats::rnorm(n * p), nrow = n)
  colnames(X) <- paste0("G", seq_len(p))
  y <- X[, 1L] + 0.3 * X[, 2L]^2 + stats::rnorm(n)
  event <- stats::rexp(n, rate = exp(0.3 * X[, 1L]))
  censor <- stats::rexp(n, rate = 0.4)
  list(X = X, y = y, time = pmin(event, censor),
       delta = as.integer(event <= censor),
       binary = factor(rep(c("no", "yes"), length.out = n)),
       category = factor(rep(c("a", "b", "c"), length.out = n)))
}
