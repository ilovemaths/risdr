test_that("survival slicing separates censoring status before time slicing", {

  y <- seq_len(40)
  delta <- rep(c(0L, 1L), each = 20L)

  sliced <- slice_response(
    y = y,
    nslices = 4L,
    response_type = "survival",
    delta = delta
  )

  censored_groups <- unique(sliced$groups[delta == 0L])
  event_groups <- unique(sliced$groups[delta == 1L])

  expect_equal(length(censored_groups), 4L)
  expect_equal(length(event_groups), 4L)
  expect_length(intersect(censored_groups, event_groups), 0L)
  expect_equal(length(unique(sliced$groups)), 8L)
})


test_that("SIR SAVE and DR kernels respond to censoring status", {

  set.seed(20260828)

  n <- 160L
  p <- 10L

  X <- matrix(
    stats::rnorm(n * p),
    nrow = n,
    ncol = p
  )

  eta <-
    1.1 * X[, 1L] -
    0.8 * X[, 2L] +
    0.5 * X[, 3L]

  time <- exp(
    5 +
    0.30 * eta +
    stats::rnorm(n, sd = 0.35)
  )

  delta_1 <- as.integer(
    eta + stats::rnorm(n, sd = 0.45) > stats::median(eta)
  )

  set.seed(20260829)
  delta_2 <- sample(delta_1, replace = FALSE)

  expect_equal(sum(delta_1), sum(delta_2))
  expect_false(identical(delta_1, delta_2))

  Sigma <- cov_oas(X)

  for (method in c("sir", "save", "dr")) {

    fit_1 <- compute_sdr(
      X = X,
      y = time,
      method = method,
      Sigma = Sigma,
      nslices = 4L,
      response_type = "survival",
      delta = delta_1
    )

    fit_2 <- compute_sdr(
      X = X,
      y = time,
      method = method,
      Sigma = Sigma,
      nslices = 4L,
      response_type = "survival",
      delta = delta_2
    )

    fit_cont <- compute_sdr(
      X = X,
      y = time,
      method = method,
      Sigma = Sigma,
      nslices = 4L,
      response_type = "continuous"
    )

    expect_gt(
      max(abs(fit_1$kernel - fit_2$kernel)),
      1e-10
    )

    expect_gt(
      max(abs(fit_1$kernel - fit_cont$kernel)),
      1e-10
    )

    expect_true(all(is.finite(fit_1$kernel)))
    expect_equal(fit_1$kernel, t(fit_1$kernel), tolerance = 1e-10)
  }
})


test_that("C1F variable contributions reconstruct complexity and are permutation equivariant", {

  set.seed(20260828)

  p <- 6L

  Q <- qr.Q(
    qr(
      matrix(
        stats::rnorm(p * p),
        nrow = p,
        ncol = p
      )
    )
  )

  lambda <- c(6, 4, 3, 2, 1, 0.5)

  Sigma <- Q %*%
    diag(lambda) %*%
    t(Q)

  Sigma <- (Sigma + t(Sigma)) / 2

  colnames(Sigma) <- rownames(Sigma) <- paste0("X", seq_len(p))

  contribution <- risdr:::c1f_variable_contributions(Sigma)

  eigvals <- eigen(
    Sigma,
    symmetric = TRUE,
    only.values = TRUE
  )$values

  global_c1f <- utils::tail(
    C1F(eigvals)$c1f,
    1L
  )

  expect_equal(sum(contribution), global_c1f, tolerance = 1e-10)

  w <- compute_penalty_weights(
    Sigma = Sigma,
    mode = "c1f"
  )

  perm <- c(3L, 1L, 6L, 2L, 5L, 4L)

  Sigma_perm <- Sigma[perm, perm, drop = FALSE]

  contribution_perm <- risdr:::c1f_variable_contributions(Sigma_perm)

  w_perm <- compute_penalty_weights(
    Sigma = Sigma_perm,
    mode = "c1f"
  )

  expect_equal(
    unname(contribution_perm),
    unname(contribution[perm]),
    tolerance = 1e-8
  )

  expect_equal(
    unname(w_perm),
    unname(w[perm]),
    tolerance = 1e-8
  )

  expect_equal(mean(w), 1, tolerance = 1e-12)
})


test_that("sparse lambda grid is operational", {

  V <- matrix(
    c(
      0.80, 0.10,
      0.60, 0.20,
      0.30, 0.70,
      0.20, 0.50,
      0.10, 0.40
    ),
    nrow = 5L,
    byrow = TRUE
  )

  Sigma <- diag(c(5, 4, 3, 2, 1))

  grid <- fit_sparse_grid(
    directions = V,
    d = 2L,
    lambda_grid = c(0, 0.20),
    adapt_weights = TRUE,
    Sigma = Sigma,
    weight_mode = "c1f"
  )

  expect_length(grid$fits, 2L)
  expect_false(isTRUE(all.equal(grid$fits[[1L]], grid$fits[[2L]])))
  expect_equal(length(grid$penalty_weights), 5L)
  expect_equal(mean(grid$penalty_weights), 1, tolerance = 1e-12)
})


test_that("unified survival fitter profiles d and lambda jointly", {

  set.seed(20260831)

  n <- 150L
  p <- 10L

  X <- matrix(
    stats::rnorm(n * p),
    nrow = n,
    ncol = p
  )

  colnames(X) <- paste0("G", seq_len(p))

  eta <-
    0.9 * X[, 1L] -
    0.7 * X[, 2L] +
    0.4 * X[, 3L]

  time <- exp(
    5 +
    0.30 * eta +
    stats::rnorm(n, sd = 0.40)
  )

  delta <- as.integer(
    eta + stats::rnorm(n, sd = 0.60) > stats::median(eta)
  )

  lambda_grid <- c(0, 0.05, 0.10)

  fit <- fit_risdr(
    X = X,
    y = time,
    delta = delta,
    response_type = "survival",
    sdr_method = "sir",
    cov_method = "oas",
    nslices = 4L,
    d = NULL,
    d_max = 4L,
    selector = "cicomp",
    lambda_grid = lambda_grid,
    adapt_weights = TRUE,
    weight_mode = "c1f",
    support_penalty = FALSE,
    standardize = TRUE,
    stabilize = TRUE
  )

  expect_equal(nrow(fit$selection_grid), 4L * length(lambda_grid))
  expect_identical(as.integer(fit$d_candidates), 1:4)
  expect_equal(nrow(fit$d_table), 4L)
  expect_equal(fit$d, unname(fit$criterion_dimensions["CICOMP"]))
  expect_equal(
    fit$best_lambda,
    unname(fit$criterion_lambdas["CICOMP"]),
    tolerance = 1e-14
  )
  expect_equal(ncol(fit$directions), fit$d)
  expect_equal(ncol(fit$reduced_predictors), fit$d)
  expect_s3_class(fit$downstream_fit, "coxph")
})
