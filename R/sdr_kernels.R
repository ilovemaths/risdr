# ============================================================
# R/sdr_kernels.R
# Sufficient dimension reduction kernel estimators for risdr
# ============================================================


#' Matrix inverse square root
#'
#' Computes the inverse square root of a symmetric positive definite matrix.
#'
#' @param Sigma Symmetric positive definite matrix.
#' @param eps Eigenvalue floor.
#'
#' @return Matrix inverse square root.
#' @keywords internal
matrix_inv_sqrt <- function(Sigma, eps = 1e-8) {

  Sigma <- check_cov_matrix(Sigma)

  if (!is.numeric(eps) || length(eps) != 1L || !is.finite(eps) || eps <= 0) {
    stop("`eps` must be a single positive numeric value.", call. = FALSE)
  }

  eig <- eigen(Sigma, symmetric = TRUE)
  values <- pmax(eig$values, eps)

  inv_sqrt <- eig$vectors %*%
    diag(1 / sqrt(values), nrow = length(values)) %*%
    t(eig$vectors)

  inv_sqrt <- (inv_sqrt + t(inv_sqrt)) / 2

  inv_sqrt
}


#' Standardise predictors using covariance matrix
#'
#' Computes the covariance-standardised predictor matrix.
#'
#' Specifically, this function centres the predictor matrix and multiplies
#' it by the inverse square root of the covariance matrix.
#'
#' `Sigma` denotes a positive definite covariance matrix and `center` denotes
#' the sample mean vector when it is not supplied explicitly.
#'
#' @param X Numeric predictor matrix.
#' @param Sigma Covariance matrix.
#' @param center Optional centring vector.
#' @param eps Eigenvalue floor.
#'
#' @return A list containing standardised predictors and centring vector.
#' @keywords internal
standardize_by_cov <- function(X, Sigma, center = NULL, eps = 1e-8) {

  X <- check_X(X)
  Sigma <- check_cov_matrix(Sigma)

  if (ncol(X) != ncol(Sigma)) {
    stop("Number of columns in `X` must match dimension of `Sigma`.", call. = FALSE)
  }

  if (!is.numeric(eps) || length(eps) != 1L || !is.finite(eps) || eps <= 0) {
    stop("`eps` must be a single positive numeric value.", call. = FALSE)
  }

  if (is.null(center)) {
    center <- colMeans(X)
  }

  if (!is.numeric(center) || length(center) != ncol(X) ||
      anyNA(center) || any(!is.finite(center))) {
    stop("`center` must be a finite numeric vector with one value per predictor.", call. = FALSE)
  }

  Xc <- sweep(X, 2, center, "-")
  Sigma_inv_sqrt <- matrix_inv_sqrt(Sigma, eps = eps)

  Z <- Xc %*% Sigma_inv_sqrt

  list(
    Z = Z,
    center = center,
    Sigma_inv_sqrt = Sigma_inv_sqrt
  )
}


#' Eigen-decompose SDR kernel
#'
#' @param M Kernel matrix.
#' @param sort_by_abs Logical. If TRUE, sorts by absolute eigenvalue magnitude.
#'
#' @return A list with kernel, eigenvalues, directions.
#' @keywords internal
decompose_kernel <- function(M, sort_by_abs = FALSE) {

  M <- check_cov_matrix((M + t(M)) / 2)

  eig <- eigen(M, symmetric = TRUE)

  if (sort_by_abs) {
    ord <- order(abs(eig$values), decreasing = TRUE)
  } else {
    ord <- order(eig$values, decreasing = TRUE)
  }

  values <- eig$values[ord]
  vectors <- eig$vectors[, ord, drop = FALSE]

  list(
    kernel = M,
    eigenvalues = values,
    directions = vectors
  )
}


