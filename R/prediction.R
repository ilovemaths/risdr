# ============================================================
# R/prediction.R
# Prediction and performance evaluation for risdr
# ============================================================


#' Fit downstream regression model on SDR scores
#'
#' Fits a linear regression model using the first d SDR scores.
#'
#' @param scores Matrix of SDR scores.
#' @param y Numeric response vector.
#' @param d Structural dimension.
#'
#' @return A fitted lm object.
#' @examples
#' scores <- as.matrix(mtcars[, c("wt", "hp")])
#' fit_downstream_lm(scores, y = mtcars$mpg, d = 2)
#' @export
fit_downstream_lm <- function(scores, y, d) {

  scores <- check_X(scores, min_cols = 1L)
  y <- check_y_continuous(y, nrow(scores))
  check_missing(scores, y)

  if (!is.numeric(d) || length(d) != 1 || !is.finite(d) ||
      d != as.integer(d) || d < 1 || d > ncol(scores)) {
    stop("`d` must be a positive integer not exceeding the number of score columns.", call. = FALSE)
  }

  d <- as.integer(d)

  Z_d <- as.data.frame(scores[, seq_len(d), drop = FALSE])
  names(Z_d) <- paste0("SDR", seq_len(d))

  dat <- data.frame(y = y, Z_d)

  stats::lm(y ~ ., data = dat)
}


#' Compute SDR scores for new data
#'
#' Projects new predictor observations onto estimated SDR directions.
#'
#' @param newX New predictor matrix or data frame.
#' @param directions Matrix of SDR directions.
#'
#' @return Matrix of SDR scores.
#' @examples
#' X <- as.matrix(mtcars[1:5, c("wt", "hp", "disp")])
#' directions <- diag(3)[, 1:2, drop = FALSE]
#' compute_scores(X, directions)
#' @export
compute_scores <- function(newX, directions) {

  newX <- check_new_X(newX)

  if (!is.matrix(directions) && !is.data.frame(directions)) {
    stop("`directions` must be a matrix or data frame.", call. = FALSE)
  }

  directions <- as.matrix(directions)

  if (!is.numeric(directions) || anyNA(directions) ||
      any(!is.finite(directions)) || nrow(directions) < 1L ||
      ncol(directions) < 1L) {
    stop("`directions` must be a non-empty finite numeric matrix.", call. = FALSE)
  }

  if (ncol(newX) != nrow(directions)) {
    stop(
      "The number of columns in `newX` must equal the number of rows in `directions`.",
      call. = FALSE
    )
  }

  scores <- newX %*% directions

  colnames(scores) <- paste0("SDR", seq_len(ncol(scores)))

  scores
}


#' Predict from downstream SDR regression model
#'
#' @param fit_lm Fitted linear model from fit_downstream_lm().
#' @param scores_new Matrix of new SDR scores.
#' @param d Structural dimension.
#'
#' @return Numeric vector of predictions.
#' @export
predict_downstream_lm <- function(fit_lm, scores_new, d) {

  if (!inherits(fit_lm, "lm")) {
    stop("`fit_lm` must be an object of class 'lm'.", call. = FALSE)
  }

  scores_new <- check_new_X(scores_new)

  if (!is.numeric(d) || length(d) != 1 || !is.finite(d) ||
      d != as.integer(d) || d < 1 || d > ncol(scores_new)) {
    stop("`d` must be a positive integer not exceeding the number of score columns.", call. = FALSE)
  }

  d <- as.integer(d)

  Z_new <- as.data.frame(scores_new[, seq_len(d), drop = FALSE])
  names(Z_new) <- paste0("SDR", seq_len(d))

  as.numeric(stats::predict(fit_lm, newdata = Z_new))
}


#' Root mean squared error
#'
#' @param y_true Observed response values.
#' @param y_pred Predicted response values.
#'
#' @return Numeric RMSE.
#' @examples
#' rmse(c(2, 4, 6, 8), c(2.2, 3.8, 5.7, 8.1))
#' @export
rmse <- function(y_true, y_pred) {

  check_prediction_vectors(y_true, y_pred)

  sqrt(mean((y_true - y_pred)^2))
}


#' Mean absolute error
#'
#' @param y_true Observed response values.
#' @param y_pred Predicted response values.
#'
#' @return Numeric MAE.
#' @examples
#' mae(c(2, 4, 6, 8), c(2.2, 3.8, 5.7, 8.1))
#' @export
mae <- function(y_true, y_pred) {

  check_prediction_vectors(y_true, y_pred)

  mean(abs(y_true - y_pred))
}


