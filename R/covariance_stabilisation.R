# ============================================================
# R/covariance_stabilisation.R
# Covariance matrix stabilisation utilities for risdr
# ============================================================

#' Eigenvalue floor stabilisation
#'
#' Stabilises a symmetric covariance matrix by replacing eigenvalues smaller than
#' a positive threshold with that threshold.
#'
#' @param Sigma A square symmetric covariance matrix.
#' @param eps Positive eigenvalue floor.
#'
#' @return A symmetric positive definite covariance matrix.
#' @export
stabilize_eigenfloor <- function(Sigma, eps = 1e-6) {

  Sigma <- check_cov_matrix(Sigma)

  if (!is.numeric(eps) || length(eps) != 1 || !is.finite(eps) || eps <= 0) {
    stop("`eps` must be a single positive numeric value.", call. = FALSE)
  }

  eig <- eigen(Sigma, symmetric = TRUE)

  values <- pmax(eig$values, eps)

  Sigma_stable <- eig$vectors %*% diag(values, nrow = length(values)) %*% t(eig$vectors)

  Sigma_stable <- (Sigma_stable + t(Sigma_stable)) / 2

  Sigma_stable
}


#' Ridge stabilisation of covariance matrix
#'
#' Stabilises a covariance matrix by adding a positive multiple of the identity matrix.
#'
#' @param Sigma A square symmetric covariance matrix.
#' @param lambda Ridge stabilisation parameter.
#'
#' @return A symmetric positive definite covariance matrix.
#' @export
stabilize_ridge <- function(Sigma, lambda = 1e-4) {

  Sigma <- check_cov_matrix(Sigma)

  if (!is.numeric(lambda) || length(lambda) != 1 || !is.finite(lambda) ||
      lambda < 0) {
    stop("`lambda` must be a single non-negative numeric value.", call. = FALSE)
  }

  p <- ncol(Sigma)

  Sigma_stable <- Sigma + lambda * diag(p)
  Sigma_stable <- (Sigma_stable + t(Sigma_stable)) / 2

  Sigma_stable
}


#' Nearest positive definite stabilisation
#'
#' Stabilises a covariance matrix by projecting it to the nearest positive
#' definite matrix using Matrix::nearPD().
#'
#' @param Sigma A square symmetric covariance matrix.
#' @param keep_diag Logical. If TRUE, keeps original diagonal where possible.
#'
#' @return A symmetric positive definite covariance matrix.
#' @export
stabilize_nearest_pd <- function(Sigma, keep_diag = TRUE) {

  Sigma <- check_cov_matrix(Sigma)

  if (!is.logical(keep_diag) || length(keep_diag) != 1L || is.na(keep_diag)) {
    stop("`keep_diag` must be TRUE or FALSE.", call. = FALSE)
  }

  if (!requireNamespace("Matrix", quietly = TRUE)) {
    stop("Package `Matrix` is required for nearest positive definite stabilisation.", call. = FALSE)
  }

  Sigma_pd <- Matrix::nearPD(
    Sigma,
    corr = FALSE,
    keepDiag = keep_diag
  )$mat

  Sigma_pd <- as.matrix(Sigma_pd)
  Sigma_pd <- (Sigma_pd + t(Sigma_pd)) / 2

  Sigma_pd
}


#' General covariance stabilisation dispatcher
#'
#' Stabilises a covariance matrix using one of several available methods.
#'
#' @param Sigma A square symmetric covariance matrix.
#' @param method Stabilisation method.
#' @param eps Positive eigenvalue floor for eigenfloor method.
#' @param lambda Ridge parameter for ridge method.
#' @param keep_diag Logical. Used by nearest positive definite method.
#'
#' @return A stabilised covariance matrix.
#' @export
stabilize_cov <- function(
    Sigma,
    method = c("eigenfloor", "ridge", "nearest_pd"),
    eps = 1e-6,
    lambda = 1e-4,
    keep_diag = TRUE
) {

  method <- match.arg(method)

  if (method == "eigenfloor") {
    return(stabilize_eigenfloor(Sigma, eps = eps))
  }

  if (method == "ridge") {
    return(stabilize_ridge(Sigma, lambda = lambda))
  }

  if (method == "nearest_pd") {
    return(stabilize_nearest_pd(Sigma, keep_diag = keep_diag))
  }
}


#' Check covariance matrix
#'
#' Internal function for validating covariance matrix input.
#'
#' @param Sigma Matrix.
#'
#' @return A numeric square symmetric matrix.
#' @keywords internal
check_cov_matrix <- function(Sigma) {

  if (missing(Sigma) || is.null(Sigma)) {
    stop("`Sigma` must be supplied.", call. = FALSE)
  }

  if (!is.matrix(Sigma) && !is.data.frame(Sigma)) {
    stop("`Sigma` must be a matrix or data frame.", call. = FALSE)
  }

  Sigma <- as.matrix(Sigma)

  if (!is.numeric(Sigma)) {
    stop("`Sigma` must be numeric.", call. = FALSE)
  }

  if (nrow(Sigma) != ncol(Sigma)) {
    stop("`Sigma` must be square.", call. = FALSE)
  }

  if (any(!is.finite(Sigma))) {
    stop("`Sigma` contains non-finite values.", call. = FALSE)
  }

  if (max(abs(Sigma - t(Sigma))) > 1e-8) {
    warning("`Sigma` is not exactly symmetric. It has been symmetrised.", call. = FALSE)
    Sigma <- (Sigma + t(Sigma)) / 2
  }

  Sigma
}


#' Covariance condition number
#'
#' Computes the spectral condition number of a covariance matrix.
#'
#' @param Sigma A covariance matrix.
#' @param eps Small positive value used to avoid division by zero.
#'
#' @return Numeric condition number.
#' @export
cov_condition_number <- function(Sigma, eps = 1e-12) {

  Sigma <- check_cov_matrix(Sigma)

  if (!is.numeric(eps) || length(eps) != 1L || !is.finite(eps) || eps <= 0) {
    stop("`eps` must be a single positive numeric value.", call. = FALSE)
  }

  eig <- eigen(Sigma, symmetric = TRUE, only.values = TRUE)$values
  eig <- pmax(eig, eps)

  max(eig) / min(eig)
}


#' Effective covariance rank
#'
#' Computes the number of eigenvalues exceeding a threshold.
#'
#' @param Sigma A covariance matrix.
#' @param tol Positive threshold.
#'
#' @return Effective rank.
#' @export
cov_effective_rank <- function(Sigma, tol = 1e-6) {

  Sigma <- check_cov_matrix(Sigma)

  if (!is.numeric(tol) || length(tol) != 1L || !is.finite(tol) || tol < 0) {
    stop("`tol` must be a single non-negative numeric value.", call. = FALSE)
  }

  eig <- eigen(Sigma, symmetric = TRUE, only.values = TRUE)$values

  sum(eig > tol)
}


#' Covariance eigenvalue summary
#'
#' Provides diagnostic eigenvalue summaries for a covariance matrix.
#'
#' @param Sigma A covariance matrix.
#' @param tol Threshold for effective rank.
#'
#' @return A list of covariance diagnostics.
#' @export
cov_diagnostics <- function(Sigma, tol = 1e-6) {

  Sigma <- check_cov_matrix(Sigma)

  eig <- eigen(Sigma, symmetric = TRUE, only.values = TRUE)$values

  list(
    min_eigenvalue = min(eig),
    max_eigenvalue = max(eig),
    condition_number = cov_condition_number(Sigma),
    effective_rank = cov_effective_rank(Sigma, tol = tol),
    eigenvalues = eig
  )
}