#' Compute Sliced Inverse Regression
#'
#' @param X Numeric predictor matrix.
#' @param y Numeric response vector.
#' @param Sigma Covariance matrix used for standardisation.
#' @param nslices Number of response slices.
#' @param slice_type Slicing strategy.
#' @param eps Eigenvalue floor.
#'
#' @return A list containing SIR kernel, eigenvalues, directions, scores, and slices.
#' @examples
#' X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
#' fit <- compute_sir(X, y = mtcars$mpg, nslices = 4)
#' head(fit$eigenvalues)
#' @export
compute_sir <- function(
    X,
    y,
    Sigma = NULL,
    nslices = 6,
    slice_type = c("quantile", "equal_width"),
    eps = 1e-8
) {

  X <- check_X(X)
  y <- check_y_continuous(y, nrow(X))
  check_missing(X, y)

  if (is.null(Sigma)) {
    Sigma <- stats::cov(X)
  }

  slice_type <- match.arg(slice_type)
  slices <- make_slices(y, nslices = nslices, type = slice_type)

  std <- standardize_by_cov(X, Sigma, eps = eps)
  Z <- std$Z

  n <- nrow(Z)
  p <- ncol(Z)
  M <- matrix(0, nrow = p, ncol = p)

  slice_ids <- sort(unique(slices))

  for (h in slice_ids) {

    idx <- which(slices == h)
    Zh <- Z[idx, , drop = FALSE]

    if (nrow(Zh) < 2L) {
      stop("Every response slice must contain at least two observations.", call. = FALSE)
    }

    p_h <- nrow(Zh) / n
    mu_h <- matrix(colMeans(Zh), ncol = 1)

    M <- M + p_h * (mu_h %*% t(mu_h))
  }

  decomp <- decompose_kernel(M)

  B <- std$Sigma_inv_sqrt %*% decomp$directions
  X_centered <- sweep(X, 2, std$center, "-")
  scores <- X_centered %*% B

  list(
    method = "sir",
    kernel = decomp$kernel,
    eigenvalues = decomp$eigenvalues,
    directions = B,
    z_directions = decomp$directions,
    scores = scores,
    slices = slices,
    center = std$center,
    sdr_center = std$center,
    Sigma = Sigma
  )
}


#' Compute Sliced Average Variance Estimation
#'
#' @param X Numeric predictor matrix.
#' @param y Numeric response vector.
#' @param Sigma Covariance matrix used for standardisation.
#' @param nslices Number of response slices.
#' @param slice_type Slicing strategy.
#' @param stabilize_slices Logical. Stabilise slice covariance matrices.
#' @param stabilization Stabilisation method.
#' @param eps Eigenvalue floor.
#'
#' @return A list containing SAVE kernel, eigenvalues, directions, scores, and slices.
#' @examples
#' X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
#' fit <- compute_save(X, y = mtcars$mpg, nslices = 4)
#' head(fit$eigenvalues)
#' @export
compute_save <- function(
    X,
    y,
    Sigma = NULL,
    nslices = 6,
    slice_type = c("quantile", "equal_width"),
    stabilize_slices = TRUE,
    stabilization = c("eigenfloor", "ridge", "nearest_pd"),
    eps = 1e-8
) {

  X <- check_X(X)
  y <- check_y_continuous(y, nrow(X))
  check_missing(X, y)

  if (is.null(Sigma)) {
    Sigma <- stats::cov(X)
  }

  slice_type <- match.arg(slice_type)
  stabilization <- match.arg(stabilization)
  stabilize_slices <- check_flag(stabilize_slices, "stabilize_slices")

  slices <- make_slices(y, nslices = nslices, type = slice_type)

  std <- standardize_by_cov(X, Sigma, eps = eps)
  Z <- std$Z

  n <- nrow(Z)
  p <- ncol(Z)
  I_p <- diag(p)
  M <- matrix(0, nrow = p, ncol = p)

  slice_ids <- sort(unique(slices))

  for (h in slice_ids) {

    idx <- which(slices == h)
    Zh <- Z[idx, , drop = FALSE]

    if (nrow(Zh) < 2L) {
      stop("Every response slice must contain at least two observations.", call. = FALSE)
    }

    p_h <- nrow(Zh) / n
    Sigma_h <- stats::cov(Zh)

    if (stabilize_slices) {
      Sigma_h <- stabilize_cov(Sigma_h, method = stabilization, eps = eps)
    }

    A_h <- I_p - Sigma_h
    M <- M + p_h * (A_h %*% A_h)
  }

  decomp <- decompose_kernel(M)

  B <- std$Sigma_inv_sqrt %*% decomp$directions
  X_centered <- sweep(X, 2, std$center, "-")
  scores <- X_centered %*% B

  list(
    method = "save",
    kernel = decomp$kernel,
    eigenvalues = decomp$eigenvalues,
    directions = B,
    z_directions = decomp$directions,
    scores = scores,
    slices = slices,
    center = std$center,
    sdr_center = std$center,
    Sigma = Sigma
  )
}

