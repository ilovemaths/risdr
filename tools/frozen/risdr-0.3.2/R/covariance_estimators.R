# ============================================================
# R/covariance_estimators.R
# Covariance estimators for risdr
# ============================================================


#' Sample covariance matrix
#'
#' @param X Numeric matrix or data frame.
#' @return A covariance matrix.
#' @export
cov_sample <- function(X) {

  X <- check_X(X)

  stats::cov(X)
}


#' Ridge-type covariance estimator
#'
#' @param X Numeric matrix or data frame.
#' @param lambda Shrinkage intensity between 0 and 1, inclusive.
#' @return A covariance matrix.
#' @export
cov_ridge <- function(X, lambda = 0.10) {

  X <- check_X(X)

  if (
    !is.numeric(lambda) ||
    length(lambda) != 1L ||
    is.na(lambda) ||
    lambda < 0 ||
    lambda > 1
  ) {
    stop(
      "`lambda` must be a single numeric value in [0, 1].",
      call. = FALSE
    )
  }

  S <- stats::cov(X)
  p <- ncol(S)

  target <- mean(diag(S)) * diag(p)

  Sigma <- (1 - lambda) * S + lambda * target

  (Sigma + t(Sigma)) / 2
}


#' Oracle Approximating Shrinkage based covariance estimator
#'
#' Implements the OAS-based stabilised covariance construction used by the
#' thesis development workflow. The empirical covariance is first spectrally
#' stabilised and OAS-shrunk, followed by the package's second diagonal-target
#' mixing step.
#'
#' @param X Numeric matrix or data frame.
#' @param tol Numerical tolerance.
#' @return A covariance matrix with shrinkage diagnostics as attributes.
#' @export
cov_oas <- function(X, tol = 1e-10) {

  X <- check_X(X)

  n <- nrow(X)
  p <- ncol(X)

  S <- ((n - 1) / n) * stats::cov(X)
  S <- (S + t(S)) / 2

  eigS <- eigen(
    S,
    symmetric = TRUE
  )

  vecs <- eigS$vectors
  vals <- eigS$values

  vals[vals < tol] <- tol

  lambda_star <- pmax(
    vals,
    rep(mean(vals), length(vals))
  )

  STA <- vecs %*%
    diag(lambda_star, nrow = p) %*%
    t(vecs)

  STA <- (STA + t(STA)) / 2

  tr_sta <- sum(diag(STA))
  tr_sta2 <- sum(STA * STA)

  numerator <-
    (1 - 2 / p) * tr_sta2 +
    tr_sta^2

  denominator <-
    (p + 1 - 2 / p) *
    (
      tr_sta2 -
      tr_sta^2 / p +
      tr_sta^2
    )

  if (!is.finite(denominator) || abs(denominator) < tol) {
    rho_oas <- 1
  } else {
    rho_oas <- numerator / denominator
  }

  rho_oas <- max(
    0,
    min(1, rho_oas)
  )

  target <- tr_sta * diag(p) / p

  OAS <-
    (1 - rho_oas) * STA +
    rho_oas * target

  OAS <- (OAS + t(OAS)) / 2

  tr_oas <- sum(diag(OAS))
  tr_oas2 <- sum(OAS * OAS)

  beta <-
    tr_oas^2 /
    max(tol, tr_oas2)

  alpha_shape <-
    2 *
    (p * (1 + beta) - 2) /
    max(tol, p - beta)

  m_val <- alpha_shape / 2

  rho <- n / (n + m_val)

  Sigma <-
    rho * OAS +
    (1 - rho) * target

  Sigma <- (Sigma + t(Sigma)) / 2

  attr(Sigma, "rho") <- rho
  attr(Sigma, "alpha") <- rho
  attr(Sigma, "rho_oas") <- rho_oas
  attr(Sigma, "beta") <- beta
  attr(Sigma, "alpha_shape") <- alpha_shape
  attr(Sigma, "method") <- "oas"

  Sigma
}


#' Ledoit-Wolf type covariance estimator
#'
#' @param X Numeric matrix or data frame.
#' @return A covariance matrix.
#' @export
cov_lw <- function(X) {

  X <- check_X(X)

  Xc <- scale(
    X,
    center = TRUE,
    scale = FALSE
  )

  n <- nrow(Xc)
  p <- ncol(Xc)

  S <- crossprod(Xc) / n
  target <- mean(diag(S)) * diag(p)

  phi_mat <- matrix(
    0,
    nrow = p,
    ncol = p
  )

  for (i in seq_len(n)) {

    xi <- matrix(
      Xc[i, ],
      ncol = 1
    )

    Si <- xi %*% t(xi)

    phi_mat <- phi_mat + (Si - S)^2
  }

  phi <- sum(phi_mat) / n^2
  gamma <- sum((S - target)^2)

  if (gamma < .Machine$double.eps) {
    rho <- 1
  } else {
    rho <- phi / gamma
  }

  rho <- max(
    0,
    min(1, rho)
  )

  Sigma <-
    (1 - rho) * S +
    rho * target

  Sigma <- (Sigma + t(Sigma)) / 2

  attr(Sigma, "rho") <- rho
  attr(Sigma, "alpha") <- rho
  attr(Sigma, "method") <- "lw"

  Sigma
}


