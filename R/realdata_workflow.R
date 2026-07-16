# ============================================================
# Variance filtering for high-dimensional omics data
# ============================================================

#' Filter low-variance predictors
#'
#' Removes predictors with variance below a specified quantile.
#'
#' @param X Predictor matrix.
#' @param variance_quantile Quantile threshold.
#'
#' @return Filtered matrix.
#' @export

filter_low_variance <- function(
    X,
    variance_quantile = 0.25
) {

  X <- check_X(X)

  if (!is.numeric(variance_quantile) || length(variance_quantile) != 1L ||
      !is.finite(variance_quantile) || variance_quantile < 0 ||
      variance_quantile >= 1) {
    stop("`variance_quantile` must be a single value in [0, 1).", call. = FALSE)
  }

  vars <- apply(X, 2, stats::var, na.rm = TRUE)

  cutoff <- stats::quantile(
    vars,
    probs = variance_quantile,
    na.rm = TRUE
  )

  keep <- vars > cutoff

  if (sum(keep) < 2L) {
    stop(
      "Variance filtering retained fewer than two predictors.",
      call. = FALSE
    )
  }

  X_filtered <- X[, keep, drop = FALSE]

  attr(X_filtered, "kept_variables") <- colnames(X)[keep]

  X_filtered
}


# ============================================================
# Prepare survival response
# ============================================================

#' Prepare survival response
#'
#' @param time Survival time vector.
#' @param delta Event indicator vector.
#'
#' @return Cleaned survival response list.
#' @export

prepare_survival_response <- function(
    time,
    delta
) {

  if (length(time) != length(delta)) {
    stop("`time` and `delta` must have the same length.", call. = FALSE)
  }

  if (!is.numeric(time) || !is.numeric(delta)) {
    stop("`time` and `delta` must be numeric.", call. = FALSE)
  }

  keep <- stats::complete.cases(time, delta)

  out <- list(
    time = as.numeric(time[keep]),
    delta = as.numeric(delta[keep]),
    keep = keep
  )

  if (!all(out$delta %in% c(0, 1))) {
    stop("`delta` must contain only 0 and 1 after incomplete cases are removed.", call. = FALSE)
  }

  out
}

# ============================================================
# RISDR real-data workflow
# ============================================================

#' Fit RISDR to real high-dimensional data
#'
#' @param X Predictor matrix.
#' @param y Response vector.
#' @param delta Optional survival censoring indicator.
#' @param response_type Response type.
#' @param variance_quantile Variance filtering threshold.
#' @param d Optional fixed structural dimension passed to [fit_risdr()].
#' @param ... Additional arguments passed to fit_risdr().
#'
#' @return Fitted RISDR workflow object.
#' @export

fit_risdr_realdata <- function(
    X,
    y,
    delta = NULL,
    response_type = c(
      "continuous",
      "binary",
      "multiclass",
      "survival"
    ),
    variance_quantile = 0.25,
    d = NULL,
    ...
) {

  response_type <- match.arg(response_type)

  if (response_type != "continuous") {
    stop(
      "`fit_risdr_realdata()` currently supports continuous responses only. ",
      "Binary, multiclass, and survival extensions remain under development.",
      call. = FALSE
    )
  }

  # --------------------------------------------------------
  # Variance filtering
  # --------------------------------------------------------

  X_filtered <- filter_low_variance(
    X = X,
    variance_quantile = variance_quantile
  )

  kept_vars <- attr(
    X_filtered,
    "kept_variables"
  )

  # --------------------------------------------------------
  # Fit RISDR
  # --------------------------------------------------------

  fit <- fit_risdr(
    X = X_filtered,
    y = y,
    d = d,
    ...
  )

  # --------------------------------------------------------
  # Selected variables
  # --------------------------------------------------------

  active <- which(
    rowSums(abs(fit$directions[, seq_len(fit$d), drop = FALSE])) > 1e-8
  )

  selected_variables <- data.frame(
    variable = colnames(X_filtered)[active]
  )

  # --------------------------------------------------------
  # Reduced predictors
  # --------------------------------------------------------

  reduced_predictors <- fit$scores[, seq_len(fit$d), drop = FALSE]

  out <- list(
    fit = fit,
    selected_variables = selected_variables,
    reduced_predictors = reduced_predictors,
    filtered_predictors = X_filtered,
    kept_variables = kept_vars
  )

  class(out) <- "risdr_realdata"

  out
}

# ============================================================
# Print method
# ============================================================

#' Print real-data RISDR workflow
#'
#' @param x Object of class risdr_realdata.
#' @param ... Additional arguments.
#'
#' @return Invisibly returns `x`.
#' @export

print.risdr_realdata <- function(x, ...) {

  cat("\n")
  cat("RISDR Real-Data Workflow\n")
  cat("-------------------------\n")

  cat(
    "Number of selected variables:",
    nrow(x$selected_variables),
    "\n"
  )

  cat(
    "Reduced dimension:",
    ncol(x$reduced_predictors),
    "\n"
  )

  invisible(x)
}
