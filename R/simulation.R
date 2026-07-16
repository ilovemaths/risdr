# ============================================================
# R/simulation.R
# Simulation utilities for risdr
# ============================================================


#' Simulate SDR data
#'
#' Simulates data from a sufficient dimension reduction model with an
#' autoregressive covariance structure. The function returns the true
#' orthonormal central subspace basis, which allows simulation studies to
#' evaluate both prediction accuracy and subspace recovery.
#'
#' @param n Sample size.
#' @param p Number of predictors.
#' @param d Structural dimension.
#' @param rho AR(1) correlation parameter.
#' @param sigma Error standard deviation.
#' @param signal_strength Multiplicative strength of the regression signal.
#' @param model Data-generating model.
#' @param beta_type Type of true central subspace basis.
#' @param beta Optional user-supplied `p` by `d` central subspace basis. When
#'   supplied, its orthonormal basis is used and `beta_type` is ignored.
#' @param seed Optional random seed.
#'
#' @return A list containing the simulated predictors, response, true basis,
#' latent sufficient predictors, population covariance matrix, signal, error,
#' and simulation settings.
#' @export
simulate_risdr_data <- function(
    n = 200,
    p = 50,
    d = 2,
    rho = 0.6,
    sigma = 1,
    signal_strength = 1,
    model = c("linear_quadratic", "symmetric", "interaction", "linear"),
    beta_type = c("coordinate", "random_sparse", "random_dense"),
    beta = NULL,
    seed = NULL
) {

  if (!is.null(seed)) {
    set.seed(seed)
  }

  model <- match.arg(model)
  beta_type <- match.arg(beta_type)

  if (!is.numeric(n) || length(n) != 1 || !is.finite(n) ||
      n != as.integer(n) || n < 20) {
    stop("`n` must be a single integer at least 20.", call. = FALSE)
  }

  if (!is.numeric(p) || length(p) != 1 || !is.finite(p) ||
      p != as.integer(p) || p < 2) {
    stop("`p` must be a single integer at least 2.", call. = FALSE)
  }

  if (!is.numeric(d) || length(d) != 1 || !is.finite(d) ||
      d != as.integer(d) || d < 1 || d > p) {
    stop("`d` must be a positive integer not exceeding `p`.", call. = FALSE)
  }

  if (!is.numeric(rho) || length(rho) != 1 || !is.finite(rho) ||
      rho < 0 || rho >= 1) {
    stop("`rho` must be a single numeric value in [0, 1).", call. = FALSE)
  }

  if (!is.numeric(sigma) || length(sigma) != 1 || !is.finite(sigma) ||
      sigma <= 0) {
    stop("`sigma` must be a positive numeric value.", call. = FALSE)
  }

  if (!is.numeric(signal_strength) || length(signal_strength) != 1 ||
      !is.finite(signal_strength) || signal_strength <= 0) {
    stop("`signal_strength` must be a positive numeric value.", call. = FALSE)
  }

  n <- as.integer(n)
  p <- as.integer(p)
  d <- as.integer(d)

  Sigma <- ar1_covariance(p = p, rho = rho)

  X <- simulate_mvn(
    n = n,
    Sigma = Sigma
  )

  if (is.null(beta)) {
    beta <- make_true_beta(
      p = p,
      d = d,
      beta_type = beta_type
    )
  } else {
    beta <- as.matrix(beta)

    if (!is.numeric(beta) || anyNA(beta) || any(!is.finite(beta)) ||
        !identical(dim(beta), c(p, d))) {
      stop("`beta` must be a finite numeric `p` by `d` matrix.", call. = FALSE)
    }

    qr_beta <- qr(beta)

    if (qr_beta$rank < d) {
      stop("`beta` must have full column rank.", call. = FALSE)
    }

    gram <- unname(crossprod(beta))

    if (max(abs(gram - diag(d))) > sqrt(.Machine$double.eps)) {
      beta <- qr.Q(qr_beta)[, seq_len(d), drop = FALSE]
    }
  }

  eta <- X %*% beta

  signal <- generate_signal(
    U = eta,
    model = model
  )

  signal <- signal_strength * as.numeric(signal)

  epsilon <- stats::rnorm(
    n = n,
    mean = 0,
    sd = sigma
  )

  y <- signal + epsilon

  colnames(X) <- paste0("X", seq_len(p))
  colnames(beta) <- paste0("beta", seq_len(d))
  rownames(beta) <- colnames(X)
  colnames(eta) <- paste0("eta", seq_len(d))

  list(
    X = X,
    y = as.numeric(y),
    beta = beta,
    B = beta,
    eta = eta,
    U = eta,
    Sigma = Sigma,
    signal = as.numeric(signal),
    epsilon = epsilon,
    rho = rho,
    sigma = sigma,
    signal_strength = signal_strength,
    model = model,
    beta_type = beta_type,
    n = n,
    p = p,
    d = d
  )
}

