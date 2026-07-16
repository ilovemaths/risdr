# ============================================================
# R/dimension_selection.R
# Structural dimension selection for risdr
# ============================================================


#' Covariance complexity C1
#'
#' Computes Bozdogan-type maximal covariance complexity.
#'
#' @param Sigma A covariance matrix.
#' @param eps Eigenvalue floor.
#'
#' @return Numeric complexity value.
#' @export
cov_complexity_C1 <- function(Sigma, eps = 1e-10) {

  Sigma <- check_cov_matrix(Sigma)

  eig <- eigen(Sigma, symmetric = TRUE, only.values = TRUE)$values
  eig <- pmax(eig, eps)

  s <- length(eig)

  C1 <- (s / 2) * log(mean(eig)) - (1 / 2) * sum(log(eig))

  as.numeric(C1)
}


#' Scale-invariant covariance complexity C1F
#'
#' Computes the scale-invariant C1F covariance complexity measure.
#'
#' @param Sigma A covariance matrix.
#' @param eps Eigenvalue floor.
#'
#' @return Numeric complexity value.
#' @export
cov_complexity_C1F <- function(Sigma, eps = 1e-10) {

  Sigma <- check_cov_matrix(Sigma)

  eig <- eigen(Sigma, symmetric = TRUE, only.values = TRUE)$values
  eig <- pmax(eig, eps)

  lambda_bar <- mean(eig)

  if (lambda_bar <= eps) {
    return(0)
  }

  C1F <- sum((eig - lambda_bar)^2) / (4 * lambda_bar^2)

  as.numeric(C1F)
}


#' Compute model selection criteria
#'
#' Computes AIC, BIC, CAIC, ICOMP, and CICOMP for a fitted linear model.
#'
#' @param fit A fitted lm object.
#' @param complexity Character string. Complexity measure, either "C1" or "C1F".
#' @param eps Eigenvalue floor.
#'
#' @return Named numeric vector of criteria.
#' @export
compute_information_criteria <- function(
    fit,
    complexity = c("C1", "C1F"),
    eps = 1e-10
) {

  if (!inherits(fit, "lm")) {
    stop("`fit` must be an object of class 'lm'.", call. = FALSE)
  }

  complexity <- match.arg(complexity)

  n <- stats::nobs(fit)
  logLik_fit <- as.numeric(stats::logLik(fit))

  k <- length(stats::coef(fit)) + 1L

  AIC_value <- -2 * logLik_fit + 2 * k
  BIC_value <- -2 * logLik_fit + log(n) * k
  CAIC_value <- -2 * logLik_fit + (log(n) + 1) * k

  V <- stats::vcov(fit)

  if (complexity == "C1") {
    C_value <- cov_complexity_C1(V, eps = eps)
  } else {
    C_value <- cov_complexity_C1F(V, eps = eps)
  }

  ICOMP_value <- -2 * logLik_fit + 2 * C_value
  CICOMP_value <- CAIC_value + 2 * C_value

  c(
    AIC = AIC_value,
    BIC = BIC_value,
    CAIC = CAIC_value,
    ICOMP = ICOMP_value,
    CICOMP = CICOMP_value
  )
}


#' Select structural dimension
#'
#' Fits linear models on SDR scores for candidate dimensions and computes
#' information criteria.
#'
#' @param scores Matrix of SDR scores.
#' @param y Numeric response vector.
#' @param d_max Maximum candidate dimension.
#' @param complexity Complexity measure for ICOMP.
#' @param eps Eigenvalue floor.
#'
#' @return A data frame of criteria by candidate dimension.
#' @export
select_dimension <- function(
    scores,
    y,
    d_max = 10,
    complexity = c("C1", "C1F"),
    eps = 1e-10
) {

  scores <- check_X(scores)
  y <- check_y_continuous(y, nrow(scores))
  check_missing(scores, y)

  complexity <- match.arg(complexity)

  p <- ncol(scores)

  dims <- check_dimensions(
    d = NULL,
    d_max = d_max,
    p = p,
    n = nrow(scores)
  )
  d_max <- dims$d_max

  out <- data.frame(
    d = seq_len(d_max),
    AIC = NA_real_,
    BIC = NA_real_,
    CAIC = NA_real_,
    ICOMP = NA_real_,
    CICOMP = NA_real_
  )

  for (d in seq_len(d_max)) {

    Z_d <- scores[, seq_len(d), drop = FALSE]
    Z_d <- as.data.frame(Z_d)
    names(Z_d) <- paste0("SDR", seq_len(d))

    dat <- data.frame(y = y, Z_d)

    fit_d <- stats::lm(y ~ ., data = dat)

    crit <- compute_information_criteria(
      fit = fit_d,
      complexity = complexity,
      eps = eps
    )

    out[out$d == d, names(crit)] <- crit
  }

  out
}


#' Choose dimension from criteria table
#'
#' @param d_table Data frame returned by select_dimension().
#' @param selector Criterion used for selection.
#'
#' @return Selected structural dimension.
#' @export
choose_dimension <- function(
    d_table,
    selector = c("cicomp", "icomp", "bic", "caic", "aic")
) {

  selector <- check_selector(selector)

  criterion <- toupper(selector)

  if (!criterion %in% names(d_table)) {
    stop("Selected criterion not found in `d_table`.", call. = FALSE)
  }

  d_table$d[which.min(d_table[[criterion]])]
}


#' Information criterion weights
#'
#' Computes relative weights from any information criterion column.
#'
#' @param d_table Dimension selection table.
#' @param criterion Criterion column name.
#'
#' @return Data frame with criterion differences and weights.
#' @export
criterion_weights <- function(
    d_table,
    criterion = c("AIC", "BIC", "CAIC", "ICOMP", "CICOMP")
) {

  criterion <- match.arg(criterion)

  if (!criterion %in% names(d_table)) {
    stop("Criterion not found in `d_table`.", call. = FALSE)
  }

  values <- d_table[[criterion]]
  delta <- values - min(values)
  weights <- exp(-0.5 * delta)
  weights <- weights / sum(weights)

  data.frame(
    d = d_table$d,
    criterion = criterion,
    value = values,
    delta = delta,
    weight = weights
  )
}
