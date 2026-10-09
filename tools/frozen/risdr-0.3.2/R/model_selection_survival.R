# ============================================================
# R/model_selection_survival.R
# Reduced-model information criteria for continuous, categorical,
# and censored-survival responses
# ============================================================

.risdr_reduced_model_components <- function(
    y,
    Z,
    response_type,
    delta = NULL,
    n_active = NULL,
    support_penalty = FALSE,
    tol = 1e-10
) {

  response_type <- match.arg(
    response_type,
    c("continuous", "categorical", "survival")
  )

  Z <- as.matrix(Z)

  n <- nrow(Z)
  d <- ncol(Z)

  if (length(y) != n) {
    stop("Length of `y` must equal nrow(`Z`).", call. = FALSE)
  }

  if (response_type == "survival") {

    if (is.null(delta)) {
      stop("For survival response, `delta` must be supplied.", call. = FALSE)
    }

    if (length(delta) != n) {
      stop("`delta` must have length nrow(`Z`).", call. = FALSE)
    }

    delta <- as.integer(delta)

    if (!all(delta %in% c(0L, 1L))) {
      stop("`delta` must contain only 0/1 values.", call. = FALSE)
    }

    dat <- data.frame(
      time = as.numeric(y),
      delta = delta,
      Z
    )

    fit <- suppressWarnings(
      survival::coxph(
        survival::Surv(time, delta) ~ .,
        data = dat,
        ties = "efron"
      )
    )

    loglik <- as.numeric(fit$loglik[2L])
    base_df <- d

  } else if (response_type == "continuous") {

    dat <- data.frame(
      y = as.numeric(y),
      Z
    )

    fit <- stats::lm(
      y ~ .,
      data = dat
    )

    loglik <- as.numeric(
      stats::logLik(fit)
    )

    base_df <- d + 1L

  } else {

    y_fac <- as.factor(y)
    nclass <- nlevels(y_fac)

    if (nclass < 2L) {
      stop("Categorical response must contain at least two classes.", call. = FALSE)
    }

    if (nclass == 2L) {

      dat <- data.frame(
        y = as.numeric(y_fac) - 1L,
        Z
      )

      fit <- suppressWarnings(
        stats::glm(
          y ~ .,
          data = dat,
          family = stats::binomial()
        )
      )

      loglik <- as.numeric(
        stats::logLik(fit)
      )

      base_df <- d + 1L

    } else {

      if (!requireNamespace("nnet", quietly = TRUE)) {
        stop("Package `nnet` is required for multiclass response.", call. = FALSE)
      }

      dat <- data.frame(
        y = y_fac,
        Z
      )

      fit <- suppressWarnings(
        nnet::multinom(
          y ~ .,
          data = dat,
          trace = FALSE
        )
      )

      loglik <- as.numeric(
        stats::logLik(fit)
      )

      base_df <- (d + 1L) * (nclass - 1L)
    }
  }

  if (support_penalty && !is.null(n_active)) {

    n_active <- as.integer(n_active)

    if (length(n_active) != 1L || is.na(n_active) || n_active < 0L) {
      stop("`n_active` must be a non-negative integer scalar.", call. = FALSE)
    }

    k_eff <- base_df + n_active

  } else {

    k_eff <- base_df
  }

  k_eff <- max(as.integer(k_eff), 1L)

  if (d == 1L) {

    vz <- stats::var(as.numeric(Z[, 1L]))

    if (!is.finite(vz)) {
      vz <- tol
    }

    cov_theta <- matrix(
      max(vz, tol),
      nrow = 1L,
      ncol = 1L
    )

  } else {

    cov_theta <- stats::cov(Z)
    cov_theta <- as.matrix(cov_theta)
  }

  cov_theta <- (cov_theta + t(cov_theta)) / 2

  eigvals <- eigen(
    cov_theta,
    symmetric = TRUE,
    only.values = TRUE
  )$values

  eigvals <- eigvals[eigvals > tol]

  if (length(eigvals) == 0L) {
    c1f_val <- 0
  } else {
    c1f_val <- utils::tail(
      C1F(eigvals, tol = tol)$c1f,
      1L
    )
  }

  list(
    n = n,
    d = d,
    loglik = loglik,
    k_eff = k_eff,
    c1f = as.numeric(c1f_val)
  )
}


#' Compute all reduced-model information criteria
#'
#' @param y Response vector.
#' @param Z Reduced predictors.
#' @param response_type Response type.
#' @param delta Optional event indicator.
#' @param n_active Optional active-support size.
#' @param support_penalty Include active-support size in effective df.
#' @param tol Numerical tolerance.
#' @return Named numeric vector containing AIC, BIC, CAIC, ICOMP, CICOMP,
#'   log-likelihood, effective df, and C1F.
#' @export
compute_ic_values <- function(
    y,
    Z,
    response_type = c("continuous", "categorical", "survival"),
    delta = NULL,
    n_active = NULL,
    support_penalty = FALSE,
    tol = 1e-10
) {

  response_type <- match.arg(response_type)

  comp <- .risdr_reduced_model_components(
    y = y,
    Z = Z,
    response_type = response_type,
    delta = delta,
    n_active = n_active,
    support_penalty = support_penalty,
    tol = tol
  )

  n <- comp$n
  k <- comp$k_eff
  loglik <- comp$loglik
  c1f <- comp$c1f

  c(
    AIC = -2 * loglik + 2 * k,
    BIC = -2 * loglik + log(n) * k,
    CAIC = -2 * loglik + k * (log(n) + 1),
    ICOMP = -2 * loglik + 2 * c1f + 2 * k,
    CICOMP = -2 * loglik + k * (log(n) + 1) + 2 * c1f,
    logLik = loglik,
    k_eff = k,
    C1F = c1f
  )
}


#' Compute one reduced-model information criterion
#'
#' @param y Response vector.
#' @param Z Reduced predictors.
#' @param criterion Criterion name.
#' @param response_type Response type.
#' @param delta Optional event indicator.
#' @param n_active Optional active-support size.
#' @param support_penalty Include active-support size in effective df.
#' @param tol Numerical tolerance.
#' @return Scalar criterion value.
#' @export
compute_ic <- function(
    y,
    Z,
    criterion = c("cicomp", "icomp", "aic", "caic", "bic"),
    response_type = c("continuous", "categorical", "survival"),
    delta = NULL,
    n_active = NULL,
    support_penalty = FALSE,
    tol = 1e-10
) {

  criterion <- match.arg(criterion)
  response_type <- match.arg(response_type)

  values <- compute_ic_values(
    y = y,
    Z = Z,
    response_type = response_type,
    delta = delta,
    n_active = n_active,
    support_penalty = support_penalty,
    tol = tol
  )

  unname(
    values[toupper(criterion)]
  )
}