#' Construct true central subspace basis
#'
#' @param p Number of predictors.
#' @param d Structural dimension.
#' @param beta_type Basis type.
#'
#' @return A p x d orthonormal basis matrix.
#' @keywords internal
make_true_beta <- function(
    p,
    d,
    beta_type = c("coordinate", "random_sparse", "random_dense")
) {

  beta_type <- match.arg(beta_type)

  if (beta_type == "coordinate") {

    beta <- matrix(0, nrow = p, ncol = d)

    beta[cbind(seq_len(d), seq_len(d))] <- 1

  } else if (beta_type == "random_sparse") {

    beta <- matrix(0, nrow = p, ncol = d)

    active_size <- min(p, max(5L, d + 3L))

    active <- sort(
      sample(
        seq_len(p),
        size = active_size,
        replace = FALSE
      )
    )

    for (j in seq_len(d)) {

      beta[active, j] <-
        stats::rnorm(active_size)

    }

  } else {

    beta <-
      matrix(
        stats::rnorm(p * d),
        nrow = p,
        ncol = d
      )

  }

  beta <- qr.Q(qr(beta))

  beta <- beta[, seq_len(d), drop = FALSE]

  beta

}
#' AR(1) covariance matrix
#'
#' @param p Dimension.
#' @param rho Correlation parameter.
#'
#' @return Covariance matrix.
#' @export
ar1_covariance <- function(p, rho) {

  if (!is.numeric(p) || length(p) != 1 || !is.finite(p) ||
      p != as.integer(p) || p < 2) {
    stop("`p` must be a single integer at least 2.", call. = FALSE)
  }

  if (!is.numeric(rho) || length(rho) != 1 || !is.finite(rho) ||
      rho < 0 || rho >= 1) {
    stop("`rho` must be in [0, 1).", call. = FALSE)
  }

  idx <- seq_len(p)
  abs_outer <- abs(outer(idx, idx, "-"))

  rho^abs_outer
}


#' Simulate multivariate normal data
#'
#' @param n Sample size.
#' @param Sigma Covariance matrix.
#'
#' @return Numeric matrix.
#' @keywords internal
simulate_mvn <- function(n, Sigma) {

  Sigma <- check_cov_matrix(Sigma)

  if (!requireNamespace("MASS", quietly = TRUE)) {
    stop("Package `MASS` is required for multivariate normal simulation.", call. = FALSE)
  }

  MASS::mvrnorm(
    n = n,
    mu = rep(0, ncol(Sigma)),
    Sigma = Sigma
  )
}


#' Generate SDR signal
#'
#' @param U Matrix of sufficient predictors.
#' @param model Signal model.
#'
#' @return Numeric signal vector.
#' @keywords internal
generate_signal <- function(
    U,
    model = c("linear_quadratic", "symmetric", "interaction", "linear")
) {

  model <- match.arg(model)

  U <- as.matrix(U)

  if (model == "linear") {
    return(U[, 1])
  }

  if (model == "symmetric") {
    return(U[, 1]^2)
  }

  if (ncol(U) < 2 && model %in% c("linear_quadratic", "interaction")) {
    stop("This signal model requires at least two sufficient predictors.", call. = FALSE)
  }

  if (model == "linear_quadratic") {
    return(U[, 1] + U[, 2]^2)
  }

  if (model == "interaction") {
    return(U[, 1] + U[, 2] + U[, 1] * U[, 2])
  }
}



#' Projection matrix
#'
#' @param B Basis matrix.
#'
#' @return Projection matrix.
#' @export
projection_matrix <- function(B) {

  B <- as.matrix(B)

  if (!is.numeric(B) || anyNA(B) || any(!is.finite(B)) ||
      nrow(B) < 1L || ncol(B) < 1L) {
    stop("`B` must be a non-empty finite numeric matrix.", call. = FALSE)
  }

  qr_B <- qr(B)

  if (qr_B$rank < ncol(B)) {
    stop("`B` must have full column rank.", call. = FALSE)
  }

  Q <- qr.Q(qr_B)[, seq_len(ncol(B)), drop = FALSE]

  Q %*% t(Q)
}


#' Subspace distance
#'
#' Computes Frobenius distance between projection matrices.
#'
#' @param B_hat Estimated basis matrix.
#' @param B True basis matrix.
#'
#' @return Numeric subspace distance.
#' @export
subspace_distance <- function(B_hat, B) {

  B_hat <- as.matrix(B_hat)
  B <- as.matrix(B)

  if (nrow(B_hat) != nrow(B)) {
    stop("`B_hat` and `B` must have the same number of rows.", call. = FALSE)
  }

  P_hat <- projection_matrix(B_hat)
  P_true <- projection_matrix(B)

  sqrt(sum((P_hat - P_true)^2))
}