#' Compute Directional Regression
#'
#' Computes Directional Regression using the canonical pairwise-slice
#' formulation.
#'
#' @details
#' Directional Regression is computed using the pairwise-slice formulation.
#'
#' \deqn{
#' M_{DR} =
#' \sum_h \sum_k
#' p_h p_k
#' (2I_p - A_{hk})
#' (2I_p - A_{hk})^\top
#' }
#'
#' where
#'
#' \deqn{
#' A_{hk} =
#' \Sigma_h + \Sigma_k +
#' (\mu_h - \mu_k)
#' (\mu_h - \mu_k)^\top
#' }
#'
#' @param X Numeric predictor matrix.
#' @param y Numeric response vector.
#' @param Sigma Covariance matrix used for standardisation.
#' @param nslices Number of response slices.
#' @param slice_type Slicing strategy.
#' @param stabilize_slices Logical. Stabilise slice covariance matrices.
#' @param stabilization Stabilisation method.
#' @param eps Eigenvalue floor.
#'
#' @return A list containing DR kernel, eigenvalues, directions, scores, and slices.
#' @examples
#' X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
#' fit <- compute_dr(X, y = mtcars$mpg, nslices = 4)
#' head(fit$eigenvalues)
#' @export
compute_dr <- function(
    X,
    y,
    Sigma = NULL,
    nslices = 6,
    slice_type = c("quantile", "equal_width"),
    stabilize_slices = TRUE,
    stabilization = c("eigenfloor", "ridge", "nearest_pd"),
    eps = 1e-8
) {

  X <- check_X(X)
  y <- check_y_continuous(y, nrow(X))
  check_missing(X, y)

  if (is.null(Sigma)) {
    Sigma <- stats::cov(X)
  }

  slice_type <- match.arg(slice_type)
  stabilization <- match.arg(stabilization)
  stabilize_slices <- check_flag(stabilize_slices, "stabilize_slices")

  slices <- make_slices(y, nslices = nslices, type = slice_type)

  std <- standardize_by_cov(X, Sigma, eps = eps)
  Z <- std$Z

  n <- nrow(Z)
  p <- ncol(Z)
  I_p <- diag(p)
  M <- matrix(0, nrow = p, ncol = p)

  slice_ids <- sort(unique(slices))
  H_eff <- length(slice_ids)

  p_h_list <- vector("list", H_eff)
  mu_h_list <- vector("list", H_eff)
  Sigma_h_list <- vector("list", H_eff)

  names(p_h_list) <- names(mu_h_list) <- names(Sigma_h_list) <- as.character(slice_ids)

  for (h in slice_ids) {

    idx <- which(slices == h)
    Zh <- Z[idx, , drop = FALSE]

    if (nrow(Zh) < 2L) {
      stop("Every response slice must contain at least two observations.", call. = FALSE)
    }

    p_h <- nrow(Zh) / n
    mu_h <- matrix(colMeans(Zh), ncol = 1)
    Sigma_h <- stats::cov(Zh)

    if (stabilize_slices) {
      Sigma_h <- stabilize_cov(
        Sigma_h,
        method = stabilization,
        eps = eps
      )
    }

    p_h_list[[as.character(h)]] <- p_h
    mu_h_list[[as.character(h)]] <- mu_h
    Sigma_h_list[[as.character(h)]] <- Sigma_h
  }

  for (h in slice_ids) {
    for (k in slice_ids) {

      ph <- p_h_list[[as.character(h)]]
      pk <- p_h_list[[as.character(k)]]

      muh <- mu_h_list[[as.character(h)]]
      muk <- mu_h_list[[as.character(k)]]

      Sh <- Sigma_h_list[[as.character(h)]]
      Sk <- Sigma_h_list[[as.character(k)]]

      delta_hk <- muh - muk

      A_hk <- Sh + Sk + delta_hk %*% t(delta_hk)
      D_hk <- 2 * I_p - A_hk

      M <- M + ph * pk * (D_hk %*% D_hk)
    }
  }

  M <- (M + t(M)) / 2

  decomp <- decompose_kernel(M)

  B <- std$Sigma_inv_sqrt %*% decomp$directions

  X_centered <- sweep(X, 2, std$center, "-")
  scores <- X_centered %*% B

  list(
    method = "dr",
    kernel = decomp$kernel,
    eigenvalues = decomp$eigenvalues,
    directions = B,
    z_directions = decomp$directions,
    scores = scores,
    slices = slices,
    center = std$center,
    sdr_center = std$center,
    Sigma = Sigma
  )
}


