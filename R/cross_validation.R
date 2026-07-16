# ============================================================
# R/cross_validation.R
# Cross-validation utilities for risdr
# ============================================================


#' Create cross-validation folds
#'
#' @param n Sample size.
#' @param v Number of folds.
#' @param seed Optional random seed.
#'
#' @return Integer vector of fold memberships.
#' @export
make_cv_folds <- function(n, v = 5, seed = NULL) {

  design <- check_cv_design(n = n, v = v, minimum_required = 0L)
  n <- design$n
  v <- design$v

  if (!is.null(seed)) {
    set.seed(seed)
  }

  sample(rep(seq_len(v), length.out = n))
}

#' Validate a cross-validation design
#'
#' @param n Sample size.
#' @param v Number of folds.
#' @param minimum_required Minimum required training-set size.
#'
#' @return Checked fold count and minimum training-set size.
#' @keywords internal
check_cv_design <- function(n, v, minimum_required = 5L) {

  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) ||
      n != as.integer(n) || n < 2L) {
    stop("`n` must be a single integer greater than 1.", call. = FALSE)
  }

  if (!is.numeric(v) || length(v) != 1L || !is.finite(v) ||
      v != as.integer(v) || v < 2L || v > n) {
    stop("`v` must be a single integer between 2 and n.", call. = FALSE)
  }

  n <- as.integer(n)
  v <- as.integer(v)
  minimum_training_size <- n - ceiling(n / v)

  if (!is.numeric(minimum_required) || length(minimum_required) != 1L ||
      !is.finite(minimum_required) ||
      minimum_required != as.integer(minimum_required) ||
      minimum_required < 0L) {
    stop("`minimum_required` must be a non-negative integer.", call. = FALSE)
  }

  minimum_required <- as.integer(minimum_required)

  if (minimum_training_size < minimum_required) {
    stop(
      "The cross-validation design leaves fewer than ", minimum_required,
      " training observations per fold.",
      call. = FALSE
    )
  }

  list(n = n, v = v, minimum_training_size = minimum_training_size)
}


