# ============================================================
# R/cv_prediction.R
# Repeated cross-validation for predictive assessment
# ============================================================

#' Repeated cross-validation for predictive assessment
#'
#' Repeats V-fold cross-validation for a fixed SDR and covariance-estimator
#' combination. Failed folds are retained with diagnostic messages.
#'
#' @param X Numeric predictor matrix or data frame.
#' @param y Numeric continuous response vector.
#' @param sdr_method SDR method.
#' @param cov_method Covariance estimator.
#' @param d Fixed structural dimension.
#' @param v Number of folds.
#' @param repeats Number of cross-validation repetitions.
#' @param nslices Number of response slices.
#' @param standardize Logical. Standardise within each training fold.
#' @param stabilize Logical. Stabilise the estimated covariance matrix.
#' @param stabilization Covariance stabilisation method.
#' @param seed Optional random seed.
#' @param cov_args Named list of covariance-estimator arguments.
#' @param stabilization_args Named list of stabilisation arguments.
#' @param sdr_args Named list of SDR-kernel arguments.
#' @param ... Backward-compatible component arguments.
#'
#' @return A list containing a one-row summary and fold-level results.
#' @export
evaluate_prediction_cv <- function(
    X,
    y,
    sdr_method = c("dr", "sir", "save", "phd"),
    cov_method = c("sample", "ridge", "oas", "lw", "mec"),
    d,
    v = 5,
    repeats = 10,
    nslices = 6,
    standardize = TRUE,
    stabilize = TRUE,
    stabilization = c("eigenfloor", "ridge", "nearest_pd"),
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
  cv_design <- check_cv_design(nrow(X), v)
  v <- cv_design$v
  nslices <- check_nslices(nslices, cv_design$minimum_training_size)
  standardize <- check_flag(standardize, "standardize")
  stabilize <- check_flag(stabilize, "stabilize")

  if (!is.numeric(d) || length(d) != 1 || !is.finite(d) ||
      d != as.integer(d) || d < 1 ||
      d > min(ncol(X) - 1L, cv_design$minimum_training_size - 2L)) {
    stop(
      "`d` is too large for the available predictors or fold-level training samples.",
      call. = FALSE
    )
  }

  d <- as.integer(d)

  if (!is.numeric(repeats) || length(repeats) != 1L ||
      !is.finite(repeats) || repeats != as.integer(repeats) || repeats < 1L) {
    stop("`repeats` must be a positive integer.", call. = FALSE)
  }

  repeats <- as.integer(repeats)

  results <- list()
  counter <- 1L

  for (r in seq_len(repeats)) {

    folds <- make_cv_folds(
      n = nrow(X),
      v = v,
      seed = if (is.null(seed)) NULL else seed + r
    )

    for (fold in seq_len(v)) {

      train_idx <- which(folds != fold)
      valid_idx <- which(folds == fold)

      X_train_fold <- X[train_idx, , drop = FALSE]
      y_train_fold <- y[train_idx]
      X_valid_fold <- X[valid_idx, , drop = FALSE]
      y_valid_fold <- y[valid_idx]

      fit_fold <- tryCatch(
        fit_risdr(
          X = X_train_fold,
          y = y_train_fold,
          sdr_method = sdr_method,
          cov_method = cov_method,
          nslices = nslices,
          d = d,
          d_max = max(d, 2),
          selector = "cicomp",
          standardize = standardize,
          stabilize = stabilize,
          stabilization = stabilization,
          cov_args = cov_args,
          stabilization_args = stabilization_args,
          sdr_args = sdr_args,
          ...
        ),
        error = function(e) e
      )

      if (inherits(fit_fold, "error")) {
        results[[counter]] <- data.frame(
          repetition = r,
          fold = fold,
          sdr_method = toupper(sdr_method),
          cov_method = toupper(cov_method),
          d = d,
          status = "failed",
          error_message = fit_fold$message,
          RMSE = NA_real_,
          MAE = NA_real_,
          MAPE = NA_real_,
          R2 = NA_real_,
          Adjusted_R2 = NA_real_,
          Correlation = NA_real_
        )
        counter <- counter + 1L
        next
      }

      y_pred <- predict(fit_fold, newX = X_valid_fold, d = d)

      perf <- evaluate_prediction(
        y_true = y_valid_fold,
        y_pred = y_pred,
        d = d
      )

      results[[counter]] <- data.frame(
        repetition = r,
        fold = fold,
        sdr_method = toupper(sdr_method),
        cov_method = toupper(cov_method),
        d = d,
        status = "success",
        error_message = NA_character_,
        RMSE = perf$RMSE,
        MAE = perf$MAE,
        MAPE = perf$MAPE,
        R2 = perf$R2,
        Adjusted_R2 = perf$Adjusted_R2,
        Correlation = perf$Correlation
      )

      counter <- counter + 1L
    }
  }

  cv_results <- do.call(rbind, results)
  successful <- cv_results[cv_results$status == "success", , drop = FALSE]

  if (nrow(successful) == 0L) {
    cv_summary <- data.frame(
      n_success = 0L,
      mean_RMSE = NA_real_,
      sd_RMSE = NA_real_,
      mean_MAE = NA_real_,
      sd_MAE = NA_real_,
      mean_MAPE = NA_real_,
      mean_R2 = NA_real_,
      mean_Adjusted_R2 = NA_real_,
      mean_Correlation = NA_real_
    )
  } else {
    cv_summary <- data.frame(
      n_success = nrow(successful),
      mean_RMSE = mean(successful$RMSE, na.rm = TRUE),
      sd_RMSE = stats::sd(successful$RMSE, na.rm = TRUE),
      mean_MAE = mean(successful$MAE, na.rm = TRUE),
      sd_MAE = stats::sd(successful$MAE, na.rm = TRUE),
      mean_MAPE = mean(successful$MAPE, na.rm = TRUE),
      mean_R2 = mean(successful$R2, na.rm = TRUE),
      mean_Adjusted_R2 = mean(successful$Adjusted_R2, na.rm = TRUE),
      mean_Correlation = mean(successful$Correlation, na.rm = TRUE)
    )
  }

  list(
    summary = as.data.frame(cv_summary),
    fold_results = cv_results
  )
}
