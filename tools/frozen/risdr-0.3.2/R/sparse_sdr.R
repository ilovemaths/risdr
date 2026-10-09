# ============================================================
# R/sparse_sdr.R
# Adaptive sparse-direction support for risdr
# ============================================================

#' C1F complexity and induced adaptive weights
#'
#' Computes cumulative scale-invariant covariance complexity from leading
#' eigenvalues and converts the complexity profile to relative weights.
#'
#' @param evals Numeric vector of eigenvalues.
#' @param positive_only Logical; retain only positive eigenvalues.
#' @param cumulative Logical; compute cumulative C1F values.
#' @param tol Numerical tolerance.
#' @return A list with C1F values, induced weights, and processed eigenvalues.
#' @export
C1F <- function(
    evals,
    positive_only = TRUE,
    cumulative = TRUE,
    tol = 1e-10
) {

  evals <- as.numeric(evals)

  if (positive_only) {
    evals <- evals[evals > tol]
  }

  if (length(evals) == 0L) {
    return(
      list(
        c1f = 0,
        weights = 1,
        evals = numeric(0)
      )
    )
  }

  evals <- sort(evals, decreasing = TRUE)

  c1f_scalar <- function(x) {

    lam_bar <- mean(x)

    if (abs(lam_bar) < tol) {
      return(0)
    }

    sum((x - lam_bar)^2) / (4 * lam_bar^2)
  }

  if (cumulative) {

    c1f_vals <- vapply(
      seq_along(evals),
      function(k) {
        c1f_scalar(evals[seq_len(k)])
      },
      numeric(1)
    )

  } else {

    c1f_vals <- c1f_scalar(evals)
  }

  delta <- c1f_vals - min(c1f_vals)

  weights <- exp(-0.5 * delta)
  weights <- weights / sum(weights)

  list(
    c1f = c1f_vals,
    weights = weights,
    evals = evals
  )
}


#' Expand penalty weights to predictor dimension
#'
#' @param w Numeric vector of weights.
#' @param p Number of predictors.
#' @param normalise Logical; rescale weights to mean one.
#' @param tol Numerical tolerance.
#' @return Numeric vector of length `p`.
#' @export
expand_penalty_weights <- function(
    w,
    p,
    normalise = TRUE,
    tol = 1e-10
) {

  w <- as.numeric(w)

  if (length(w) == 0L) {
    w <- rep(1, p)
  } else if (length(w) == 1L) {
    w <- rep(w, p)
  } else if (length(w) != p) {
    w <- rep(w, length.out = p)
  }

  w[!is.finite(w) | w < tol] <- tol

  if (normalise) {
    w <- w / mean(w)
  }

  w
}


#' Variable-level contributions to C1F covariance complexity
#'
#' Decomposes the scale-invariant C1F covariance-complexity measure into
#' original-coordinate contributions. If
#' \eqn{\Sigma = U \Lambda U^\top}, the contribution of variable \eqn{j}
#' is
#' \deqn{
#' c_j = \frac{1}{4\bar\lambda^2}
#'       \sum_r u_{jr}^2(\lambda_r-\bar\lambda)^2.
#' }
#' The contributions sum to the scalar C1F complexity and transform
#' equivariantly when predictor columns are permuted.
#'
#' @param Sigma Numeric covariance matrix.
#' @param tol Numerical tolerance.
#' @return Numeric vector of non-negative variable-level C1F contributions.
#' @keywords internal
c1f_variable_contributions <- function(
    Sigma,
    tol = 1e-10
) {

  Sigma <- as.matrix(Sigma)

  if (
    !is.numeric(Sigma) ||
    nrow(Sigma) != ncol(Sigma)
  ) {
    stop(
      "`Sigma` must be a numeric square matrix.",
      call. = FALSE
    )
  }

  Sigma <- (Sigma + t(Sigma)) / 2

  eig <- eigen(
    Sigma,
    symmetric = TRUE
  )

  lambda <- as.numeric(
    eig$values
  )

  lambda[
    !is.finite(lambda) |
    lambda < tol
  ] <- tol

  lambda_bar <- mean(lambda)

  if (
    !is.finite(lambda_bar) ||
    lambda_bar <= tol
  ) {
    return(
      rep(
        0,
        nrow(Sigma)
      )
    )
  }

  spectral_deviation <-
    (lambda - lambda_bar)^2

  contributions <- as.numeric(
    (eig$vectors^2) %*%
      spectral_deviation
  ) /
    (4 * lambda_bar^2)

  contributions[
    !is.finite(contributions) |
    contributions < 0
  ] <- 0

  names(contributions) <-
    colnames(Sigma)

  contributions
}