#' Run one SDR simulation replication
#'
#' @param n Sample size.
#' @param p Number of predictors.
#' @param d Structural dimension.
#' @param rho Correlation parameter.
#' @param sigma Error standard deviation.
#' @param model Data-generating model.
#' @param beta_type Type of true central subspace basis.
#' @param sdr_method SDR method.
#' @param cov_method Covariance method.
#' @param nslices Number of slices.
#' @param selector Dimension selection criterion.
#' @param d_max Maximum candidate dimension.
#' @param seed Optional random seed. The test sample uses `seed + 1`.
#'
#' @return A data frame with simulation results.
#' @export
run_one_simulation <- function(
    n = 200,
    p = 50,
    d = 2,
    rho = 0.6,
    sigma = 1,
    model = "linear_quadratic",
    beta_type = "coordinate",
    sdr_method = "dr",
    cov_method = "oas",
    nslices = 6,
    selector = "cicomp",
    d_max = 10,
    seed = NULL
) {

  train <- simulate_risdr_data(
    n = n,
    p = p,
    d = d,
    rho = rho,
    sigma = sigma,
    model = model,
    beta_type = beta_type,
    seed = seed
  )

  test <- simulate_risdr_data(
    n = n,
    p = p,
    d = d,
    rho = rho,
    sigma = sigma,
    model = model,
    beta_type = beta_type,
    beta = train$beta,
    seed = if (is.null(seed)) NULL else seed + 1L
  )

  fit <- fit_risdr(
    X = train$X,
    y = train$y,
    sdr_method = sdr_method,
    cov_method = cov_method,
    nslices = nslices,
    selector = selector,
    d_max = d_max
  )

  y_pred <- predict(fit, newX = test$X)

  perf <- evaluate_prediction(
    y_true = test$y,
    y_pred = y_pred,
    d = fit$d
  )

  B_hat <- fit$directions[, seq_len(min(d, ncol(fit$directions))), drop = FALSE]

  dist <- subspace_distance(
    B_hat = B_hat,
    B = train$B
  )

  data.frame(
    n = n,
    p = p,
    true_d = d,
    selected_d = fit$d,
    rho = rho,
    sigma = sigma,
    model = model,
    sdr_method = sdr_method,
    cov_method = cov_method,
    selector = selector,
    subspace_distance = dist,
    perf
  )
}


#' Run SDR simulation study
#'
#' @param R Number of replications.
#' @param rho_values Correlation values.
#' @param methods SDR methods.
#' @param cov_methods Covariance methods.
#' @param seed Optional starting seed for reproducible replications.
#' @param ... Additional arguments passed to [run_one_simulation()].
#'
#' @return Data frame of simulation results.
#' @export
run_risdr_simulation <- function(
    R = 200,
    rho_values = c(0.3, 0.6, 0.9),
    methods = c("sir", "save", "dr", "phd"),
    cov_methods = c("sample", "oas", "mec"),
    seed = NULL,
    ...
) {

  if (!is.numeric(R) || length(R) != 1 || !is.finite(R) ||
      R != as.integer(R) || R < 1) {
    stop("`R` must be a positive integer.", call. = FALSE)
  }

  R <- as.integer(R)

  if (!is.numeric(rho_values) || length(rho_values) < 1L ||
      anyNA(rho_values) || any(!is.finite(rho_values)) ||
      any(rho_values < 0) || any(rho_values >= 1)) {
    stop("`rho_values` must contain one or more values in [0, 1).", call. = FALSE)
  }

  if (!is.character(methods) || length(methods) < 1L ||
      any(!methods %in% c("sir", "save", "dr", "phd"))) {
    stop("`methods` must contain one or more supported SDR methods.", call. = FALSE)
  }

  if (!is.character(cov_methods) || length(cov_methods) < 1L ||
      any(!cov_methods %in% c("sample", "ridge", "oas", "lw", "mec"))) {
    stop("`cov_methods` must contain one or more supported covariance methods.", call. = FALSE)
  }

  results <- list()
  counter <- 1L

  for (rho in rho_values) {
    for (method in methods) {
      for (cov_method in cov_methods) {
        for (r in seq_len(R)) {

          results[[counter]] <- run_one_simulation(
            rho = rho,
            sdr_method = method,
            cov_method = cov_method,
            seed = if (is.null(seed)) NULL else seed + counter - 1L,
            ...
          )

          results[[counter]]$replication <- r

          counter <- counter + 1L
        }
      }
    }
  }

  do.call(rbind, results)
}


#' Summarise simulation results
#'
#' @param sim_results Data frame from run_risdr_simulation().
#'
#' @return Summary data frame.
#' @export
summarise_simulation <- function(sim_results) {

  required <- c(
    "rho", "sdr_method", "cov_method",
    "subspace_distance", "RMSE", "MAE", "R2", "Adjusted_R2", "Correlation"
  )

  missing_cols <- setdiff(required, names(sim_results))

  if (length(missing_cols) > 0) {
    stop(
      "Missing required columns in `sim_results`: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  stats::aggregate(
    sim_results[, c("subspace_distance", "RMSE", "MAE", "R2", "Adjusted_R2", "Correlation")],
    by = list(
      rho = sim_results$rho,
      sdr_method = sim_results$sdr_method,
      cov_method = sim_results$cov_method
    ),
    FUN = function(z) mean(z, na.rm = TRUE)
  )
}
