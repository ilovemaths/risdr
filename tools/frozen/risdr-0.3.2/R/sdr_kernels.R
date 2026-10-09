# ============================================================
# R/sdr_kernels.R
# Survival-aware sufficient dimension reduction kernels for risdr
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

  eig <- eigen(Sigma, symmetric = TRUE)
  values <- pmax(eig$values, eps)

  inv_sqrt <- eig$vectors %*%
    diag(1 / sqrt(values), nrow = length(values)) %*%
    t(eig$vectors)

  (inv_sqrt + t(inv_sqrt)) / 2
}


#' Standardise predictors using covariance matrix
#'
#' @param X Numeric predictor matrix.
#' @param Sigma Covariance matrix.
#' @param center Optional centring vector.
#' @param eps Eigenvalue floor.
#'
#' @return A list containing standardised predictors and centring information.
#' @keywords internal
standardize_by_cov <- function(X, Sigma, center = NULL, eps = 1e-8) {

  X <- check_X(X)
  Sigma <- check_cov_matrix(Sigma)

  if (ncol(X) != ncol(Sigma)) {
    stop(
      "Number of columns in `X` must match dimension of `Sigma`.",
      call. = FALSE
    )
  }

  if (is.null(center)) {
    center <- colMeans(X)
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
#' @param sort_by_abs Logical. Sort by absolute eigenvalue magnitude.
#'
#' @return A list with kernel, eigenvalues, and directions.
#' @keywords internal
decompose_kernel <- function(M, sort_by_abs = FALSE) {

  M <- as.matrix(M)
  M <- (M + t(M)) / 2

  if (!is.numeric(M) || nrow(M) != ncol(M)) {
    stop("`M` must be a numeric square matrix.", call. = FALSE)
  }

  eig <- eigen(M, symmetric = TRUE)

  if (sort_by_abs) {
    ord <- order(abs(eig$values), decreasing = TRUE)
  } else {
    ord <- order(eig$values, decreasing = TRUE)
  }

  list(
    kernel = M,
    eigenvalues = eig$values[ord],
    directions = eig$vectors[, ord, drop = FALSE]
  )
}


.risdr_kernel_slice_labels <- function(
    y,
    nslices,
    response_type,
    delta = NULL,
    slice_type = c("quantile", "equal_width")
) {

  response_type <- match.arg(
    response_type,
    c("continuous", "categorical", "survival")
  )

  slice_type <- match.arg(slice_type)

  if (response_type == "continuous") {

    y <- check_y_continuous(y, length(y))

    groups <- make_slices(
      y = y,
      nslices = nslices,
      type = slice_type
    )

    return(
      list(
        groups = as.integer(groups),
        nslices = length(unique(groups)),
        labels = sort(unique(as.integer(groups))),
        response_type = "continuous"
      )
    )
  }

  if (response_type == "categorical") {

    if (anyNA(y)) {
      stop("`y` contains missing values.", call. = FALSE)
    }

    groups <- as.integer(as.factor(y))

    return(
      list(
        groups = groups,
        nslices = length(unique(groups)),
        labels = sort(unique(groups)),
        response_type = "categorical"
      )
    )
  }

  slice_response(
    y = y,
    nslices = nslices,
    response_type = "survival",
    delta = delta
  )
}


.risdr_validate_kernel_response <- function(
    X,
    y,
    response_type,
    delta = NULL
) {

  if (length(y) != nrow(X)) {
    stop(
      "Length of `y` must equal the number of rows in `X`.",
      call. = FALSE
    )
  }

  if (anyNA(y)) {
    stop("`y` contains missing values.", call. = FALSE)
  }

  if (response_type == "survival") {

    if (is.null(delta)) {
      stop(
        "For survival response, `delta` must be supplied.",
        call. = FALSE
      )
    }

    if (length(delta) != nrow(X)) {
      stop(
        "`delta` must have the same length as `y`.",
        call. = FALSE
      )
    }

    if (anyNA(delta)) {
      stop("`delta` contains missing values.", call. = FALSE)
    }

    delta_i <- as.integer(delta)

    if (!all(delta_i %in% c(0L, 1L))) {
      stop("`delta` must contain only 0/1 values.", call. = FALSE)
    }
  }

  invisible(TRUE)
}


.risdr_slice_covariance <- function(
    Z,
    idx,
    stabilize_slices,
    stabilization,
    eps
) {

  p <- ncol(Z)

  if (length(idx) <= 1L) {
    S <- matrix(0, nrow = p, ncol = p)
  } else {
    S <- stats::cov(Z[idx, , drop = FALSE])
  }

  S <- (S + t(S)) / 2

  if (stabilize_slices) {
    S <- stabilize_cov(
      S,
      method = stabilization,
      eps = eps
    )
  }

  S
}


#' Compute Sliced Inverse Regression
#'
#' Continuous responses use the existing scalar slicing rule. Censored survival
#' responses use status-specific time slicing through `slice_response()`.
#'
#' @param X Numeric predictor matrix.
#' @param y Response vector. For survival data, observed time.
#' @param Sigma Covariance matrix used for standardisation.
#' @param nslices Number of response slices, or slices per censoring-status
#'   group for survival data.
#' @param response_type One of `"continuous"`, `"categorical"`, or `"survival"`.
#' @param delta Optional 0/1 event indicator for survival data.
#' @param slice_type Continuous-response slicing strategy.
#' @param eps Eigenvalue floor.
#'
#' @return A list containing SIR kernel, eigenvalues, directions, scores,
#'   and realised slices.
#' @export
compute_sir <- function(
    X,
    y,
    Sigma = NULL,
    nslices = 6,
    response_type = c("continuous", "categorical", "survival"),
    delta = NULL,
    slice_type = c("quantile", "equal_width"),
    eps = 1e-8
) {

  X <- check_X(X)
  response_type <- match.arg(response_type)

  .risdr_validate_kernel_response(
    X = X,
    y = y,
    response_type = response_type,
    delta = delta
  )

  if (is.null(Sigma)) {
    Sigma <- stats::cov(X)
  }

  sl <- .risdr_kernel_slice_labels(
    y = y,
    nslices = nslices,
    response_type = response_type,
    delta = delta,
    slice_type = slice_type
  )

  slices <- sl$groups

  std <- standardize_by_cov(
    X = X,
    Sigma = Sigma,
    eps = eps
  )

  Z <- std$Z

  n <- nrow(Z)
  p <- ncol(Z)

  M <- matrix(0, nrow = p, ncol = p)

  slice_ids <- sort(unique(slices))

  for (h in slice_ids) {

    idx <- which(slices == h)
    Zh <- Z[idx, , drop = FALSE]

    p_h <- nrow(Zh) / n
    mu_h <- matrix(colMeans(Zh), ncol = 1)

    M <- M + p_h * tcrossprod(mu_h)
  }

  M <- (M + t(M)) / 2

  decomp <- decompose_kernel(M)

  B <- std$Sigma_inv_sqrt %*% decomp$directions

  X_centered <- sweep(
    X,
    2,
    std$center,
    "-"
  )

  scores <- X_centered %*% B

  list(
    method = "sir",
    kernel = decomp$kernel,
    eigenvalues = decomp$eigenvalues,
    directions = B,
    z_directions = decomp$directions,
    scores = scores,
    slices = slices,
    slice_metadata = sl,
    center = std$center,
    sdr_center = std$center,
    Sigma = Sigma,
    response_type = response_type
  )
}


#' Compute Sliced Average Variance Estimation
#'
#' @param X Numeric predictor matrix.
#' @param y Response vector. For survival data, observed time.
#' @param Sigma Covariance matrix used for standardisation.
#' @param nslices Number of response slices, or slices per censoring-status
#'   group for survival data.
#' @param response_type One of `"continuous"`, `"categorical"`, or `"survival"`.
#' @param delta Optional 0/1 event indicator for survival data.
#' @param slice_type Continuous-response slicing strategy.
#' @param stabilize_slices Logical. Stabilise slice covariance matrices.
#' @param stabilization Stabilisation method.
#' @param eps Eigenvalue floor.
#'
#' @return A list containing SAVE kernel, eigenvalues, directions, scores,
#'   and realised slices.
#' @export
compute_save <- function(
    X,
    y,
    Sigma = NULL,
    nslices = 6,
    response_type = c("continuous", "categorical", "survival"),
    delta = NULL,
    slice_type = c("quantile", "equal_width"),
    stabilize_slices = TRUE,
    stabilization = c("eigenfloor", "ridge", "nearest_pd"),
    eps = 1e-8
) {

  X <- check_X(X)
  response_type <- match.arg(response_type)
  stabilization <- match.arg(stabilization)

  .risdr_validate_kernel_response(
    X = X,
    y = y,
    response_type = response_type,
    delta = delta
  )

  if (is.null(Sigma)) {
    Sigma <- stats::cov(X)
  }

  sl <- .risdr_kernel_slice_labels(
    y = y,
    nslices = nslices,
    response_type = response_type,
    delta = delta,
    slice_type = slice_type
  )

  slices <- sl$groups

  std <- standardize_by_cov(
    X = X,
    Sigma = Sigma,
    eps = eps
  )

  Z <- std$Z

  n <- nrow(Z)
  p <- ncol(Z)
  I_p <- diag(p)

  M <- matrix(0, nrow = p, ncol = p)

  slice_ids <- sort(unique(slices))

  for (h in slice_ids) {

    idx <- which(slices == h)

    p_h <- length(idx) / n

    Sigma_h <- .risdr_slice_covariance(
      Z = Z,
      idx = idx,
      stabilize_slices = stabilize_slices,
      stabilization = stabilization,
      eps = eps
    )

    A_h <- I_p - Sigma_h

    M <- M + p_h * (A_h %*% A_h)
  }

  M <- (M + t(M)) / 2

  decomp <- decompose_kernel(M)

  B <- std$Sigma_inv_sqrt %*% decomp$directions

  X_centered <- sweep(
    X,
    2,
    std$center,
    "-"
  )

  scores <- X_centered %*% B

  list(
    method = "save",
    kernel = decomp$kernel,
    eigenvalues = decomp$eigenvalues,
    directions = B,
    z_directions = decomp$directions,
    scores = scores,
    slices = slices,
    slice_metadata = sl,
    center = std$center,
    sdr_center = std$center,
    Sigma = Sigma,
    response_type = response_type
  )
}


#' Compute Directional Regression
#'
#' Uses the canonical pairwise-slice directional-regression kernel. Censored
#' survival responses use censoring-status-specific time slices.
#'
#' @param X Numeric predictor matrix.
#' @param y Response vector. For survival data, observed time.
#' @param Sigma Covariance matrix used for standardisation.
#' @param nslices Number of response slices, or slices per censoring-status
#'   group for survival data.
#' @param response_type One of `"continuous"`, `"categorical"`, or `"survival"`.
#' @param delta Optional 0/1 event indicator for survival data.
#' @param slice_type Continuous-response slicing strategy.
#' @param stabilize_slices Logical. Stabilise slice covariance matrices.
#' @param stabilization Stabilisation method.
#' @param eps Eigenvalue floor.
#'
#' @return A list containing DR kernel, eigenvalues, directions, scores,
#'   and realised slices.
#' @export
compute_dr <- function(
    X,
    y,
    Sigma = NULL,
    nslices = 6,
    response_type = c("continuous", "categorical", "survival"),
    delta = NULL,
    slice_type = c("quantile", "equal_width"),
    stabilize_slices = TRUE,
    stabilization = c("eigenfloor", "ridge", "nearest_pd"),
    eps = 1e-8
) {

  X <- check_X(X)
  response_type <- match.arg(response_type)
  stabilization <- match.arg(stabilization)

  .risdr_validate_kernel_response(
    X = X,
    y = y,
    response_type = response_type,
    delta = delta
  )

  if (is.null(Sigma)) {
    Sigma <- stats::cov(X)
  }

  sl <- .risdr_kernel_slice_labels(
    y = y,
    nslices = nslices,
    response_type = response_type,
    delta = delta,
    slice_type = slice_type
  )

  slices <- sl$groups

  std <- standardize_by_cov(
    X = X,
    Sigma = Sigma,
    eps = eps
  )

  Z <- std$Z

  n <- nrow(Z)
  p <- ncol(Z)
  I_p <- diag(p)

  M <- matrix(0, nrow = p, ncol = p)

  slice_ids <- sort(unique(slices))
  H_eff <- length(slice_ids)

  p_h <- numeric(H_eff)
  mu_h <- vector("list", H_eff)
  Sigma_h <- vector("list", H_eff)

  names(p_h) <- names(mu_h) <- names(Sigma_h) <- as.character(slice_ids)

  for (h in slice_ids) {

    key <- as.character(h)
    idx <- which(slices == h)

    p_h[key] <- length(idx) / n
    mu_h[[key]] <- matrix(
      colMeans(Z[idx, , drop = FALSE]),
      ncol = 1
    )

    Sigma_h[[key]] <- .risdr_slice_covariance(
      Z = Z,
      idx = idx,
      stabilize_slices = stabilize_slices,
      stabilization = stabilization,
      eps = eps
    )
  }

  for (h in slice_ids) {
    for (k in slice_ids) {

      key_h <- as.character(h)
      key_k <- as.character(k)

      delta_hk <- mu_h[[key_h]] - mu_h[[key_k]]

      A_hk <-
        Sigma_h[[key_h]] +
        Sigma_h[[key_k]] +
        tcrossprod(delta_hk)

      D_hk <- 2 * I_p - A_hk

      M <- M +
        p_h[key_h] *
        p_h[key_k] *
        (D_hk %*% D_hk)
    }
  }

  M <- (M + t(M)) / 2

  decomp <- decompose_kernel(M)

  B <- std$Sigma_inv_sqrt %*% decomp$directions

  X_centered <- sweep(
    X,
    2,
    std$center,
    "-"
  )

  scores <- X_centered %*% B

  list(
    method = "dr",
    kernel = decomp$kernel,
    eigenvalues = decomp$eigenvalues,
    directions = B,
    z_directions = decomp$directions,
    scores = scores,
    slices = slices,
    slice_metadata = sl,
    center = std$center,
    sdr_center = std$center,
    Sigma = Sigma,
    response_type = response_type
  )
}


#' Compute Principal Hessian Directions
#'
#' @param X Numeric predictor matrix.
#' @param y Numeric continuous response vector.
#' @param Sigma Covariance matrix used for standardisation.
#' @param eps Eigenvalue floor.
#'
#' @return A list containing pHd kernel, eigenvalues, directions, and scores.
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

  std <- standardize_by_cov(
    X = X,
    Sigma = Sigma,
    eps = eps
  )

  Z <- std$Z

  n <- nrow(Z)
  p <- ncol(Z)

  y_centered <- y - mean(y)

  M <- matrix(0, nrow = p, ncol = p)

  for (i in seq_len(n)) {

    zi <- matrix(Z[i, ], ncol = 1)

    M <- M +
      y_centered[i] *
      tcrossprod(zi)
  }

  M <- M / n
  M <- (M + t(M)) / 2

  decomp <- decompose_kernel(
    M,
    sort_by_abs = TRUE
  )

  B <- std$Sigma_inv_sqrt %*% decomp$directions

  X_centered <- sweep(
    X,
    2,
    std$center,
    "-"
  )

  scores <- X_centered %*% B

  list(
    method = "phd",
    kernel = decomp$kernel,
    eigenvalues = decomp$eigenvalues,
    directions = B,
    z_directions = decomp$directions,
    scores = scores,
    slices = NULL,
    slice_metadata = NULL,
    center = std$center,
    sdr_center = std$center,
    Sigma = Sigma,
    response_type = "continuous"
  )
}


#' General SDR kernel dispatcher
#'
#' @param X Numeric predictor matrix.
#' @param y Response vector.
#' @param method SDR method.
#' @param Sigma Covariance matrix.
#' @param nslices Number of slices.
#' @param response_type Response type.
#' @param delta Optional event indicator.
#' @param ... Additional arguments passed to internal methods.
#'
#' @return SDR fit components.
#' @export
compute_sdr <- function(
    X,
    y,
    method = c("dr", "sir", "save", "phd"),
    Sigma = NULL,
    nslices = 6,
    response_type = c("continuous", "categorical", "survival"),
    delta = NULL,
    ...
) {

  method <- match.arg(method)
  response_type <- match.arg(response_type)

  if (method == "sir") {
    return(
      compute_sir(
        X = X,
        y = y,
        Sigma = Sigma,
        nslices = nslices,
        response_type = response_type,
        delta = delta,
        ...
      )
    )
  }

  if (method == "save") {
    return(
      compute_save(
        X = X,
        y = y,
        Sigma = Sigma,
        nslices = nslices,
        response_type = response_type,
        delta = delta,
        ...
      )
    )
  }

  if (method == "dr") {
    return(
      compute_dr(
        X = X,
        y = y,
        Sigma = Sigma,
        nslices = nslices,
        response_type = response_type,
        delta = delta,
        ...
      )
    )
  }

  if (response_type != "continuous") {
    stop(
      "`phd` is currently restricted to continuous responses.",
      call. = FALSE
    )
  }

  compute_phd(
    X = X,
    y = y,
    Sigma = Sigma,
    ...
  )
}
