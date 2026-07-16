# ============================================================
# R/covariance_estimators.R
# Covariance estimators for risdr
# ============================================================

#' Sample covariance matrix
#'
#' Computes the usual unbiased sample covariance matrix.
#'
#' @param X Numeric matrix or data frame.
#'
#' @return A covariance matrix.
#' @export
cov_sample <- function(X) {

  X <- check_X(X)

  stats::cov(X)
}


#' Ridge-type covariance estimator
#'
#' Computes a convex shrinkage covariance estimator of the form
#' \deqn{\Sigma_{\lambda} = (1 - \lambda)S + \lambda T,}
#' where \eqn{S} is the sample covariance matrix and \eqn{T} is a scaled identity target.
#'
#' @param X Numeric matrix or data frame.
#' @param lambda Shrinkage intensity in \eqn{[0,1]}.
#'
#' @return A covariance matrix.
#' @export
cov_ridge <- function(X, lambda = 0.10) {

  X <- check_X(X)

  if (!is.numeric(lambda) || length(lambda) != 1 || !is.finite(lambda) ||
      lambda < 0 || lambda > 1) {
    stop("`lambda` must be a single numeric value in [0, 1].", call. = FALSE)
  }

  S <- stats::cov(X)
  p <- ncol(S)

  target <- mean(diag(S)) * diag(p)

  Sigma <- (1 - lambda) * S + lambda * target

  Sigma <- (Sigma + t(Sigma)) / 2

  Sigma
}


#' Oracle Approximating Shrinkage covariance estimator
#'
#' Computes a simplified Oracle Approximating Shrinkage (OAS) covariance estimator
#' for stabilising the sample covariance matrix.
#'
#' @param X Numeric matrix or data frame.
#'
#' @return A covariance matrix.
#' @export
cov_oas <- function(X) {

  X <- check_X(X)

  X <- scale(X, center = TRUE, scale = FALSE)

  n <- nrow(X)
  p <- ncol(X)

  S <- crossprod(X) / n

  trS <- sum(diag(S))
  trS2 <- sum(S * S)

  numerator <- (1 - 2 / p) * trS2 + trS^2
  denominator <- (n + 1 - 2 / p) * (trS2 - trS^2 / p)

  if (abs(denominator) < .Machine$double.eps) {
    rho <- 1
  } else {
    rho <- numerator / denominator
  }

  rho <- max(0, min(1, rho))

  target <- (trS / p) * diag(p)

  Sigma <- (1 - rho) * S + rho * target

  Sigma <- (Sigma + t(Sigma)) / 2

  attr(Sigma, "shrinkage") <- rho

  Sigma
}


#' Ledoit-Wolf type covariance estimator
#'
#' Computes a practical Ledoit-Wolf type shrinkage estimator toward a scaled identity target.
#'
#' @param X Numeric matrix or data frame.
#'
#' @return A covariance matrix.
#' @export
cov_lw <- function(X) {

  X <- check_X(X)

  X <- scale(X, center = TRUE, scale = FALSE)

  n <- nrow(X)
  p <- ncol(X)

  S <- crossprod(X) / n
  target <- mean(diag(S)) * diag(p)

  squared_row_norms <- rowSums(X^2)
  phi <- (
    sum(squared_row_norms^2) - n * sum(S^2)
  ) / n^2
  phi <- max(phi, 0)
  gamma <- sum((S - target)^2)

  if (gamma < .Machine$double.eps) {
    rho <- 1
  } else {
    rho <- phi / gamma
  }

  rho <- max(0, min(1, rho))

  Sigma <- (1 - rho) * S + rho * target

  Sigma <- (Sigma + t(Sigma)) / 2

  attr(Sigma, "shrinkage") <- rho

  Sigma
}


