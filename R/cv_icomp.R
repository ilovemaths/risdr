# ============================================================
# R/cv_icomp.R
# Complexity-aware cross-validation for risdr
# ============================================================

#' Complexity-aware cross-validation for structural dimension selection
#'
#' Combines out-of-fold prediction error with rescaled BIC, CAIC, or CICOMP
#' penalties. The tuning constant `lambda` controls the contribution of the
#' information-criterion component.
#'
#' @param X Numeric predictor matrix or data frame.
#' @param y Numeric continuous response vector.
#' @param sdr_method SDR method.
#' @param cov_method Covariance estimator.
#' @param d_max Maximum candidate structural dimension.
#' @param v Number of cross-validation folds.
#' @param nslices Number of response slices.
#' @param standardize Logical. Standardise within each training fold.
#' @param stabilize Logical. Stabilise the estimated covariance matrix.
#' @param stabilization Covariance stabilisation method.
#' @param complexity Covariance complexity measure.
#' @param lambda Non-negative information-criterion weight.
#' @param seed Optional random seed.
#' @param cov_args Named list of covariance-estimator arguments.
#' @param stabilization_args Named list of stabilisation arguments.
#' @param sdr_args Named list of SDR-kernel arguments.
#' @param ... Backward-compatible component arguments.
#'
#' @return A list containing selected dimensions, the aggregated
#'   cross-validation table, and fold-level results.
#' @export
select_dimension_cv_icomp <- function(
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
    complexity = c("C1", "C1F"),
    lambda = 1,
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
  complexity <- match.arg(complexity)
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

  if (!is.numeric(lambda) || length(lambda) != 1L ||
      !is.finite(lambda) || lambda < 0) {
    stop("`lambda` must be a single non-negative numeric value.", call. = FALSE)
  }

  folds <- make_cv_folds(n = nrow(X), v = v, seed = seed)

  fold_results <- list()
  counter <- 1L

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
        d = d_max,
        d_max = d_max,
        selector = "cicomp",
        standardize = standardize,
        stabilize = stabilize,
        stabilization = stabilization,
        complexity = complexity,
        cov_args = cov_args,
        stabilization_args = stabilization_args,
        sdr_args = sdr_args,
        ...
      ),
      error = function(e) e
    )

    if (inherits(fit_fold, "error")) {
      next
    }

    pred_scores <- compute_scores_for_newdata(fit_fold, X_valid_fold)

    for (d in seq_len(d_max)) {

      lm_fit <- fit_downstream_lm(
        scores = fit_fold$scores,
        y = y_train_fold,
        d = d
      )

      y_pred <- predict_downstream_lm(
        fit_lm = lm_fit,
        scores_new = pred_scores,
        d = d
      )

      perf <- evaluate_prediction(
        y_true = y_valid_fold,
        y_pred = y_pred,
        d = d
      )

      crit <- compute_information_criteria(
        fit = lm_fit,
        complexity = complexity
      )

      fold_results[[counter]] <- data.frame(
        fold = fold,
        d = d,
        RMSE = perf$RMSE,
        MAE = perf$MAE,
        R2 = perf$R2,
        Adjusted_R2 = perf$Adjusted_R2,
        Correlation = perf$Correlation,
        AIC = crit["AIC"],
        BIC = crit["BIC"],
        CAIC = crit["CAIC"],
        ICOMP = crit["ICOMP"],
        CICOMP = crit["CICOMP"]
      )

      counter <- counter + 1L
    }
  }

  fold_results <- do.call(rbind, fold_results)

  if (is.null(fold_results) || nrow(fold_results) == 0) {
    stop("All cross-validation folds failed.", call. = FALSE)
  }

  metric_names <- c(
    "RMSE", "MAE", "R2", "Adjusted_R2", "Correlation",
    "AIC", "BIC", "CAIC", "ICOMP", "CICOMP"
  )

  cv_table <- stats::aggregate(
    fold_results[, metric_names, drop = FALSE],
    by = list(d = fold_results$d),
    FUN = function(z) mean(z, na.rm = TRUE)
  )

  names(cv_table)[-1L] <- paste0("mean_", names(cv_table)[-1L])

  rmse_sd <- stats::aggregate(
    fold_results$RMSE,
    by = list(d = fold_results$d),
    FUN = function(z) stats::sd(z, na.rm = TRUE)
  )
  names(rmse_sd)[2L] <- "sd_RMSE"
  cv_table <- merge(cv_table, rmse_sd, by = "d", sort = TRUE)

  scale01 <- function(z) {
    rng <- max(z, na.rm = TRUE) - min(z, na.rm = TRUE)
    if (rng < .Machine$double.eps) {
      return(rep(0, length(z)))
    }
    (z - min(z, na.rm = TRUE)) / rng
  }

  cv_table$RMSE_scaled <- scale01(cv_table$mean_RMSE)
  cv_table$BIC_scaled <- scale01(cv_table$mean_BIC)
  cv_table$CAIC_scaled <- scale01(cv_table$mean_CAIC)
  cv_table$CICOMP_scaled <- scale01(cv_table$mean_CICOMP)
  cv_table$CVBIC <- cv_table$RMSE_scaled + lambda * cv_table$BIC_scaled
  cv_table$CVCAIC <- cv_table$RMSE_scaled + lambda * cv_table$CAIC_scaled
  cv_table$CVCICOMP <- cv_table$RMSE_scaled + lambda * cv_table$CICOMP_scaled

  list(
    selected_d_rmse = cv_table$d[which.min(cv_table$mean_RMSE)],
    selected_d_cvbic = cv_table$d[which.min(cv_table$CVBIC)],
    selected_d_cvcaic = cv_table$d[which.min(cv_table$CVCAIC)],
    selected_d_cvcicomp = cv_table$d[which.min(cv_table$CVCICOMP)],
    lambda = lambda,
    cv_table = as.data.frame(cv_table),
    fold_results = fold_results
  )
}

compute_scores_for_newdata <- function(object, newX) {

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

  compute_scores(
    newX = newX_sdr_centered,
    directions = object$directions
  )
}