#' Compute adaptive penalty weights from C1F variable contributions
#'
#' For `mode = "c1f"`, the regularised covariance matrix is decomposed into
#' original-coordinate C1F contributions. Variables with larger contribution
#' receive smaller soft-threshold weights, matching the direction of the
#' historical C1F weighting rule while avoiding the invalid mapping of
#' eigenvalue indices directly to predictor indices. `inverse_c1f` reverses
#' that weighting. `uniform` returns equal weights.
#'
#' @param Sigma Regularised covariance matrix.
#' @param mode One of `"c1f"`, `"inverse_c1f"`, or `"uniform"`.
#' @param tol Numerical tolerance.
#' @return Numeric vector of variable-level penalty weights with mean one.
#' @export
compute_penalty_weights <- function(
    Sigma,
    mode = c("c1f", "inverse_c1f", "uniform"),
    tol = 1e-10
) {

  mode <- match.arg(mode)

  Sigma <- as.matrix(Sigma)

  if (
    !is.numeric(Sigma) ||
    nrow(Sigma) != ncol(Sigma)
  ) {
    stop(
      "`Sigma` must be a numeric square matrix.",
      call. = FALSE
    )
  }

  p <- ncol(Sigma)

  if (mode == "uniform") {
    return(
      rep(1, p)
    )
  }

  contribution <-
    c1f_variable_contributions(
      Sigma = Sigma,
      tol = tol
    )

  delta <-
    contribution -
    min(contribution)

  raw_weights <-
    exp(-0.5 * delta)

  if (mode == "inverse_c1f") {
    raw_weights <-
      1 /
      pmax(
        raw_weights,
        tol
      )
  }

  out <-
    expand_penalty_weights(
      raw_weights,
      p = p,
      normalise = TRUE,
      tol = tol
    )

  if (!is.null(colnames(Sigma))) {
    names(out) <- colnames(Sigma)
  }

  out
}


.risdr_safe_normalise <- function(x, tol = 1e-12) {

  nrm <- sqrt(sum(x^2))

  if (!is.finite(nrm) || nrm < tol) {
    return(x)
  }

  x / nrm
}


#' Weighted soft-threshold operator
#'
#' @param z Numeric vector.
#' @param lambda Non-negative tuning parameter.
#' @param weights Penalty weights.
#' @param tol Numerical tolerance.
#' @return Thresholded vector.
#' @export
weighted_soft_threshold <- function(
    z,
    lambda,
    weights = NULL,
    tol = 1e-10
) {

  z <- as.numeric(z)

  if (length(lambda) != 1L || is.na(lambda) || !is.finite(lambda) || lambda < 0) {
    stop("`lambda` must be a finite non-negative scalar.", call. = FALSE)
  }

  if (is.null(weights)) {
    weights <- rep(1, length(z))
  }

  weights <- expand_penalty_weights(
    weights,
    p = length(z),
    tol = tol
  )

  sign(z) * pmax(abs(z) - lambda * weights, 0)
}


#' Weighted sparse directions from dense SDR directions
#'
#' @param V Dense direction matrix.
#' @param lambda Non-negative tuning parameter.
#' @param weights Variable-level penalty weights.
#' @param tol Numerical tolerance.
#' @return Sparse direction matrix.
#' @export
weighted_sparsify_directions <- function(
    V,
    lambda,
    weights = NULL,
    tol = 1e-10
) {

  V <- as.matrix(V)

  if (!is.numeric(V)) {
    stop("`V` must be numeric.", call. = FALSE)
  }

  p <- nrow(V)
  d <- ncol(V)

  if (is.null(weights)) {
    weights <- rep(1, p)
  }

  weights <- expand_penalty_weights(
    weights,
    p = p,
    tol = tol
  )

  out <- matrix(
    0,
    nrow = p,
    ncol = d
  )

  for (j in seq_len(d)) {

    vj <- V[, j]

    vj_thr <- weighted_soft_threshold(
      vj,
      lambda = lambda,
      weights = weights,
      tol = tol
    )

    # Preserve the dense direction if thresholding collapses it completely.
    if (sum(abs(vj_thr)) < tol) {
      vj_thr <- vj
    }

    out[, j] <- .risdr_safe_normalise(
      vj_thr,
      tol = tol
    )
  }

  rownames(out) <- rownames(V)
  colnames(out) <- colnames(V)

  out
}