#' Maximum Entropy Covariance estimator
#'
#' Computes a maximum-entropy motivated covariance estimator for SDR.
#'
#' The estimator uses response slicing to obtain slice-specific covariance
#' matrices, selects the covariance matrix with maximum log-determinant entropy,
#' and combines it with the pooled covariance matrix through convex shrinkage.
#'
#' For censored survival responses, the function accepts `delta` and applies
#' a survival-aware response construction before slicing.
#'
#' @param X Numeric matrix or data frame.
#' @param y Numeric response vector.
#' @param nslices Number of response slices.
#' @param response_type Response type. One of `"continuous"`, `"categorical"`,
#'   or `"survival"`.
#' @param delta Optional event indicator for survival data.
#' @param alpha Convex weight assigned to the entropy-maximising slice
#'   covariance. If NULL, alpha is chosen adaptively from the condition number
#'   of the pooled covariance.
#' @param eps Small positive eigenvalue floor used for log-determinant stability.
#' @param ... Additional arguments passed to internal methods.
#'
#' @return A covariance matrix with attributes containing the shrinkage weight
#'   and entropy diagnostics.
#' @export
cov_mec <- function(
    X,
    y,
    nslices = 6,
    response_type = c("continuous", "categorical", "survival"),
    delta = NULL,
    alpha = NULL,
    eps = 1e-6,
    ...
) {

  X <- check_X(X)

  response_type <- match.arg(response_type)

  if (length(y) != nrow(X)) {
    stop(
      "`y` must have length equal to the number of rows in `X`.",
      call. = FALSE
    )
  }

  if (anyNA(y)) {
    stop("`y` contains missing values.", call. = FALSE)
  }

  if (response_type == "survival") {

    y <- check_y_continuous(y, nrow(X))

    if (is.null(delta)) {
      stop(
        "`delta` must be supplied when `response_type = 'survival'`.",
        call. = FALSE
      )
    }

    if (length(delta) != length(y)) {
      stop(
        "`delta` must have the same length as `y`.",
        call. = FALSE
      )
    }

    delta <- as.numeric(delta)

    if (anyNA(delta) || any(!is.finite(delta)) ||
        !all(delta %in% c(0, 1))) {
      stop(
        "`delta` must contain only 0 and 1 values.",
        call. = FALSE
      )
    }

    # Survival-aware observed response construction for slicing.
    # This keeps event-time information for uncensored observations and
    # compresses censored observations through their censoring indicator.
    y_slice <- y * delta

    nslices <- check_nslices(nslices, nrow(X))
    slices <- make_slices(y = y_slice, nslices = nslices)

  } else if (response_type == "categorical") {

    y_factor <- factor(y)

    if (nlevels(y_factor) < 2L) {
      stop("Categorical `y` must contain at least two observed levels.", call. = FALSE)
    }

    slices <- as.integer(y_factor)
    nslices <- nlevels(y_factor)

  } else {

    y_slice <- check_y_continuous(y, nrow(X))
    nslices <- check_nslices(nslices, nrow(X))
    slices <- make_slices(y = y_slice, nslices = nslices)
  }

  if (!is.numeric(eps) || length(eps) != 1 || !is.finite(eps) || eps <= 0) {
    stop("`eps` must be a positive numeric value.", call. = FALSE)
  }

  S_pooled <- stats::cov(X)
  S_pooled <- stabilize_eigenfloor(S_pooled, eps = eps)

  slice_covs <- vector("list", nslices)
  slice_entropy <- rep(NA_real_, nslices)

  for (h in seq_len(nslices)) {

    idx <- which(slices == h)

    if (length(idx) < 2) {
      next
    }

    Xh <- X[idx, , drop = FALSE]

    Sh <- stats::cov(Xh)
    Sh <- stabilize_eigenfloor(Sh, eps = eps)

    eig_h <- eigen(
      Sh,
      symmetric = TRUE,
      only.values = TRUE
    )$values

    eig_h <- pmax(eig_h, eps)

    slice_covs[[h]] <- Sh
    slice_entropy[h] <- sum(log(eig_h))
  }

  if (all(is.na(slice_entropy))) {
    warning(
      "No valid slice covariance matrix was available. Returning stabilised pooled covariance.",
      call. = FALSE
    )

    attr(S_pooled, "alpha") <- 0
    attr(S_pooled, "entropy_slice") <- NA_integer_
    attr(S_pooled, "slice_entropy") <- slice_entropy
    attr(S_pooled, "response_type") <- response_type

    return(S_pooled)
  }

  h_star <- which.max(slice_entropy)
  S_entropy <- slice_covs[[h_star]]

  if (is.null(alpha)) {

    eig_pool <- eigen(
      S_pooled,
      symmetric = TRUE,
      only.values = TRUE
    )$values

    eig_pool <- pmax(eig_pool, eps)

    cond_pool <- max(eig_pool) / min(eig_pool)

    alpha <- cond_pool / (cond_pool + nrow(X))
    alpha <- max(0.05, min(0.95, alpha))
  }

  if (!is.numeric(alpha) || length(alpha) != 1 || !is.finite(alpha) ||
      alpha < 0 || alpha > 1) {
    stop(
      "`alpha` must be NULL or a single numeric value in [0, 1].",
      call. = FALSE
    )
  }

  Sigma <- (1 - alpha) * S_pooled + alpha * S_entropy
  Sigma <- (Sigma + t(Sigma)) / 2
  Sigma <- stabilize_eigenfloor(Sigma, eps = eps)

  attr(Sigma, "alpha") <- alpha
  attr(Sigma, "entropy_slice") <- h_star
  attr(Sigma, "slice_entropy") <- slice_entropy
  attr(Sigma, "response_type") <- response_type

  Sigma
}

#' General covariance estimator dispatcher
#'
#' Dispatches to the requested covariance estimator. For MEC, the function
#' supports continuous, categorical, and censored survival responses by passing
#' `response_type` and `delta` to `cov_mec()`.
#'
#' @param X Numeric matrix or data frame.
#' @param y Optional response vector required for MEC.
#' @param method Covariance estimator.
#' @param nslices Number of slices for MEC.
#' @param response_type Response type. One of `"continuous"`, `"categorical"`,
#'   or `"survival"`.
#' @param delta Optional event indicator for survival data.
#' @param ... Additional arguments passed to internal covariance estimators.
#'
#' @return A covariance matrix.
#' @export
estimate_cov <- function(
    X,
    y = NULL,
    method = c("sample", "ridge", "oas", "lw", "mec"),
    nslices = 6,
    response_type = c("continuous", "categorical", "survival"),
    delta = NULL,
    ...
) {

  X <- check_X(X)

  method <- check_cov_method(method)
  response_type <- match.arg(response_type)

  if (method == "sample") {
    return(cov_sample(X))
  }

  if (method == "ridge") {
    return(cov_ridge(X, ...))
  }

  if (method == "oas") {
    return(cov_oas(X))
  }

  if (method == "lw") {
    return(cov_lw(X))
  }

  if (method == "mec") {

    if (is.null(y)) {
      stop(
        "`y` must be supplied when `method = 'mec'`.",
        call. = FALSE
      )
    }

    return(
      cov_mec(
        X = X,
        y = y,
        nslices = nslices,
        response_type = response_type,
        delta = delta,
        ...
      )
    )
  }
}