#' Mean absolute percentage error
#'
#' @param y_true Observed response values.
#' @param y_pred Predicted response values.
#'
#' @return Numeric MAPE.
#' @examples
#' mape(c(2, 4, 6, 8), c(2.2, 3.8, 5.7, 8.1))
#' @export
mape <- function(y_true, y_pred) {

  check_prediction_vectors(y_true, y_pred)

  if (any(abs(y_true) < .Machine$double.eps)) {
    warning(
      "MAPE is undefined because at least one observed value is zero or near zero.",
      call. = FALSE
    )
    return(NA_real_)
  }

  mean(abs((y_true - y_pred) / y_true)) * 100
}


#' Coefficient of determination
#'
#' @param y_true Observed response values.
#' @param y_pred Predicted response values.
#'
#' @return Numeric R-squared.
#' @examples
#' r_squared(c(2, 4, 6, 8), c(2.2, 3.8, 5.7, 8.1))
#' @export
r_squared <- function(y_true, y_pred) {

  check_prediction_vectors(y_true, y_pred)

  ss_res <- sum((y_true - y_pred)^2)
  ss_tot <- sum((y_true - mean(y_true))^2)

  if (ss_tot < .Machine$double.eps) {
    warning("Total sum of squares is near zero. R-squared is undefined.", call. = FALSE)
    return(NA_real_)
  }

  1 - ss_res / ss_tot
}


#' Adjusted coefficient of determination
#'
#' @param y_true Observed response values.
#' @param y_pred Predicted response values.
#' @param d Number of predictors in the downstream model.
#'
#' @return Numeric adjusted R-squared.
#' @examples
#' adjusted_r_squared(
#'   c(2, 4, 6, 8, 10),
#'   c(2.2, 3.8, 5.7, 8.1, 9.8),
#'   d = 1
#' )
#' @export
adjusted_r_squared <- function(y_true, y_pred, d) {

  check_prediction_vectors(y_true, y_pred)

  n <- length(y_true)

  if (!is.numeric(d) || length(d) != 1 || !is.finite(d) ||
      d != as.integer(d) || d < 1) {
    stop("`d` must be a positive integer.", call. = FALSE)
  }

  d <- as.integer(d)

  if (n <= d + 1) {
    warning("Sample size is too small relative to d. Adjusted R-squared is undefined.", call. = FALSE)
    return(NA_real_)
  }

  r2 <- r_squared(y_true, y_pred)

  1 - (1 - r2) * (n - 1) / (n - d - 1)
}


#' Prediction correlation
#'
#' @param y_true Observed response values.
#' @param y_pred Predicted response values.
#'
#' @return Pearson correlation.
#' @examples
#' prediction_correlation(
#'   c(2, 4, 6, 8),
#'   c(2.2, 3.8, 5.7, 8.1)
#' )
#' @export
prediction_correlation <- function(y_true, y_pred) {

  check_prediction_vectors(y_true, y_pred)

  stats::cor(y_true, y_pred)
}


#' Evaluate predictions
#'
#' Computes common prediction metrics.
#'
#' @param y_true Observed response values.
#' @param y_pred Predicted response values.
#' @param d Optional number of reduced predictors.
#'
#' @return A data frame of prediction metrics.
#' @examples
#' evaluate_prediction(
#'   y_true = c(2, 4, 6, 8, 10),
#'   y_pred = c(2.2, 3.8, 5.7, 8.1, 9.8),
#'   d = 1
#' )
#' @export
evaluate_prediction <- function(y_true, y_pred, d = NULL) {

  check_prediction_vectors(y_true, y_pred)

  r2 <- r_squared(y_true, y_pred)

  adj_r2 <- NA_real_
  if (!is.null(d)) {
    adj_r2 <- adjusted_r_squared(y_true, y_pred, d = d)
  }

  data.frame(
    RMSE = rmse(y_true, y_pred),
    MAE = mae(y_true, y_pred),
    MAPE = mape(y_true, y_pred),
    R2 = r2,
    Adjusted_R2 = adj_r2,
    Correlation = prediction_correlation(y_true, y_pred)
  )
}


#' Check prediction vectors
#'
#' @param y_true Observed response values.
#' @param y_pred Predicted response values.
#'
#' @return Invisibly TRUE.
#' @keywords internal
check_prediction_vectors <- function(y_true, y_pred) {

  if (!is.numeric(y_true) || !is.numeric(y_pred)) {
    stop("`y_true` and `y_pred` must both be numeric.", call. = FALSE)
  }

  y_true <- as.numeric(y_true)
  y_pred <- as.numeric(y_pred)

  if (length(y_true) != length(y_pred)) {
    stop("`y_true` and `y_pred` must have the same length.", call. = FALSE)
  }

  if (anyNA(y_true) || anyNA(y_pred)) {
    stop("Prediction vectors must not contain missing values.", call. = FALSE)
  }

  if (any(!is.finite(y_true)) || any(!is.finite(y_pred))) {
    stop("Prediction vectors must contain only finite values.", call. = FALSE)
  }

  invisible(TRUE)
}
