#' Predict from the sparse or dual SDR engine
#'
#' Projects new observations using the training centring, scaling, and selected
#' directions. Survival predictions are Cox linear predictors or relative risks;
#' they are not predicted survival times.
#'
#' @param object A sparse or dual RISDR fit.
#' @param newX Numeric predictor matrix or data frame, with named columns.
#' @param type Prediction type. `"response"` returns continuous predictions,
#'   binary probabilities, multiclass labels, or survival relative risks.
#'   `"scores"` returns the selected SDR coordinates. `"link"` and `"risk"`
#'   are available for survival outcomes. `"class"` and `"probs"` are
#'   available for categorical outcomes.
#' @param ... Additional arguments passed to the downstream prediction method.
#' @return Predictions or a score matrix, according to `type`.
#' @name predict.risdr_sparse
#' @export
predict.risdr_sparse <- function(object, newX,
    type = c("response", "scores", "link", "risk", "class", "probs"), ...) {
  type <- match.arg(type)
  X <- .sparse_prediction_matrix(newX, colnames(object$X))
  X <- sweep(X, 2L, object$center, "-")
  X <- sweep(X, 2L, object$scale, "/")
  X <- sweep(X, 2L, object$sdr_center, "-")
  Z <- X %*% object$directions
  colnames(Z) <- colnames(object$reduced_predictors)
  if (type == "scores") return(Z)
  dat <- as.data.frame(Z)
  if (object$response_type == "survival") {
    if (!type %in% c("response", "link", "risk"))
      stop("Survival prediction type must be response, link, risk, or scores.", call. = FALSE)
    prediction_type <- if (type == "response") "risk" else if (type == "link") "lp" else type
    return(stats::predict(object$downstream_fit, newdata = dat,
                          type = prediction_type, ...))
  }
  if (object$response_type == "continuous") {
    if (!type %in% c("response", "link"))
      stop("Continuous prediction type must be response, link, or scores.", call. = FALSE)
    return(stats::predict(object$downstream_fit, newdata = dat, ...))
  }
  if (inherits(object$downstream_fit, "glm")) {
    if (!type %in% c("response", "link", "class", "probs"))
      stop("Invalid categorical prediction type.", call. = FALSE)
    p <- stats::predict(object$downstream_fit, newdata = dat,
                        type = if (type == "link") "link" else "response", ...)
    if (type == "class") return(factor(levels(as.factor(object$y))[1L + (p >= 0.5)],
                                      levels = levels(as.factor(object$y))))
    return(p)
  }
  if (!type %in% c("response", "class", "probs"))
    stop("Multiclass prediction type must be response, class, probs, or scores.", call. = FALSE)
  stats::predict(object$downstream_fit, newdata = dat,
                 type = if (type == "probs") "probs" else "class", ...)
}

#' @rdname predict.risdr_sparse
#' @export
predict.risdr_dual <- function(object, newX,
    type = c("response", "scores", "link", "risk", "class", "probs"), ...) {
  type <- match.arg(type)
  X <- .sparse_prediction_matrix(newX, rownames(object$dual$loadings))
  X <- sweep(X, 2L, object$dual$center, "-")
  X <- sweep(X, 2L, object$dual$scale, "/")
  dual_scores <- X %*% object$dual$loadings
  colnames(dual_scores) <- colnames(object$fit_dual$X)
  stats::predict(object$fit_dual, newX = dual_scores, type = type, ...)
}

.sparse_prediction_matrix <- function(newX, variables) {
  X <- as.matrix(newX)
  if (!is.numeric(X) || length(dim(X)) != 2L || nrow(X) < 1L ||
      anyNA(X) || any(!is.finite(X)))
    stop("`newX` must contain finite numeric predictors and at least one row.", call. = FALSE)
  if (ncol(X) != length(variables))
    stop("`newX` must contain all training predictor columns.", call. = FALSE)
  if (!is.null(colnames(X))) {
    if (anyDuplicated(colnames(X)) || !setequal(colnames(X), variables))
      stop("`newX` predictor names must match the training names.", call. = FALSE)
    X <- X[, variables, drop = FALSE]
  } else colnames(X) <- variables
  X
}