#' Fit sparse SDR directions over a lambda grid
#'
#' Accepts either an explicit dense direction matrix or a historical kernel
#' object containing `directions` or `vectors`.
#'
#' @param kernel_obj Optional historical kernel object.
#' @param directions Optional dense direction matrix.
#' @param d Structural dimension.
#' @param lambda_grid Numeric vector of tuning values.
#' @param penalty_weights Optional user-supplied penalty weights.
#' @param adapt_weights Logical; derive weights from `Sigma` when TRUE.
#' @param Sigma Optional covariance matrix.
#' @param weight_mode Adaptive weighting mode.
#' @param tol Numerical tolerance.
#' @return Sparse-grid object.
#' @export
fit_sparse_grid <- function(
    kernel_obj = NULL,
    directions = NULL,
    d = 2L,
    lambda_grid = seq(0, 0.5, length.out = 25L),
    penalty_weights = NULL,
    adapt_weights = FALSE,
    Sigma = NULL,
    weight_mode = c("c1f", "inverse_c1f", "uniform"),
    tol = 1e-10
) {

  weight_mode <- match.arg(weight_mode)

  lambda_grid <- as.numeric(lambda_grid)

  if (length(lambda_grid) < 1L || anyNA(lambda_grid) ||
      any(!is.finite(lambda_grid)) || any(lambda_grid < 0)) {
    stop("`lambda_grid` must contain finite non-negative values.", call. = FALSE)
  }

  if (is.null(directions)) {

    if (is.null(kernel_obj)) {
      stop("Supply `directions` or `kernel_obj`.", call. = FALSE)
    }

    if (!is.null(kernel_obj$directions)) {
      directions <- kernel_obj$directions
    } else if (!is.null(kernel_obj$vectors)) {
      directions <- kernel_obj$vectors
    } else {
      stop("`kernel_obj` contains no recognised direction matrix.", call. = FALSE)
    }
  }

  directions <- as.matrix(directions)

  d <- as.integer(d)

  if (length(d) != 1L || is.na(d) || d < 1L || d > ncol(directions)) {
    stop("Invalid structural dimension `d`.", call. = FALSE)
  }

  V_dense <- directions[, seq_len(d), drop = FALSE]
  p <- nrow(V_dense)

  if (is.null(penalty_weights)) {

    if (adapt_weights) {

      if (is.null(Sigma)) {
        warning(
          "`adapt_weights = TRUE` but `Sigma` is NULL; using uniform weights.",
          call. = FALSE
        )
        penalty_weights <- rep(1, p)
      } else {
        penalty_weights <- compute_penalty_weights(
          Sigma = Sigma,
          mode = weight_mode,
          tol = tol
        )
      }

    } else {
      penalty_weights <- rep(1, p)
    }

  } else {

    penalty_weights <- expand_penalty_weights(
      penalty_weights,
      p = p,
      tol = tol
    )
  }

  fits <- vector(
    "list",
    length(lambda_grid)
  )

  names(fits) <- paste0(
    "lambda_",
    format(lambda_grid, trim = TRUE)
  )

  for (i in seq_along(lambda_grid)) {

    fits[[i]] <- weighted_sparsify_directions(
      V = V_dense,
      lambda = lambda_grid[i],
      weights = penalty_weights,
      tol = tol
    )
  }

  list(
    fits = fits,
    lambda_grid = lambda_grid,
    penalty_weights = penalty_weights,
    dense_directions = V_dense,
    weight_mode = weight_mode,
    adapt_weights = adapt_weights
  )
}


#' Summarise sparsity pattern
#'
#' @param V Direction matrix.
#' @param tol Threshold for active support.
#' @return Sparsity summary.
#' @export
summarise_sparsity <- function(V, tol = 1e-8) {

  V <- as.matrix(V)

  active_rows <- which(
    rowSums(abs(V)) > tol
  )

  active_by_direction <- lapply(
    seq_len(ncol(V)),
    function(j) {
      which(abs(V[, j]) > tol)
    }
  )

  list(
    n_active = length(active_rows),
    active_rows = active_rows,
    active_by_direction = active_by_direction
  )
}
