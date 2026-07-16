# ============================================================
# R/ladle.R
# Ladle-type structural dimension diagnostics for risdr
# ============================================================


#' Ladle-type structural dimension diagnostic
#'
#' Computes a simple ladle-type diagnostic by combining normalised eigenvalue
#' information with a bootstrap-based subspace instability measure.
#'
#' @param X Numeric predictor matrix or data frame.
#' @param y Numeric continuous response vector.
#' @param sdr_method SDR method.
#' @param cov_method Covariance estimator.
#' @param d_max Maximum candidate structural dimension.
#' @param B Number of bootstrap replications.
#' @param nslices Number of slices.
#' @param standardize Logical. If TRUE, standardises predictors.
#' @param stabilize Logical. If TRUE, stabilises covariance matrix.
#' @param stabilization Stabilisation method.
#' @param seed Optional random seed.
#' @param cov_args Named list of covariance-estimator arguments.
#' @param stabilization_args Named list of stabilisation arguments.
#' @param sdr_args Named list of SDR-kernel arguments.
#' @param ... Backward-compatible component arguments.
#'
#' @return A list containing ladle table, selected dimension, and bootstrap distances.
#' @export

select_dimension_ladle <- function(
    X,
    y,
    sdr_method = c("dr", "sir", "save", "phd"),
    cov_method = c("sample", "ridge", "oas", "lw", "mec"),
    d_max = 10,
    B = 100,
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

  if (!is.null(seed)) {
    set.seed(seed)
  }

  X <- check_X(X)
  y <- check_y_continuous(y, nrow(X))
  check_missing(X, y)

  sdr_method <- check_sdr_method(sdr_method)
  cov_method <- match.arg(cov_method)
  stabilization <- check_stabilization_method(stabilization)
  nslices <- check_nslices(nslices, nrow(X))
  standardize <- check_flag(standardize, "standardize")
  stabilize <- check_flag(stabilize, "stabilize")

  dims <- check_dimensions(
    d = NULL,
    d_max = d_max,
    p = ncol(X),
    n = nrow(X)
  )
  d_max <- dims$d_max

  if (!is.numeric(B) || length(B) != 1L || !is.finite(B) ||
      B != as.integer(B) || B < 1L) {
    stop("`B` must be a positive integer.", call. = FALSE)
  }

  B <- as.integer(B)

  fit_full <- fit_risdr(
    X = X,
    y = y,
    sdr_method = sdr_method,
    cov_method = cov_method,
    stabilize = stabilize,
    stabilization = stabilization,
    nslices = nslices,
    d = d_max,
    d_max = d_max,
    standardize = standardize,
    cov_args = cov_args,
    stabilization_args = stabilization_args,
    sdr_args = sdr_args,
    ...
  )

  eig <- abs(fit_full$eigenvalues)
  eig <- eig / (1 + sum(eig))

  eigen_part <- numeric(d_max)

  for (d in seq_len(d_max)) {
    if ((d + 1) <= length(eig)) {
      eigen_part[d] <- eig[d + 1]
    } else {
      eigen_part[d] <- 0
    }
  }

  boot_instability <- matrix(NA_real_, nrow = B, ncol = d_max)
  colnames(boot_instability) <- paste0("d", seq_len(d_max))

  n <- nrow(X)

  V_full <- fit_full$z_directions

  for (b in seq_len(B)) {

    idx <- sample(seq_len(n), size = n, replace = TRUE)

    fit_b <- try(
      fit_risdr(
        X = X[idx, , drop = FALSE],
        y = y[idx],
        sdr_method = sdr_method,
        cov_method = cov_method,
        stabilize = stabilize,
        stabilization = stabilization,
        nslices = nslices,
        d = d_max,
        d_max = d_max,
        standardize = standardize,
        cov_args = cov_args,
        stabilization_args = stabilization_args,
        sdr_args = sdr_args,
        ...
      ),
      silent = TRUE
    )

    if (inherits(fit_b, "try-error")) {
      next
    }

    V_b <- fit_b$z_directions

    for (d in seq_len(d_max)) {

      A <- qr.Q(qr(V_full[, seq_len(d), drop = FALSE]))
      C <- qr.Q(qr(V_b[, seq_len(d), drop = FALSE]))

      sv <- svd(t(A) %*% C, nu = 0, nv = 0)$d
      sv <- pmin(pmax(sv, 0), 1)

      boot_instability[b, d] <- 1 - prod(sv)
    }
  }

  stability_part <- colMeans(boot_instability, na.rm = TRUE)

  if (all(is.na(stability_part))) {
    stop("All bootstrap fits failed. Ladle diagnostic could not be computed.", call. = FALSE)
  }

  ladle_value <- eigen_part + stability_part

  ladle_table <- data.frame(
    d = seq_len(d_max),
    eigen_part = eigen_part,
    stability_part = stability_part,
    ladle = ladle_value
  )

  selected_d <- ladle_table$d[which.min(ladle_table$ladle)]

  list(
    selected_d = selected_d,
    ladle_table = ladle_table,
    boot_instability = boot_instability,
    full_fit = fit_full
  )
}


#' Plot ladle dimension diagnostic
#'
#' @param ladle Object returned by select_dimension_ladle().
#' @param ... Additional graphical arguments passed to [graphics::matplot()].
#'
#' @return Invisibly returns ladle table.
#' @export
plot_ladle <- function(ladle, ...) {

  if (!is.list(ladle) || is.null(ladle$ladle_table)) {
    stop("`ladle` must be an object returned by select_dimension_ladle().", call. = FALSE)
  }

  tab <- ladle$ladle_table

  matplot(
    tab$d,
    tab[, c("eigen_part", "stability_part", "ladle")],
    type = "b",
    pch = c(19, 17, 15),
    lty = c(1, 2, 3),
    xlab = "Structural dimension (d)",
    ylab = "Normalised value",
    main = "Ladle Dimension Diagnostic",
    ...
  )

  abline(v = ladle$selected_d, lty = 2)

  legend(
    "topright",
    legend = c("Eigenvalue part", "Stability part", "Ladle"),
    pch = c(19, 17, 15),
    lty = c(1, 2, 3),
    bty = "n"
  )

  invisible(tab)
}