.risdr_mec_slice_covariances <- function(
    X,
    groups
) {

  levs <- sort(unique(groups))

  covariances <- vector(
    "list",
    length(levs)
  )

  counts <- integer(
    length(levs)
  )

  names(covariances) <- as.character(levs)
  names(counts) <- as.character(levs)

  p <- ncol(X)

  for (i in seq_along(levs)) {

    idx <- which(groups == levs[i])

    counts[i] <- length(idx)

    if (length(idx) <= 1L) {
      covariances[[i]] <- matrix(
        0,
        nrow = p,
        ncol = p
      )
    } else {
      covariances[[i]] <- stats::cov(
        X[idx, , drop = FALSE]
      )
    }

    covariances[[i]] <-
      (
        covariances[[i]] +
        t(covariances[[i]])
      ) / 2
  }

  list(
    covariances = covariances,
    counts = counts,
    labels = levs
  )
}


#' Maximum Entropy Covariance estimator
#'
#' Implements the entropy-guided pooled-slice covariance construction used in
#' the survival-capable thesis development workflow. For censored survival data,
#' slicing is performed jointly through censoring status and observed time via
#' `slice_response()`.
#'
#' @param X Numeric matrix or data frame.
#' @param y Response vector. For survival data, observed time.
#' @param nslices Number of slices, or slices per censoring-status group.
#' @param response_type One of `"continuous"`, `"categorical"`, or `"survival"`.
#' @param delta Optional 0/1 event indicator for survival data.
#' @param tol Numerical tolerance.
#' @param ... Reserved for compatibility.
#' @return A covariance matrix with MEC diagnostics as attributes.
#' @export
cov_mec <- function(
    X,
    y,
    nslices = 6,
    response_type = c("continuous", "categorical", "survival"),
    delta = NULL,
    tol = 1e-10,
    ...
) {

  X <- check_X(X)

  response_type <- match.arg(response_type)

  if (length(y) != nrow(X)) {
    stop(
      "Length of `y` must equal the number of rows in `X`.",
      call. = FALSE
    )
  }

  sl <- slice_response(
    y = y,
    nslices = nslices,
    response_type = response_type,
    delta = delta
  )

  groups <- sl$groups

  p <- ncol(X)
  n <- nrow(X)

  slice_info <- .risdr_mec_slice_covariances(
    X = X,
    groups = groups
  )

  S_list <- slice_info$covariances
  counts <- slice_info$counts
  H <- length(S_list)

  if (H < 1L) {
    stop("No realised slices were available.", call. = FALSE)
  }

  if (n <= H) {
    stop(
      "Too few observations relative to realised slices for pooled MEC covariance.",
      call. = FALSE
    )
  }

  Sp <- matrix(
    0,
    nrow = p,
    ncol = p
  )

  for (h in seq_len(H)) {

    Sp <- Sp +
      ((counts[h] - 1) / (n - H)) *
      S_list[[h]]
  }

  Sp <- (Sp + t(Sp)) / 2

  entropy_vals <- rep(
    -Inf,
    H
  )

  for (h in seq_len(H)) {

    eigvals <- eigen(
      S_list[[h]],
      symmetric = TRUE,
      only.values = TRUE
    )$values

    eigvals <- eigvals[
      eigvals > tol
    ]

    if (length(eigvals) > 0L) {

      entropy_vals[h] <-
        p / 2 +
        0.5 * sum(log(eigvals)) +
        p / 2 * log(2 * pi)
    }
  }

  if (all(!is.finite(entropy_vals))) {
    stop(
      "No slice supplied a positive-eigenvalue entropy calculation.",
      call. = FALSE
    )
  }

  h_star <- which.max(
    entropy_vals
  )

  S_star <- S_list[[h_star]]

  mix <- S_star + Sp
  mix <- (mix + t(mix)) / 2

  eig_mix <- eigen(
    mix,
    symmetric = TRUE
  )

  U <- eig_mix$vectors

  z_star <- diag(
    t(U) %*%
      S_star %*%
      U
  )

  z_pool <- diag(
    t(U) %*%
      Sp %*%
      U
  )

  z_mean <- mean(z_star)

  z_mec <- pmax(
    z_mean,
    z_pool
  )

  S_mec0 <-
    U %*%
    diag(z_mec, nrow = p) %*%
    t(U)

  S_mec0 <- (S_mec0 + t(S_mec0)) / 2

  tr_mec <- sum(
    diag(S_mec0)
  )

  target <-
    tr_mec *
    diag(p) /
    p

  beta <-
    tr_mec^2 /
    max(
      tol,
      sum(S_mec0 * S_mec0)
    )

  alpha_shape <-
    2 *
    (p * (1 + beta) - 2) /
    max(tol, p - beta)

  m_val <- alpha_shape / 2

  rho <- n / (n + m_val)

  Sigma <-
    rho * S_mec0 +
    (1 - rho) * target

  Sigma <- (Sigma + t(Sigma)) / 2

  attr(Sigma, "rho") <- rho
  attr(Sigma, "alpha") <- rho
  attr(Sigma, "beta") <- beta
  attr(Sigma, "alpha_shape") <- alpha_shape
  attr(Sigma, "entropy_slice") <- h_star
  attr(Sigma, "slice_entropy") <- entropy_vals
  attr(Sigma, "slice_counts") <- counts
  attr(Sigma, "realised_slices") <- H
  attr(Sigma, "response_type") <- response_type
  attr(Sigma, "method") <- "mec"

  Sigma
}


