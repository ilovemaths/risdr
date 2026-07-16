# ============================================================
# R/fit_risdr.R
# Main model-fitting interface for risdr
# ============================================================


#' Fit regularised and information-theoretic SDR model
#'
#' Fits sufficient dimension reduction models with optional covariance
#' regularisation and information-theoretic structural dimension selection.
#'
#' @param X Numeric predictor matrix or data frame.
#' @param y Numeric continuous response vector.
#' @param sdr_method SDR method: "dr", "sir", "save", or "phd".
#' @param cov_method Covariance estimator: "sample", "ridge", "oas", "lw", or "mec".
#' @param stabilize Logical. If TRUE, stabilises the estimated covariance matrix.
#' @param stabilization Stabilisation method.
#' @param nslices Number of slices for inverse regression methods.
#' @param d Optional structural dimension. If NULL, selected by criterion.
#' @param d_max Maximum candidate structural dimension.
#' @param selector Criterion for selecting d.
#' @param standardize Logical. If TRUE, column-standardises X before covariance estimation.
#' @param complexity Complexity measure for ICOMP: "C1" or "C1F".
#' @param cov_args Named list of arguments for the selected covariance estimator.
#' @param stabilization_args Named list of arguments for covariance stabilisation.
#' @param sdr_args Named list of arguments for the selected SDR kernel.
#' @param ... Backward-compatible component arguments. New code should use the
#'   three explicit argument lists.
#'
#' @return An object of class "risdr".
#' @export
fit_risdr <- function(
    X,
    y,
    sdr_method = c("dr", "sir", "save", "phd"),
    cov_method = c("sample", "ridge", "oas", "lw", "mec"),
    stabilize = TRUE,
    stabilization = c("eigenfloor", "ridge", "nearest_pd"),
    nslices = 6,
    d = NULL,
    d_max = 10,
    selector = c("cicomp", "icomp", "bic", "caic", "aic"),
    standardize = TRUE,
    complexity = c("C1", "C1F"),
    cov_args = list(),
    stabilization_args = list(),
    sdr_args = list(),
    ...
) {

  X <- check_X(X)
  y <- check_y_continuous(y, nrow(X))
  check_missing(X, y)

  sdr_method <- check_sdr_method(sdr_method)
  cov_method <- match.arg(cov_method)
  stabilization <- check_stabilization_method(stabilization)
  selector <- check_selector(selector)
  complexity <- match.arg(complexity)
  nslices <- check_nslices(nslices, nrow(X))
  stabilize <- check_flag(stabilize, "stabilize")
  standardize <- check_flag(standardize, "standardize")

  dims <- check_dimensions(
    d = d,
    d_max = d_max,
    p = ncol(X),
    n = nrow(X)
  )
  d <- dims$d
  d_max <- dims$d_max

  component_args <- route_risdr_args(
    dots = list(...),
    cov_method = cov_method,
    stabilization = stabilization,
    sdr_method = sdr_method,
    cov_args = cov_args,
    stabilization_args = stabilization_args,
    sdr_args = sdr_args
  )

  original_colnames <- colnames(X)

  if (is.null(original_colnames)) {
    original_colnames <- paste0("X", seq_len(ncol(X)))
    colnames(X) <- original_colnames
  }

  if (anyNA(original_colnames) || any(!nzchar(original_colnames)) ||
      anyDuplicated(original_colnames)) {
    stop("Predictor column names must be non-missing and unique.", call. = FALSE)
  }

  if (standardize) {
    std <- standardize_X(X)
    X_work <- std$X
    center <- std$center
    scale <- std$scale
  } else {
    X_work <- X
    center <- rep(0, ncol(X))
    scale <- rep(1, ncol(X))
  }

  colnames(X_work) <- original_colnames

  Sigma <- do.call(
    estimate_cov,
    c(
      list(
        X = X_work,
        y = y,
        method = cov_method,
        nslices = nslices
      ),
      component_args$cov_args
    )
  )

  Sigma_raw <- Sigma

  if (stabilize) {
    Sigma <- do.call(
      stabilize_cov,
      c(
        list(
          Sigma = Sigma,
          method = stabilization
        ),
        component_args$stabilization_args
      )
    )
  }

  sdr_fit <- do.call(
    compute_sdr,
    c(
      list(
        X = X_work,
        y = y,
        method = sdr_method,
        Sigma = Sigma,
        nslices = nslices
      ),
      component_args$sdr_args
    )
  )

  d_table <- select_dimension(
    scores = sdr_fit$scores,
    y = y,
    d_max = d_max,
    complexity = complexity
  )

  if (is.null(d)) {
    d <- choose_dimension(d_table, selector = selector)
  }

  downstream_fit <- fit_downstream_lm(
    scores = sdr_fit$scores,
    y = y,
    d = d
  )

  loadings <- extract_loadings(
    directions = sdr_fit$directions,
    variables = original_colnames
  )

  out <- list(
    call = match.call(),
    X = X,
    y = y,
    X_work = X_work,
    center = center,
    scale = scale,
    standardize = standardize,
    sdr_method = sdr_method,
    cov_method = cov_method,
    stabilize = stabilize,
    stabilization = stabilization,
    Sigma_raw = Sigma_raw,
    Sigma = Sigma,
    kernel = sdr_fit$kernel,
    eigenvalues = sdr_fit$eigenvalues,
    directions = sdr_fit$directions,
    z_directions = sdr_fit$z_directions,
    scores = sdr_fit$scores,
    slices = sdr_fit$slices,
    nslices = nslices,
    d = d,
    d_max = d_max,
    d_table = d_table,
    selector = selector,
    complexity = complexity,
    cov_args = component_args$cov_args,
    stabilization_args = component_args$stabilization_args,
    sdr_args = component_args$sdr_args,
    downstream_fit = downstream_fit,
    sdr_center = sdr_fit$sdr_center,
    loadings = loadings
  )

  class(out) <- "risdr"

  out
}


