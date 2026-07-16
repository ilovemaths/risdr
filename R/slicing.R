# ============================================================
# R/slicing.R
# Response slicing utilities for risdr
# ============================================================

#' Create response slices
#'
#' Constructs response slices for inverse regression-based sufficient
#' dimension reduction methods.
#'
#' @param y Numeric continuous response vector.
#' @param nslices Number of slices.
#' @param type Slicing strategy. Currently supports "quantile" and "equal_width".
#'
#' @return Integer vector of slice memberships.
#' @export
make_slices <- function(
    y,
    nslices = 6,
    type = c("quantile", "equal_width")
) {

  if (missing(y) || is.null(y)) {
    stop("`y` must be supplied.", call. = FALSE)
  }

  if (!is.numeric(y)) {
    stop("`y` must be numeric.", call. = FALSE)
  }

  y <- as.numeric(y)

  if (anyNA(y)) {
    stop("`y` contains missing values.", call. = FALSE)
  }

  if (any(!is.finite(y))) {
    stop("`y` contains non-finite values.", call. = FALSE)
  }

  nslices <- check_nslices(nslices, length(y))
  type <- match.arg(type)

  if (length(unique(y)) < nslices) {
    stop("`y` has fewer unique values than `nslices`.", call. = FALSE)
  }

  if (type == "quantile") {

    probs <- seq(0, 1, length.out = nslices + 1)
    breaks <- stats::quantile(y, probs = probs, na.rm = TRUE, type = 7)
    breaks <- unique(as.numeric(breaks))

    if (length(breaks) < 3) {
      stop("Quantile slicing failed because too few unique breakpoints were produced.", call. = FALSE)
    }

    slices <- cut(
      y,
      breaks = breaks,
      include.lowest = TRUE,
      labels = FALSE
    )
  }

  if (type == "equal_width") {

    breaks <- seq(min(y), max(y), length.out = nslices + 1)

    slices <- cut(
      y,
      breaks = breaks,
      include.lowest = TRUE,
      labels = FALSE
    )
  }

  if (anyNA(slices)) {
    stop("Slicing produced missing slice labels. Check `y` and slicing parameters.", call. = FALSE)
  }

  as.integer(slices)
}


#' Summarise response slices
#'
#' Produces a summary table of slice frequencies and response ranges.
#'
#' @param y Numeric response vector.
#' @param slices Integer slice memberships.
#'
#' @return A data frame summarising slices.
#' @export
slice_summary <- function(y, slices) {

  if (!is.numeric(y)) {
    stop("`y` must be numeric.", call. = FALSE)
  }

  slices <- check_slice_labels(slices, length(y))

  slice_ids <- sort(unique(slices))

  out <- lapply(slice_ids, function(h) {

    idx <- which(slices == h)

    data.frame(
      slice = h,
      n = length(idx),
      proportion = length(idx) / length(y),
      y_min = min(y[idx]),
      y_max = max(y[idx]),
      y_mean = mean(y[idx])
    )
  })

  do.call(rbind, out)
}


#' Compute slice means
#'
#' Computes slice-specific means of predictors.
#'
#' @param X Numeric matrix.
#' @param slices Integer slice memberships.
#'
#' @return Matrix of slice means with rows corresponding to slices.
#' @export
slice_means <- function(X, slices) {

  X <- check_X(X)
  slices <- check_slice_labels(slices, nrow(X))

  slice_ids <- sort(unique(slices))

  means <- t(vapply(
    slice_ids,
    function(h) {
      colMeans(X[slices == h, , drop = FALSE])
    },
    numeric(ncol(X))
  ))

  rownames(means) <- paste0("slice_", slice_ids)
  colnames(means) <- colnames(X)

  means
}


#' Compute slice covariance matrices
#'
#' Computes slice-specific covariance matrices.
#'
#' @param X Numeric matrix.
#' @param slices Integer slice memberships.
#' @param stabilize Logical. If TRUE, stabilises each slice covariance matrix.
#' @param stabilization Stabilisation method.
#' @param eps Eigenvalue floor.
#'
#' @return A list of covariance matrices.
#' @export
slice_covariances <- function(
    X,
    slices,
    stabilize = TRUE,
    stabilization = c("eigenfloor", "ridge", "nearest_pd"),
    eps = 1e-6
) {

  X <- check_X(X)
  slices <- check_slice_labels(slices, nrow(X))

  if (!is.logical(stabilize) || length(stabilize) != 1L || is.na(stabilize)) {
    stop("`stabilize` must be TRUE or FALSE.", call. = FALSE)
  }

  stabilization <- match.arg(stabilization)

  slice_ids <- sort(unique(slices))

  covs <- lapply(slice_ids, function(h) {

    Xh <- X[slices == h, , drop = FALSE]

    if (nrow(Xh) < 2) {
      stop("At least one slice contains fewer than 2 observations.", call. = FALSE)
    }

    Sh <- stats::cov(Xh)

    if (stabilize) {
      Sh <- stabilize_cov(Sh, method = stabilization, eps = eps)
    }

    Sh
  })

  names(covs) <- paste0("slice_", slice_ids)

  covs
}


#' Compute slice proportions
#'
#' Computes empirical slice probabilities.
#'
#' @param slices Integer slice memberships.
#'
#' @return Numeric vector of slice proportions.
#' @export
slice_proportions <- function(slices) {

  slices <- check_slice_labels(slices, length(slices))
  tab <- table(slices)
  proportions <- as.numeric(tab / sum(tab))
  names(proportions) <- names(tab)

  proportions
}


#' Validate slice labels
#'
#' @param slices Slice-membership vector.
#' @param n Expected length.
#'
#' @return Positive integer slice labels.
#' @keywords internal
check_slice_labels <- function(slices, n) {

  if (n < 1L) {
    stop("At least one slice label is required.", call. = FALSE)
  }

  if (!is.numeric(slices) && !is.integer(slices)) {
    stop("`slices` must be numeric or integer labels.", call. = FALSE)
  }

  if (length(slices) != n) {
    stop("`slices` must have the expected length.", call. = FALSE)
  }

  if (anyNA(slices) || any(!is.finite(slices)) ||
      any(slices != as.integer(slices)) || any(slices < 1L)) {
    stop("`slices` must contain finite positive integer labels.", call. = FALSE)
  }

  as.integer(slices)
}