#' Compute Principal Hessian Directions
#'
#' @param X Numeric predictor matrix.
#' @param y Numeric response vector.
#' @param Sigma Covariance matrix used for standardisation.
#' @param eps Eigenvalue floor.
#'
#' @return A list containing pHd kernel, eigenvalues, directions, scores.
#' @examples
#' X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
#' fit <- compute_phd(X, y = mtcars$mpg)
#' head(fit$eigenvalues)
#' @export
compute_phd <- function(
    X,
    y,
    Sigma = NULL,
    eps = 1e-8
) {

  X <- check_X(X)
  y <- check_y_continuous(y, nrow(X))
  check_missing(X, y)

  if (is.null(Sigma)) {
    Sigma <- stats::cov(X)
  }

  std <- standardize_by_cov(X, Sigma, eps = eps)
  Z <- std$Z

  n <- nrow(Z)
  p <- ncol(Z)

  y_centered <- y - mean(y)
  weighted_Z <- Z * y_centered
  M <- crossprod(Z, weighted_Z) / n
  M <- (M + t(M)) / 2

  decomp <- decompose_kernel(M, sort_by_abs = TRUE)

  B <- std$Sigma_inv_sqrt %*% decomp$directions
  X_centered <- sweep(X, 2, std$center, "-")
  scores <- X_centered %*% B

  list(
    method = "phd",
    kernel = decomp$kernel,
    eigenvalues = decomp$eigenvalues,
    directions = B,
    z_directions = decomp$directions,
    scores = scores,
    center = std$center,
    sdr_center = std$center,
    Sigma = Sigma
  )
}


#' General SDR kernel dispatcher
#'
#' @param X Numeric predictor matrix.
#' @param y Numeric response vector.
#' @param method SDR method.
#' @param Sigma Covariance matrix.
#' @param nslices Number of slices.
#' @param ... Additional arguments passed to internal methods.
#'
#' @return SDR fit components.
#' @examples
#' X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
#' Sigma <- cov_oas(X)
#' fit <- compute_sdr(
#'   X,
#'   y = mtcars$mpg,
#'   method = "sir",
#'   Sigma = Sigma,
#'   nslices = 4
#' )
#' dim(fit$scores)
#' @export
compute_sdr <- function(
    X,
    y,
    method = c("dr", "sir", "save", "phd"),
    Sigma = NULL,
    nslices = 6,
    ...
) {

  method <- check_sdr_method(method)

  if (method == "sir") {
    return(compute_sir(X = X, y = y, Sigma = Sigma, nslices = nslices, ...))
  }

  if (method == "save") {
    return(compute_save(X = X, y = y, Sigma = Sigma, nslices = nslices, ...))
  }

  if (method == "dr") {
    return(compute_dr(X = X, y = y, Sigma = Sigma, nslices = nslices, ...))
  }

  if (method == "phd") {
    return(compute_phd(X = X, y = y, Sigma = Sigma, ...))
  }
}
