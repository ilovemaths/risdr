# ============================================================
# R/simulation.R
# Simulation utilities for risdr
# ============================================================


#' Simulate SDR data
#'
#' Simulates data from a sufficient dimension reduction model with
#' autoregressive covariance structure.
#'
#' @param n Sample size.
#' @param p Number of predictors.
#' @param d Structural dimension.
#' @param rho AR(1) correlation parameter.
#' @param sigma Error standard deviation.
#' @param model Data-generating model.
#' @param seed Optional random seed.
#'
#' @return A list containing X, y, B, Sigma, and model information.
#' @export
simulate_risdr_data <- function(
    n = 200,
    p = 50,
    d = 2,
    rho = 0.6,
    sigma = 1,
    model = c("linear_quadratic", "symmetric", "interaction"),
    seed = NULL
) {

  if (!is.null(seed)) {
    set.seed(seed)
  }

  model <- match.arg(model)

  if (!is.numeric(n) || length(n) != 1 || n < 10) {
    stop("`n` must be a single integer at least 10.", call. = FALSE)
  }

  if (!is.numeric(p) || length(p) != 1 || p < 2) {
    stop("`p` must be a single integer at least 2.", call. = FALSE)
  }

  if (!is.numeric(d) || length(d) != 1 || d < 1 || d > p) {
    stop("`d` must be a positive integer not exceeding `p`.", call. = FALSE)
  }

  if (!is.numeric(rho) || length(rho) != 1 || rho <= 0 || rho >= 1) {
    stop("`rho` must be a single numeric value in (0, 1).", call. = FALSE)
  }

  if (!is.numeric(sigma) || length(sigma) != 1 || sigma <= 0) {
    stop("`sigma` must be a positive numeric value.", call. = FALSE)
  }

  n <- as.integer(n)
  p <- as.integer(p)
  d <- as.integer(d)

  Sigma <- ar1_covariance(p = p, rho = rho)

  X <- simulate_mvn(n = n, Sigma = Sigma)

  B <- matrix(0, nrow = p, ncol = d)
  B[cbind(seq_len(d), seq_len(d))] <- 1

  U <- X %*% B

  eta <- generate_signal(U, model = model)

  y <- eta + stats::rnorm(n, mean = 0, sd = sigma)

  colnames(X) <- paste0("X", seq_len(p))
  colnames(B) <- paste0("beta", seq_len(d))
  rownames(B) <- colnames(X)

  list(
    X = X,
    y = as.numeric(y),
    B = B,
    Sigma = Sigma,
    U = U,
    eta = as.numeric(eta),
    rho = rho,
    sigma = sigma,
    model = model,
    n = n,
    p = p,
    d = d
  )
}


#' AR(1) covariance matrix
#'
#' @param p Dimension.
#' @param rho Correlation parameter.
#'
#' @return Covariance matrix.
#' @export
ar1_covariance <- function(p, rho) {

  if (!is.numeric(p) || length(p) != 1 || p < 2) {
    stop("`p` must be a single integer at least 2.", call. = FALSE)
  }

  if (!is.numeric(rho) || length(rho) != 1 || rho <= 0 || rho >= 1) {
    stop("`rho` must be in (0, 1).", call. = FALSE)
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
    model = c("linear_quadratic", "symmetric", "interaction")
) {

  model <- match.arg(model)

  U <- as.matrix(U)

  if (ncol(U) < 2 && model %in% c("linear_quadratic", "interaction")) {
    stop("This signal model requires at least two sufficient predictors.", call. = FALSE)
  }

  if (model == "linear_quadratic") {
    return(U[, 1] + U[, 2]^2)
  }

  if (model == "symmetric") {
    return(U[, 1]^2)
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

  if (!is.numeric(B)) {
    stop("`B` must be numeric.", call. = FALSE)
  }

  B %*% solve(t(B) %*% B) %*% t(B)
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
#' @param sdr_method SDR method.
#' @param cov_method Covariance method.
#' @param nslices Number of slices.
#' @param selector Dimension selection criterion.
#' @param d_max Maximum candidate dimension.
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
    sdr_method = "dr",
    cov_method = "oas",
    nslices = 6,
    selector = "cicomp",
    d_max = 10
) {

  train <- simulate_risdr_data(
    n = n,
    p = p,
    d = d,
    rho = rho,
    sigma = sigma,
    model = model
  )

  test <- simulate_risdr_data(
    n = n,
    p = p,
    d = d,
    rho = rho,
    sigma = sigma,
    model = model
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
#' @param ... Additional arguments passed to internal methods.
#'
#' @return Data frame of simulation results.
#' @export
run_risdr_simulation <- function(
    R = 200,
    rho_values = c(0.3, 0.6, 0.9),
    methods = c("sir", "save", "dr", "phd"),
    cov_methods = c("sample", "oas", "mec"),
    ...
) {

  if (!is.numeric(R) || length(R) != 1 || R < 1) {
    stop("`R` must be a positive integer.", call. = FALSE)
  }

  R <- as.integer(R)

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
    FUN = mean
  )
}