#' Cross-validation dimension selection for SDR
#'
#' Selects structural dimension by V-fold cross-validation. For each candidate
#' dimension, SDR is fitted on the training folds, a downstream linear regression
#' is fitted using the reduced predictors, and prediction error is evaluated on
#' the validation fold.
#'
#' @param X Numeric predictor matrix or data frame.
#' @param y Numeric continuous response vector.
#' @param sdr_method SDR method.
#' @param cov_method Covariance estimator.
#' @param d_max Maximum candidate structural dimension.
#' @param v Number of folds.
#' @param nslices Number of slices.
#' @param standardize Logical. If TRUE, standardises predictors inside each training fold.
#' @param stabilize Logical. If TRUE, stabilises covariance matrix.
#' @param stabilization Stabilisation method.
#' @param metric Prediction metric used for selection.
#' @param seed Optional random seed.
#' @param cov_args Named list of arguments for the covariance estimator.
#' @param stabilization_args Named list of arguments for covariance stabilisation.
#' @param sdr_args Named list of arguments for the SDR kernel.
#' @param ... Backward-compatible component arguments.
#'
#' @return A list containing the CV table, selected dimension, and fold-level results.
#' @export
select_dimension_cv <- function(
    X,
    y,
    sdr_method = c("dr", "sir", "save", "phd"),
    cov_method = c("sample", "ridge", "oas", "lw", "mec"),
    d_max = 10,
    v = 5,
    nslices = 6,
    standardize = TRUE,
    stabilize = TRUE,
    stabilization = c("eigenfloor", "ridge", "nearest_pd"),
    metric = c("RMSE", "MAE"),
    seed = NULL,
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
  metric <- match.arg(metric)
  cv_design <- check_cv_design(nrow(X), v)
  v <- cv_design$v
  nslices <- check_nslices(nslices, cv_design$minimum_training_size)
  standardize <- check_flag(standardize, "standardize")
  stabilize <- check_flag(stabilize, "stabilize")

  dims <- check_dimensions(
    d = NULL,
    d_max = d_max,
    p = ncol(X),
    n = cv_design$minimum_training_size
  )
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

  folds <- make_cv_folds(n = nrow(X), v = v, seed = seed)

  fold_results <- list()
  counter <- 1L

  for (fold in seq_len(v)) {

    train_idx <- which(folds != fold)
    valid_idx <- which(folds == fold)

    X_train <- X[train_idx, , drop = FALSE]
    y_train <- y[train_idx]

    X_valid <- X[valid_idx, , drop = FALSE]
    y_valid <- y[valid_idx]

    if (standardize) {
      std <- standardize_X(X_train)
      X_train_work <- std$X
      X_valid_work <- scale(
        X_valid,
        center = std$center,
        scale = std$scale
      )
      X_valid_work <- as.matrix(X_valid_work)
    } else {
      X_train_work <- as.matrix(X_train)
      X_valid_work <- as.matrix(X_valid)
    }

    Sigma <- do.call(
      estimate_cov,
      c(
        list(
          X = X_train_work,
          y = y_train,
          method = cov_method,
          nslices = nslices
        ),
        component_args$cov_args
      )
    )

    if (stabilize) {
      Sigma <- do.call(
        stabilize_cov,
        c(
          list(Sigma = Sigma, method = stabilization),
          component_args$stabilization_args
        )
      )
    }

    sdr_fit <- do.call(
      compute_sdr,
      c(
        list(
          X = X_train_work,
          y = y_train,
          method = sdr_method,
          Sigma = Sigma,
          nslices = nslices
        ),
        component_args$sdr_args
      )
    )

    X_valid_centered <- sweep(
      X_valid_work,
      2,
      sdr_fit$sdr_center,
      "-"
    )

    scores_valid <- compute_scores(
      newX = X_valid_centered,
      directions = sdr_fit$directions
    )

    scores_train <- sdr_fit$scores

    for (d in seq_len(d_max)) {

      lm_fit <- fit_downstream_lm(
        scores = scores_train,
        y = y_train,
        d = d
      )

      y_pred <- predict_downstream_lm(
        fit_lm = lm_fit,
        scores_new = scores_valid,
        d = d
      )

      perf <- evaluate_prediction(
        y_true = y_valid,
        y_pred = y_pred,
        d = d
      )

      fold_results[[counter]] <- data.frame(
        fold = fold,
        d = d,
        perf
      )

      counter <- counter + 1L
    }
  }

  fold_results <- do.call(rbind, fold_results)

  cv_table <- stats::aggregate(
    fold_results[, c("RMSE", "MAE", "MAPE", "R2", "Adjusted_R2", "Correlation")],
    by = list(d = fold_results$d),
    FUN = function(z) mean(z, na.rm = TRUE)
  )

  cv_sd <- stats::aggregate(
    fold_results[, c("RMSE", "MAE", "MAPE", "R2", "Adjusted_R2", "Correlation")],
    by = list(d = fold_results$d),
    FUN = stats::sd
  )

  names(cv_sd)[-1] <- paste0(names(cv_sd)[-1], "_SD")

  cv_table <- merge(cv_table, cv_sd, by = "d")

  selected_d <- cv_table$d[which.min(cv_table[[metric]])]

  list(
    selected_d = selected_d,
    metric = metric,
    cv_table = cv_table,
    fold_results = fold_results,
    folds = folds
  )
}


#' Plot cross-validation dimension selection result
#'
#' @param cv Object returned by select_dimension_cv().
#' @param metric Metric to plot.
#' @param ... Additional arguments passed to internal methods.
#'
#' @return Invisibly returns the CV table.
#' @export
plot_cv_dimension <- function(
    cv,
    metric = NULL,
    ...
) {

  if (!is.list(cv) || is.null(cv$cv_table)) {
    stop("`cv` must be an object returned by select_dimension_cv().", call. = FALSE)
  }

  if (is.null(metric)) {
    metric <- cv$metric
  }

  if (!metric %in% names(cv$cv_table)) {
    stop("Requested metric not found in `cv$cv_table`.", call. = FALSE)
  }

  plot(
    cv$cv_table$d,
    cv$cv_table[[metric]],
    type = "b",
    pch = 19,
    xlab = "Structural dimension (d)",
    ylab = paste0("Mean CV ", metric),
    main = paste0("Cross-Validation Dimension Selection: ", metric),
    ...
  )

  abline(
    v = cv$selected_d,
    lty = 2
  )

  invisible(cv$cv_table)
}
