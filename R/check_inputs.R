# ============================================================
# R/check_inputs.R
# Input validation utilities for risdr
# ============================================================

#' Check predictor matrix
#'
#' Internal function for validating predictor input.
#'
#' @param X A numeric matrix or data frame of predictors.
#' @param min_rows Minimum permitted number of rows.
#' @param min_cols Minimum permitted number of columns.
#'
#' @return A numeric matrix.
#' @keywords internal
check_X <- function(X, min_rows = 5L, min_cols = 2L) {

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

  if (anyNA(X)) {
    stop("`X` contains missing values. Please remove or impute them before fitting.", call. = FALSE)
  }

  if (nrow(X) < min_rows) {
    stop(
      "`X` must contain at least ", min_rows, " observation",
      if (min_rows == 1L) "." else "s.",
      call. = FALSE
    )
  }

  if (ncol(X) < min_cols) {
    stop(
      "`X` must contain at least ", min_cols, " predictor variable",
      if (min_cols == 1L) "." else "s.",
      call. = FALSE
    )
  }

  if (any(!is.finite(X))) {
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
    stop("`y` must be numeric because the current modelling interface supports continuous responses.", call. = FALSE)
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
    choices = c("sample", "ridge", "oas", "lw", "mec")
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
#' @param n Optional sample size. When supplied, dimensions are also restricted
#'   to leave positive residual degrees of freedom in the downstream model.
#'
#' @return A list containing checked d and d_max.
#' @keywords internal
check_dimensions <- function(d = NULL, d_max = 10, p, n = NULL) {

  max_allowed <- p - 1L

  if (!is.null(n)) {
    if (!is.numeric(n) || length(n) != 1L || !is.finite(n) ||
        n != as.integer(n) || n < 3L) {
      stop("`n` must be a single integer at least 3.", call. = FALSE)
    }

    max_allowed <- min(max_allowed, as.integer(n) - 2L)
  }

  if (!is.null(d)) {
    if (!is.numeric(d) || length(d) != 1 || !is.finite(d) ||
        d != as.integer(d) || d < 1 || d > max_allowed) {
      stop(
        "`d` must be a single positive integer no larger than ",
        max_allowed,
        " for the available predictors and observations.",
        call. = FALSE
      )
    }
    d <- as.integer(d)
  }

  if (!is.numeric(d_max) || length(d_max) != 1 || !is.finite(d_max) ||
      d_max != as.integer(d_max) || d_max < 1) {
    stop("`d_max` must be a single positive integer.", call. = FALSE)
  }

  d_max <- as.integer(d_max)

  if (d_max > max_allowed) {
    d_max <- max_allowed
    warning(
      "`d_max` was reduced to ", max_allowed,
      " to respect predictor and residual-degrees-of-freedom limits.",
      call. = FALSE
    )
  }

  if (!is.null(d) && d_max < d) {
    d_max <- d
    warning(
      "`d_max` was increased to match the supplied fixed dimension `d`.",
      call. = FALSE
    )
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

  if (!is.numeric(nslices) || length(nslices) != 1 || !is.finite(nslices) ||
      nslices != as.integer(nslices)) {
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

  X <- check_X(X)

  if (is.null(center)) {
    center <- colMeans(X)
  }

  if (is.null(scale)) {
    scale <- apply(X, 2, stats::sd)
  }

  if (!is.numeric(center) || length(center) != ncol(X) ||
      anyNA(center) || any(!is.finite(center))) {
    stop("`center` must be a finite numeric vector with one value per predictor.", call. = FALSE)
  }

  if (!is.numeric(scale) || length(scale) != ncol(X) ||
      anyNA(scale) || any(!is.finite(scale))) {
    stop("`scale` must be a finite numeric vector with one value per predictor.", call. = FALSE)
  }

  zero_scale <- which(scale <= .Machine$double.eps)

  if (length(zero_scale) > 0) {
    stop(
      "Some predictors have zero or near-zero standard deviation: ",
      paste(colnames(X)[zero_scale], collapse = ", "),
      call. = FALSE
    )
  }

  X_std <- base::scale(X, center = center, scale = scale)

  list(
    X = as.matrix(X_std),
    center = center,
    scale = scale
  )
}


#' Check new predictor observations
#'
#' Validates predictor input used only for projection or prediction. Unlike
#' [check_X()], this helper permits a single observation.
#'
#' @param X A numeric matrix or data frame.
#' @param min_cols Minimum permitted number of columns.
#'
#' @return A numeric matrix.
#' @keywords internal
check_new_X <- function(X, min_cols = 1L) {
  check_X(X, min_rows = 1L, min_cols = min_cols)
}


#' Validate a named argument list
#'
#' @param x Object to validate.
#' @param name Argument name used in error messages.
#'
#' @return The validated list.
#' @keywords internal
check_named_list <- function(x, name) {

  if (!is.list(x)) {
    stop("`", name, "` must be a list.", call. = FALSE)
  }

  if (length(x) == 0L) {
    return(x)
  }

  nms <- names(x)

  if (is.null(nms) || any(!nzchar(nms))) {
    stop("Every element of `", name, "` must be named.", call. = FALSE)
  }

  if (anyDuplicated(nms)) {
    stop("`", name, "` must not contain duplicated names.", call. = FALSE)
  }

  x
}


#' Validate a logical flag
#'
#' @param x Object to validate.
#' @param name Argument name used in error messages.
#'
#' @return The validated logical value.
#' @keywords internal
check_flag <- function(x, name) {

  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop("`", name, "` must be TRUE or FALSE.", call. = FALSE)
  }

  x
}


#' Route component-specific arguments
#'
#' Separates legacy arguments supplied through `...` from explicit covariance,
#' stabilisation, and SDR argument lists. Explicit component lists take
#' precedence over matching legacy arguments.
#'
#' @param dots Named list created from `...`.
#' @param cov_method Covariance estimator.
#' @param stabilization Covariance stabilisation method.
#' @param sdr_method SDR method.
#' @param cov_args Explicit covariance-estimator arguments.
#' @param stabilization_args Explicit stabilisation arguments.
#' @param sdr_args Explicit SDR-kernel arguments.
#'
#' @return A list with `cov_args`, `stabilization_args`, and `sdr_args`.
#' @keywords internal
route_risdr_args <- function(
    dots,
    cov_method,
    stabilization,
    sdr_method,
    cov_args = list(),
    stabilization_args = list(),
    sdr_args = list()
) {

  dots <- check_named_list(dots, "...")
  cov_args <- check_named_list(cov_args, "cov_args")
  stabilization_args <- check_named_list(
    stabilization_args,
    "stabilization_args"
  )
  sdr_args <- check_named_list(sdr_args, "sdr_args")

  cov_allowed <- switch(
    cov_method,
    sample = character(),
    ridge = "lambda",
    oas = character(),
    lw = character(),
    mec = c("response_type", "delta", "alpha", "eps")
  )

  stabilization_allowed <- switch(
    stabilization,
    eigenfloor = "eps",
    ridge = "lambda",
    nearest_pd = "keep_diag"
  )

  sdr_allowed <- switch(
    sdr_method,
    sir = c("slice_type", "eps"),
    save = c("slice_type", "stabilize_slices", "stabilization", "eps"),
    dr = c("slice_type", "stabilize_slices", "stabilization", "eps"),
    phd = "eps"
  )

  validate_component <- function(x, allowed, name) {
    unsupported <- setdiff(names(x), allowed)

    if (length(unsupported) > 0L) {
      stop(
        "Unsupported argument", if (length(unsupported) > 1L) "s" else "",
        " in `", name, "`: ", paste(unsupported, collapse = ", "), ".",
        call. = FALSE
      )
    }

    x
  }

  cov_args <- validate_component(cov_args, cov_allowed, "cov_args")
  stabilization_args <- validate_component(
    stabilization_args,
    stabilization_allowed,
    "stabilization_args"
  )
  sdr_args <- validate_component(sdr_args, sdr_allowed, "sdr_args")

  recognised <- unique(c(cov_allowed, stabilization_allowed, sdr_allowed))
  unsupported_dots <- setdiff(names(dots), recognised)

  if (length(unsupported_dots) > 0L) {
    stop(
      "Unused argument", if (length(unsupported_dots) > 1L) "s" else "",
      " in `...`: ", paste(unsupported_dots, collapse = ", "), ". ",
      "Use `cov_args`, `stabilization_args`, or `sdr_args` for component-specific controls.",
      call. = FALSE
    )
  }

  legacy_cov <- dots[intersect(names(dots), cov_allowed)]
  legacy_stabilization <- dots[
    intersect(names(dots), stabilization_allowed)
  ]
  legacy_sdr <- dots[intersect(names(dots), sdr_allowed)]

  list(
    cov_args = utils::modifyList(legacy_cov, cov_args),
    stabilization_args = utils::modifyList(
      legacy_stabilization,
      stabilization_args
    ),
    sdr_args = utils::modifyList(legacy_sdr, sdr_args)
  )
}
