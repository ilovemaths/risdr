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

  vars <- apply(X, 2, stats::var, na.rm = TRUE)

  cutoff <- stats::quantile(
    vars,
    probs = variance_quantile,
    na.rm = TRUE
  )

  keep <- vars > cutoff

  X_filtered <- X[, keep, drop = FALSE]

  attr(X_filtered, "kept_variables") <- colnames(X)[keep]

  return(X_filtered)
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

  keep <- stats::complete.cases(time, delta)

  out <- list(
    time = as.numeric(time[keep]),
    delta = as.numeric(delta[keep]),
    keep = keep
  )

  return(out)
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
#' @param ... Additional arguments passed to fit_risdr().
#'
#' @return Fitted RISDR workflow object.

#' Fit RISDR to a real-data predictor matrix
#'
#' Applies outcome cleaning, low-variance screening, the unified RISDR core,
#' and descriptive loading-based variable ranking. The wrapper returns the
#' reduced predictors computed by the core itself so that centring and
#' standardisation are not silently bypassed.
#'
#' @param X Numeric predictor matrix or data frame.
#' @param y Response vector. For survival data, observed time.
#' @param delta Optional 0/1 event indicator for survival data.
#' @param response_type One of `"continuous"`, `"binary"`,
#'   `"multiclass"`, `"categorical"`, or `"survival"`.
#' @param variance_quantile Quantile of predictor variances used for the
#'   low-variance screen.
#' @param ... Arguments passed to [fit_risdr()].
#' @return An object of class `risdr_realdata`.
#' @export
fit_risdr_realdata <- function(
    X,
    y,
    delta = NULL,
    response_type = c(
      "continuous",
      "binary",
      "multiclass",
      "categorical",
      "survival"
    ),
    variance_quantile = 0.25,
    ...
) {

  response_type <- match.arg(response_type)

  X <- as.matrix(X)

  if (!is.numeric(X)) {
    stop("`X` must be numeric.", call. = FALSE)
  }

  if (length(y) != nrow(X)) {
    stop("Length of `y` must equal nrow(`X`).", call. = FALSE)
  }

  if (is.null(colnames(X))) {
    colnames(X) <- paste0("X", seq_len(ncol(X)))
  }

  if (
    anyNA(colnames(X)) ||
    any(!nzchar(colnames(X))) ||
    anyDuplicated(colnames(X))
  ) {
    stop(
      "Predictor names must be non-missing, non-empty, and unique.",
      call. = FALSE
    )
  }

  if (
    !is.numeric(variance_quantile) ||
    length(variance_quantile) != 1L ||
    is.na(variance_quantile) ||
    variance_quantile < 0 ||
    variance_quantile >= 1
  ) {
    stop(
      "`variance_quantile` must be a scalar in [0, 1).",
      call. = FALSE
    )
  }

  if (response_type == "survival") {

    surv_obj <- prepare_survival_response(
      time = y,
      delta = delta
    )

    keep_rows <- surv_obj$keep

    X_clean <- X[
      keep_rows,
      ,
      drop = FALSE
    ]

    y_clean <- surv_obj$time
    delta_clean <- surv_obj$delta
    core_response_type <- "survival"

  } else {

    keep_rows <- stats::complete.cases(y)

    X_clean <- X[
      keep_rows,
      ,
      drop = FALSE
    ]

    y_clean <- y[keep_rows]
    delta_clean <- NULL

    core_response_type <- if (
      response_type %in% c(
        "binary",
        "multiclass",
        "categorical"
      )
    ) {
      "categorical"
    } else {
      "continuous"
    }
  }

  if (nrow(X_clean) < 3L) {
    stop("Too few complete outcome records remain.", call. = FALSE)
  }

  X_filtered <- filter_low_variance(
    X = X_clean,
    variance_quantile = variance_quantile
  )

  kept_vars <- attr(
    X_filtered,
    "kept_variables"
  )

  if (is.null(kept_vars)) {
    kept_vars <- colnames(X_filtered)
  }

  kept_vars <- as.character(kept_vars)

  if (
    length(kept_vars) != ncol(X_filtered) ||
    !identical(
      kept_vars,
      colnames(X_filtered)
    )
  ) {
    stop(
      "Low-variance screening did not preserve an auditable variable-name mapping.",
      call. = FALSE
    )
  }

  fit <- fit_risdr(
    X = X_filtered,
    y = y_clean,
    delta = delta_clean,
    response_type = core_response_type,
    ...
  )

  B <- as.matrix(
    fit$directions
  )

  if (
    nrow(B) != ncol(X_filtered) ||
    ncol(B) != fit$d
  ) {
    stop(
      "Core direction matrix does not align with the filtered predictors.",
      call. = FALSE
    )
  }

  rownames(B) <- colnames(X_filtered)

  loading_norm <- sqrt(
    rowSums(
      B^2
    )
  )

  active <- which(
    loading_norm > 1e-8
  )

  selected_variables <- data.frame(
    index = active,
    variable = colnames(X_filtered)[active],
    loading_norm = loading_norm[active],
    stringsAsFactors = FALSE
  )

  selected_variables <- selected_variables[
    order(
      selected_variables$loading_norm,
      decreasing = TRUE
    ),
    ,
    drop = FALSE
  ]

  reduced_predictors <- as.matrix(
    fit$reduced_predictors
  )

  if (
    nrow(reduced_predictors) != nrow(X_filtered) ||
    ncol(reduced_predictors) != fit$d
  ) {
    stop(
      "Core reduced predictors have unexpected dimensions.",
      call. = FALSE
    )
  }

  out <- list(
    call = match.call(),
    fit = fit,
    response_type = response_type,
    core_response_type = core_response_type,
    selected_variables = selected_variables,
    reduced_predictors = reduced_predictors,
    filtered_predictors = X_filtered,
    kept_variables = kept_vars,
    kept_rows = keep_rows,
    y = y_clean,
    delta = delta_clean,
    variance_quantile = variance_quantile
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