#' Estimate covariance matrix
#'
#' @param X Predictor matrix.
#' @param y Optional response vector.
#' @param method Covariance estimation method.
#' @param nslices Number of slices.
#' @param response_type Response type.
#' @param delta Optional censoring indicator.
#' @param cov_fun Optional user covariance estimator.
#' @param stabilization Stabilisation method.
#' @param shrinkage Numeric ridge shrinkage parameter.
#' @param eps Numerical stability constant.
#' @param ... Additional arguments passed only to user-defined covariance
#'   estimators.
#' @return Regularised covariance matrix.
#' @export
estimate_cov <- function(
    X,
    y = NULL,
    method = c("mec", "oas", "lw", "sample", "ridge", "user"),
    nslices = 5L,
    response_type = c("continuous", "categorical", "survival"),
    delta = NULL,
    cov_fun = NULL,
    stabilization = c("eigenfloor", "ridge", "nearest_pd"),
    shrinkage = 1e-4,
    eps = 1e-8,
    ...
) {

  method <- match.arg(method)
  response_type <- match.arg(response_type)
  stabilization <- match.arg(stabilization)

  X <- as.matrix(X)

  if (!is.numeric(X)) {
    stop("`X` must be numeric.", call. = FALSE)
  }

  Sigma <- switch(

    method,

    mec = cov_mec(
      X = X,
      y = y,
      nslices = nslices,
      response_type = response_type,
      delta = delta,
      tol = min(eps, 1e-10)
    ),

    oas = cov_oas(
      X = X,
      tol = min(eps, 1e-10)
    ),

    lw = cov_lw(
      X = X
    ),

    sample = {

      out <- stats::cov(X)

      attr(out, "rho") <- 0
      attr(out, "alpha") <- 0
      attr(out, "method") <- "sample"

      out
    },

    ridge = {

      S <- stats::cov(X)
      p <- ncol(S)

      out <- S + shrinkage * diag(p)

      attr(out, "rho") <- shrinkage
      attr(out, "alpha") <- shrinkage
      attr(out, "method") <- "ridge"

      out
    },

    user = {

      if (is.null(cov_fun) || !is.function(cov_fun)) {
        stop(
          "`cov_fun` must be supplied when method = 'user'.",
          call. = FALSE
        )
      }

      out <- cov_fun(
        X = X,
        y = y,
        nslices = nslices,
        response_type = response_type,
        delta = delta,
        ...
      )

      if (!is.matrix(out)) {
        stop(
          "User covariance estimator must return a matrix.",
          call. = FALSE
        )
      }

      if (is.null(attr(out, "alpha"))) {
        attr(out, "alpha") <- NA_real_
      }

      if (is.null(attr(out, "rho"))) {
        attr(out, "rho") <- attr(out, "alpha")
      }

      attr(out, "method") <- "user"

      out
    }
  )

  stored_attrs <- attributes(Sigma)

  Sigma <- stabilize_cov(
    Sigma,
    method = stabilization,
    lambda = shrinkage,
    eps = eps
  )

  for (nm in setdiff(
    names(stored_attrs),
    c("dim", "dimnames")
  )) {
    attr(Sigma, nm) <- stored_attrs[[nm]]
  }

  attr(Sigma, "method") <- method
  attr(Sigma, "response_type") <- response_type

  Sigma
}
