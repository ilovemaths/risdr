# ============================================================
# R/check_inputs.R
# Input validation utilities for risdr
# ============================================================

#' Check predictor matrix
#'
#' Internal function for validating predictor input.
#'
#' @param X A numeric matrix or data frame of predictors.
#'
#' @return A numeric matrix.
#' @keywords internal
check_X <- function(X) {

  if (missing(X) || is.null(X)) {
    stop("`X` must be supplied.", call. = FALSE)
  }

  if (!is.matrix(X) && !is.data.frame(X)) {
    stop("`X` must be a matrix or data frame.", call. = FALSE)
  }

  X <- as.data.frame(X)

  non_numeric <- names(X)[!vapply(X, is.numeric, logical(1))]

  if (length(non_numeric) > 0) {
    stop(
      "`X` must contain only numeric variables. Non-numeric variables found: ",
      paste(non_numeric, collapse = ", "),
      call. = FALSE
    )
  }

  X <- as.matrix(X)

  if (nrow(X) < 5) {
    stop("`X` must contain at least 5 observations.", call. = FALSE)
  }

  if (ncol(X) < 2) {
    stop("`X` must contain at least 2 predictor variables.", call. = FALSE)
  }

  if (any(!is.finite(X), na.rm = TRUE)) {
    stop("`X` contains non-finite values. Please remove or impute them before fitting.", call. = FALSE)
  }

  X
}


#' Check continuous response vector
#'
#' Internal function for validating continuous response input.
#'
#' @param y Numeric response vector.
#' @param n Expected sample size.
#'
#' @return Numeric response vector.
#' @keywords internal
check_y_continuous <- function(y, n) {

  if (missing(y) || is.null(y)) {
    stop("`y` must be supplied.", call. = FALSE)
  }

  if (!is.numeric(y)) {
    stop("For Phase 1, `y` must be numeric because only continuous responses are supported.", call. = FALSE)
  }

  y <- as.numeric(y)

  if (length(y) != n) {
    stop(
      "`y` must have length equal to the number of rows in `X`. ",
      "Expected ", n, " but got ", length(y), ".",
      call. = FALSE
    )
  }

  if (any(!is.finite(y), na.rm = TRUE)) {
    stop("`y` contains non-finite values. Please remove or impute them before fitting.", call. = FALSE)
  }

  y
}


#' Check missing values
#'
#' Internal function for detecting missing values.
#'
#' @param X Predictor matrix.
#' @param y Response vector.
#'
#' @return Invisibly returns TRUE if no missing values are found.
#' @keywords internal
check_missing <- function(X, y) {

  if (anyNA(X)) {
    stop("`X` contains missing values. Please impute missing values before using `fit_risdr()`.", call. = FALSE)
  }

  if (anyNA(y)) {
    stop("`y` contains missing values. Please impute or remove missing response values before using `fit_risdr()`.", call. = FALSE)
  }

  invisible(TRUE)
}


#' Check SDR method
#'
#' @param method Character string.
#'
#' @return Matched SDR method.
#' @keywords internal
check_sdr_method <- function(method) {

  match.arg(
    method,
    choices = c("dr", "sir", "save", "phd")
  )
}


#' Check covariance method
#'
#' @param method Character string.
#'
#' @return Matched covariance method.
#' @keywords internal
check_cov_method <- function(method) {

  match.arg(
    method,
    choices = c("sample", "oas", "mec")
  )
}


#' Check stabilisation method
#'
#' @param method Character string.
#'
#' @return Matched stabilisation method.
#' @keywords internal
check_stabilization_method <- function(method) {

  match.arg(
    method,
    choices = c("eigenfloor", "ridge", "nearest_pd")
  )
}


#' Check dimension arguments
#'
#' @param d Structural dimension.
#' @param d_max Maximum candidate structural dimension.
#' @param p Number of predictors.
#'
#' @return A list containing checked d and d_max.
#' @keywords internal
check_dimensions <- function(d = NULL, d_max = 10, p) {

  if (!is.null(d)) {
    if (!is.numeric(d) || length(d) != 1 || d < 1 || d >= p) {
      stop("`d` must be a single positive integer less than the number of predictors.", call. = FALSE)
    }
    d <- as.integer(d)
  }

  if (!is.numeric(d_max) || length(d_max) != 1 || d_max < 1) {
    stop("`d_max` must be a single positive integer.", call. = FALSE)
  }

  d_max <- as.integer(d_max)

  if (d_max >= p) {
    d_max <- p - 1
    warning("`d_max` was reduced to p - 1 because it must be smaller than the number of predictors.", call. = FALSE)
  }

  list(d = d, d_max = d_max)
}


#' Check number of slices
#'
#' @param nslices Number of response slices.
#' @param n Sample size.
#'
#' @return Integer number of slices.
#' @keywords internal
check_nslices <- function(nslices, n) {

  if (!is.numeric(nslices) || length(nslices) != 1) {
    stop("`nslices` must be a single positive integer.", call. = FALSE)
  }

  nslices <- as.integer(nslices)

  if (nslices < 2) {
    stop("`nslices` must be at least 2.", call. = FALSE)
  }

  if (nslices > floor(n / 5)) {
    warning(
      "`nslices` is large relative to the sample size. ",
      "Some slices may contain too few observations.",
      call. = FALSE
    )
  }

  nslices
}


#' Check selector
#'
#' @param selector Model selection criterion.
#'
#' @return Matched selector.
#' @keywords internal
check_selector <- function(selector) {

  match.arg(
    selector,
    choices = c("cicomp", "icomp", "bic", "caic", "aic")
  )
}


#' Standardise predictors
#'
#' @param X Numeric predictor matrix.
#' @param center Optional centring vector.
#' @param scale Optional scaling vector.
#'
#' @return A list containing standardised matrix, centre, and scale.
#' @keywords internal
standardize_X <- function(X, center = NULL, scale = NULL) {

  if (is.null(center)) {
    center <- colMeans(X)
  }

  if (is.null(scale)) {
    scale <- apply(X, 2, stats::sd)
  }

  zero_scale <- which(scale <= .Machine$double.eps)

  if (length(zero_scale) > 0) {
    stop(
      "Some predictors have zero or near-zero standard deviation: ",
      paste(colnames(X)[zero_scale], collapse = ", "),
      call. = FALSE
    )
  }

  X_std <- scale(X, center = center, scale = scale)

  list(
    X = as.matrix(X_std),
    center = center,
    scale = scale
  )
}