#' Extract SDR loadings
#'
#' @param directions Matrix of SDR directions.
#' @param variables Variable names.
#'
#' @return A data frame of loadings.
#' @export
extract_loadings <- function(directions, variables = NULL) {

  directions <- as.matrix(directions)

  if (is.null(variables)) {
    variables <- paste0("X", seq_len(nrow(directions)))
  }

  if (length(variables) != nrow(directions)) {
    stop("Length of `variables` must equal number of rows in `directions`.", call. = FALSE)
  }

  out <- data.frame(
    Variable = variables,
    directions,
    check.names = FALSE
  )

  names(out)[-1] <- paste0("Direction_", seq_len(ncol(directions)))

  out
}


#' Print risdr object
#'
#' @param x Object of class "risdr".
#' @param ... Additional arguments passed to internal methods.
#'
#' @return Invisibly returns x.
#' @export
print.risdr <- function(x, ...) {

  cat("Regularised and Information-Theoretic SDR fit\n")
  cat("--------------------------------------------------\n")
  cat("SDR method       :", toupper(x$sdr_method), "\n")
  cat("Covariance       :", toupper(x$cov_method), "\n")
  cat("Stabilised       :", x$stabilize, "\n")
  cat("Stabilisation    :", x$stabilization, "\n")
  cat("Selected d       :", x$d, "\n")
  cat("Selector         :", toupper(x$selector), "\n")
  cat("Number of slices :", x$nslices, "\n")
  cat("Observations     :", nrow(x$X), "\n")
  cat("Predictors       :", ncol(x$X), "\n")

  invisible(x)
}


#' Summarise risdr object
#'
#' @param object Object of class "risdr".
#'
#' @return A list summary.
#' @param ... Additional arguments passed to internal methods.
#' @export
summary.risdr <- function(object, ...) {

  out <- list(
    method = object$sdr_method,
    covariance = object$cov_method,
    selected_dimension = object$d,
    selector = object$selector,
    eigenvalues = head(object$eigenvalues, 10),
    dimension_table = object$d_table,
    covariance_diagnostics = cov_diagnostics(object$Sigma)
  )

  class(out) <- "summary.risdr"

  out
}


#' Print summary of risdr object
#'
#' @param x Object of class "summary.risdr".
#' @param ... Additional arguments passed to internal methods.
#'
#' @return Invisibly returns x.
#' @export
print.summary.risdr <- function(x, ...) {

  cat("Summary of risdr fit\n")
  cat("--------------------------------------------------\n")
  cat("Method              :", toupper(x$method), "\n")
  cat("Covariance          :", toupper(x$covariance), "\n")
  cat("Selected dimension  :", x$selected_dimension, "\n")
  cat("Selector            :", toupper(x$selector), "\n\n")

  cat("Leading eigenvalues:\n")
  print(x$eigenvalues)

  cat("\nDimension selection table:\n")
  print(x$dimension_table)

  cat("\nCovariance diagnostics:\n")
  print(x$covariance_diagnostics[1:4])

  invisible(x)
}


#' Predict method for risdr objects
#'
#' @param object Object of class "risdr".
#' @param newX New predictor matrix or data frame.
#' @param d Optional structural dimension.
#' @param ... Additional arguments passed to internal methods.
#'
#' @return Numeric vector of predictions.
#' @export
predict.risdr <- function(object, newX, d = NULL, ...) {

  if (!inherits(object, "risdr")) {
    stop("`object` must be of class 'risdr'.", call. = FALSE)
  }

  supplied_names <- colnames(newX)
  newX <- check_new_X(newX, min_cols = 2L)

  if (ncol(newX) != ncol(object$X)) {
    stop("`newX` must have the same number of columns as the training X.", call. = FALSE)
  }

  training_names <- colnames(object$X)

  if (!is.null(supplied_names)) {
    if (!setequal(supplied_names, training_names)) {
      stop(
        "Named columns in `newX` must match the training predictors.",
        call. = FALSE
      )
    }

    newX <- newX[, training_names, drop = FALSE]
  }

  colnames(newX) <- training_names

  if (object$standardize) {
    newX_work <- scale(
      newX,
      center = object$center,
      scale = object$scale
    )
    newX_work <- as.matrix(newX_work)
  } else {
    newX_work <- as.matrix(newX)
  }

  newX_sdr_centered <- sweep(
    newX_work,
    2,
    object$sdr_center,
    "-"
  )

  scores_new <- compute_scores(
    newX = newX_sdr_centered,
    directions = object$directions
  )

  if (is.null(d)) {
    d <- object$d
  }

  if (!is.numeric(d) || length(d) != 1L || !is.finite(d) ||
      d != as.integer(d) || d < 1L || d > object$d_max) {
    stop(
      "`d` must be a positive integer not exceeding the fitted `d_max`.",
      call. = FALSE
    )
  }

  d <- as.integer(d)

  downstream_fit <- object$downstream_fit

  if (d != object$d) {
    downstream_fit <- fit_downstream_lm(
      scores = object$scores,
      y = object$y,
      d = d
    )
  }

  predict_downstream_lm(
    fit_lm = downstream_fit,
    scores_new = scores_new,
    d = d
  )
}
