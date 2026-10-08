# ============================================================
# R/fit_risdr.R
# Main model-fitting interface for risdr
# ============================================================


#' Fit regularised and information-theoretic sufficient dimension reduction
#'
#' Fits an SDR model using a regularised covariance estimator, a selected
#' inverse-regression kernel, adaptive sparse direction estimation, and
#' information-criterion profiling jointly over structural dimension and
#' sparsity tuning parameter.
#'
#' For `d = NULL`, every candidate dimension from 1 through `d_max` is
#' evaluated over the complete `lambda_grid`. The requested selector then
#' chooses the final `(d, lambda)` pair. For explicit `d`, the same audit grid
#' is retained but the final dimension is fixed and only lambda is selected
#' within that dimension.
#'
#' @param X Numeric predictor matrix or data frame.
#' @param y Response vector. For survival data, observed survival time.
#' @param delta Optional 0/1 event indicator for survival data.
#' @param response_type One of `"continuous"`, `"categorical"`, or
#'   `"survival"`.
#' @param sdr_method One of `"dr"`, `"sir"`, `"save"`, or `"phd"`.
#' @param cov_method One of `"mec"`, `"oas"`, `"lw"`, `"sample"`,
#'   `"ridge"`, or `"user"`.
#' @param stabilize Logical. Stage-3 thesis fits require covariance
#'   stabilisation and therefore currently require `TRUE`.
#' @param stabilization Stabilisation method passed to [estimate_cov()].
#' @param nslices Number of response slices, or slices per censoring-status
#'   group for survival data.
#' @param d Optional fixed structural dimension. If `NULL`, selected by
#'   `selector` from candidates 1 through `d_max`.
#' @param d_max Maximum candidate structural dimension.
#' @param selector One of `"cicomp"`, `"icomp"`, `"bic"`, `"caic"`,
#'   or `"aic"`.
#' @param standardize Logical. Standardise predictor columns before fitting.
#' @param complexity Retained for compatibility. The Stage-3 thesis engine
#'   uses the scale-invariant C1F complexity in ICOMP/CICOMP.
#' @param lambda_grid Non-negative sparsity tuning grid.
#' @param adapt_weights Logical. Use covariance-derived adaptive weights.
#' @param weight_mode One of `"c1f"`, `"inverse_c1f"`, or `"uniform"`.
#' @param penalty_weights Optional user-supplied variable-level weights.
#' @param support_penalty Logical. If `TRUE`, active-support size contributes
#'   to the effective parameter count in the information criteria.
#' @param cov_fun Optional user-defined covariance estimator.
#' @param shrinkage Ridge shrinkage parameter used by [estimate_cov()].
#' @param tol Numerical tolerance.
#' @param ... Additional arguments passed only to a user covariance estimator.
#' @return An object of class `risdr` containing the complete `(d, lambda)`
#'   selection grid, profiled dimension table, selected sparse directions,
#'   reduced predictors, covariance diagnostics, and compatibility fields.
#' @export
fit_risdr <- function(
    X,
    y,
    delta = NULL,
    response_type = c("continuous", "categorical", "survival"),
    sdr_method = c("dr", "sir", "save", "phd"),
    cov_method = c("mec", "oas", "lw", "sample", "ridge", "user"),
    stabilize = TRUE,
    stabilization = c("eigenfloor", "ridge", "nearest_pd"),
    nslices = 6L,
    d = NULL,
    d_max = 10L,
    selector = c("cicomp", "icomp", "bic", "caic", "aic"),
    standardize = TRUE,
    complexity = "C1F",
    lambda_grid = seq(0, 0.30, length.out = 10L),
    adapt_weights = TRUE,
    weight_mode = c("c1f", "inverse_c1f", "uniform"),
    penalty_weights = NULL,
    support_penalty = FALSE,
    cov_fun = NULL,
    shrinkage = 1e-4,
    tol = 1e-10,
    ...
) {

  X <- as.matrix(X)

  if (!is.numeric(X)) {
    stop("`X` must be numeric.", call. = FALSE)
  }

  if (nrow(X) < 3L || ncol(X) < 1L) {
    stop("`X` must contain at least three rows and one predictor.", call. = FALSE)
  }

  if (anyNA(X) || any(!is.finite(X))) {
    stop("`X` must contain only finite, non-missing values.", call. = FALSE)
  }

  response_type <- match.arg(response_type)
  sdr_method <- match.arg(sdr_method)
  cov_method <- match.arg(cov_method)
  stabilization <- match.arg(stabilization)
  selector <- match.arg(selector)
  weight_mode <- match.arg(weight_mode)

  if (!isTRUE(stabilize)) {
    stop(
      "Stage-3 unified thesis fitting currently requires `stabilize = TRUE`.",
      call. = FALSE
    )
  }

  if (!identical(toupper(as.character(complexity)[1L]), "C1F")) {
    stop(
      "Stage-3 unified thesis fitting currently uses C1F complexity only.",
      call. = FALSE
    )
  }

  n <- nrow(X)
  p <- ncol(X)

  if (length(y) != n) {
    stop("Length of `y` must equal nrow(`X`).", call. = FALSE)
  }

  if (anyNA(y)) {
    stop("`y` contains missing values.", call. = FALSE)
  }

  if (response_type %in% c("continuous", "survival")) {

    y <- as.numeric(y)

    if (any(!is.finite(y))) {
      stop("Numeric responses must be finite.", call. = FALSE)
    }
  }

  if (response_type == "survival") {

    if (is.null(delta)) {
      stop("For survival response, `delta` must be supplied.", call. = FALSE)
    }

    if (length(delta) != n || anyNA(delta)) {
      stop("`delta` must be complete and have length nrow(`X`).", call. = FALSE)
    }

    delta <- as.integer(delta)

    if (!all(delta %in% c(0L, 1L))) {
      stop("`delta` must contain only 0/1 values.", call. = FALSE)
    }

    if (any(y <= 0)) {
      stop("Survival times must be strictly positive.", call. = FALSE)
    }
  }

  if (sdr_method == "phd" && response_type != "continuous") {
    stop("`phd` is currently restricted to continuous responses.", call. = FALSE)
  }

  nslices <- as.integer(nslices)

  if (length(nslices) != 1L || is.na(nslices) || nslices < 1L) {
    stop("`nslices` must be a positive integer.", call. = FALSE)
  }

  d_max <- as.integer(d_max)

  if (length(d_max) != 1L || is.na(d_max) || d_max < 1L) {
    stop("`d_max` must be a positive integer.", call. = FALSE)
  }

  d_max <- min(d_max, p, n - 1L)

  requested_d <- d

  if (!is.null(d)) {

    d <- as.integer(d)

    if (length(d) != 1L || is.na(d) || d < 1L || d > d_max) {
      stop("Explicit `d` must lie between 1 and `d_max`.", call. = FALSE)
    }
  }

  lambda_grid <- sort(unique(as.numeric(lambda_grid)))

  if (
    length(lambda_grid) < 1L ||
    anyNA(lambda_grid) ||
    any(!is.finite(lambda_grid)) ||
    any(lambda_grid < 0)
  ) {
    stop("`lambda_grid` must contain finite non-negative values.", call. = FALSE)
  }

  if (length(support_penalty) != 1L || is.na(support_penalty)) {
    stop("`support_penalty` must be TRUE or FALSE.", call. = FALSE)
  }

  original_colnames <- colnames(X)

  if (is.null(original_colnames)) {
    original_colnames <- paste0("X", seq_len(p))
    colnames(X) <- original_colnames
  }

  if (
    anyNA(original_colnames) ||
    any(!nzchar(original_colnames)) ||
    anyDuplicated(original_colnames)
  ) {
    stop("Predictor names must be non-missing, non-empty, and unique.", call. = FALSE)
  }

  if (isTRUE(standardize)) {

    center <- colMeans(X)
    scale <- apply(X, 2L, stats::sd)

    bad_scale <- !is.finite(scale) | scale <= tol

    if (any(bad_scale)) {
      scale[bad_scale] <- 1
    }

    X_work <- sweep(X, 2L, center, "-")
    X_work <- sweep(X_work, 2L, scale, "/")

  } else {

    center <- rep(0, p)
    scale <- rep(1, p)
    X_work <- X
  }

  colnames(X_work) <- original_colnames

  Sigma <- estimate_cov(
    X = X_work,
    y = y,
    method = cov_method,
    nslices = nslices,
    response_type = response_type,
    delta = delta,
    cov_fun = cov_fun,
    stabilization = stabilization,
    shrinkage = shrinkage,
    eps = max(tol, 1e-8),
    ...
  )

  Sigma_raw <- Sigma

  sdr_fit <- compute_sdr(
    X = X_work,
    y = y,
    method = sdr_method,
    Sigma = Sigma,
    nslices = nslices,
    response_type = response_type,
    delta = delta,
    eps = max(tol, 1e-8)
  )

  dense_directions <- as.matrix(sdr_fit$directions)

  if (nrow(dense_directions) != p) {
    stop("Dense SDR direction matrix has unexpected row dimension.", call. = FALSE)
  }

  d_max <- min(d_max, ncol(dense_directions))

  if (!is.null(d) && d > d_max) {
    stop("Explicit `d` exceeds the available SDR directions.", call. = FALSE)
  }

  rownames(dense_directions) <- original_colnames

  sdr_center <- sdr_fit$sdr_center

  if (is.null(sdr_center)) {
    sdr_center <- colMeans(X_work)
  }

  X_score <- sweep(
    X_work,
    2L,
    sdr_center,
    "-"
  )

  if (is.null(penalty_weights)) {

    if (isTRUE(adapt_weights)) {
      penalty_weights_final <- compute_penalty_weights(
        Sigma = Sigma,
        mode = weight_mode,
        tol = tol
      )
    } else {
      penalty_weights_final <- rep(1, p)
    }

  } else {

    penalty_weights_final <- expand_penalty_weights(
      penalty_weights,
      p = p,
      normalise = TRUE,
      tol = tol
    )
  }

  names(penalty_weights_final) <- original_colnames

  candidate_dims <- seq_len(d_max)

  grid_rows <- vector(
    "list",
    length(candidate_dims) * length(lambda_grid)
  )

  fit_registry <- vector(
    "list",
    length(candidate_dims) * length(lambda_grid)
  )

  row_id <- 0L

  for (d_i in candidate_dims) {

    sparse_i <- fit_sparse_grid(
      directions = dense_directions,
      d = d_i,
      lambda_grid = lambda_grid,
      penalty_weights = penalty_weights_final,
      adapt_weights = FALSE,
      Sigma = Sigma,
      weight_mode = weight_mode,
      tol = tol
    )

    for (lambda_i in seq_along(lambda_grid)) {

      row_id <- row_id + 1L

      V_i <- as.matrix(sparse_i$fits[[lambda_i]])

      rownames(V_i) <- original_colnames
      colnames(V_i) <- paste0("RISDR_Dim", seq_len(d_i))

      Z_i <- X_score %*% V_i

      colnames(Z_i) <- paste0("Z", seq_len(d_i))

      sparsity_i <- summarise_sparsity(
        V_i,
        tol = max(tol, 1e-8)
      )

      ic_i <- tryCatch(
        compute_ic_values(
          y = y,
          Z = Z_i,
          response_type = response_type,
          delta = delta,
          n_active = sparsity_i$n_active,
          support_penalty = support_penalty,
          tol = tol
        ),
        error = function(e) e
      )

      if (inherits(ic_i, "error")) {

        crit <- c(
          AIC = Inf,
          BIC = Inf,
          CAIC = Inf,
          ICOMP = Inf,
          CICOMP = Inf,
          logLik = NA_real_,
          k_eff = NA_real_,
          C1F = NA_real_
        )

        valid <- FALSE
        error_message <- conditionMessage(ic_i)

      } else {

        crit <- ic_i
        valid <- all(
          is.finite(
            crit[c("AIC", "BIC", "CAIC", "ICOMP", "CICOMP")]
          )
        )
        error_message <- NA_character_
      }

      grid_rows[[row_id]] <- data.frame(
        d = d_i,
        lambda = lambda_grid[lambda_i],
        n_active = sparsity_i$n_active,
        active_fraction = sparsity_i$n_active / p,
        AIC = unname(crit["AIC"]),
        BIC = unname(crit["BIC"]),
        CAIC = unname(crit["CAIC"]),
        ICOMP = unname(crit["ICOMP"]),
        CICOMP = unname(crit["CICOMP"]),
        logLik = unname(crit["logLik"]),
        k_eff = unname(crit["k_eff"]),
        C1F = unname(crit["C1F"]),
        valid = valid,
        error_message = error_message,
        stringsAsFactors = FALSE
      )

      fit_registry[[row_id]] <- list(
        directions = V_i,
        scores = Z_i,
        sparsity = sparsity_i
      )
    }
  }

  selection_grid <- do.call(
    rbind,
    grid_rows
  )

  rownames(selection_grid) <- NULL

  if (!any(selection_grid$valid)) {
    stop("No valid (d, lambda) candidate could be fitted.", call. = FALSE)
  }

  criterion_names <- c(
    "AIC",
    "BIC",
    "CAIC",
    "ICOMP",
    "CICOMP"
  )

  d_table_rows <- lapply(
    candidate_dims,
    function(d_i) {

      rows_d <- which(selection_grid$d == d_i)

      out_d <- data.frame(
        d = d_i,
        AIC = Inf,
        BIC = Inf,
        CAIC = Inf,
        ICOMP = Inf,
        CICOMP = Inf,
        lambda_AIC = NA_real_,
        lambda_BIC = NA_real_,
        lambda_CAIC = NA_real_,
        lambda_ICOMP = NA_real_,
        lambda_CICOMP = NA_real_,
        stringsAsFactors = FALSE
      )

      for (criterion_i in criterion_names) {

        values_i <- selection_grid[rows_d, criterion_i]
        finite_i <- which(is.finite(values_i))

        if (length(finite_i) > 0L) {

          local_best <- finite_i[
            which.min(values_i[finite_i])
          ]

          global_best <- rows_d[local_best]

          out_d[[criterion_i]] <-
            selection_grid[[criterion_i]][global_best]

          out_d[[paste0("lambda_", criterion_i)]] <-
            selection_grid$lambda[global_best]
        }
      }

      out_d
    }
  )

  d_table <- do.call(
    rbind,
    d_table_rows
  )

  rownames(d_table) <- NULL

  selector_col <- toupper(selector)

  if (is.null(requested_d)) {

    eligible <- which(
      is.finite(selection_grid[[selector_col]])
    )

  } else {

    eligible <- which(
      selection_grid$d == d &
      is.finite(selection_grid[[selector_col]])
    )
  }

  if (length(eligible) == 0L) {
    stop("No finite candidate exists for the requested selector.", call. = FALSE)
  }

  best_index <- eligible[
    which.min(
      selection_grid[[selector_col]][eligible]
    )
  ]

  selected_d <- selection_grid$d[best_index]
  best_lambda <- selection_grid$lambda[best_index]

  selected_fit <- fit_registry[[best_index]]

  directions <- selected_fit$directions
  reduced_predictors <- selected_fit$scores
  scores <- reduced_predictors

  criterion_dimensions <- stats::setNames(
    integer(length(criterion_names)),
    criterion_names
  )

  criterion_lambdas <- stats::setNames(
    numeric(length(criterion_names)),
    criterion_names
  )

  for (criterion_i in criterion_names) {

    finite_rows <- which(
      is.finite(selection_grid[[criterion_i]])
    )

    best_i <- finite_rows[
      which.min(
        selection_grid[[criterion_i]][finite_rows]
      )
    ]

    criterion_dimensions[criterion_i] <-
      selection_grid$d[best_i]

    criterion_lambdas[criterion_i] <-
      selection_grid$lambda[best_i]
  }

  comparator_scores <- stats::setNames(
    as.numeric(
      selection_grid[
        best_index,
        criterion_names,
        drop = TRUE
      ]
    ),
    criterion_names
  )

  rows_selected_d <- which(
    selection_grid$d == selected_d
  )

  criteria_grid <- stats::setNames(
    selection_grid[[selector_col]][rows_selected_d],
    paste0(
      "lambda_",
      format(
        selection_grid$lambda[rows_selected_d],
        trim = TRUE
      )
    )
  )

  loadings <- data.frame(
    variable = original_colnames,
    directions,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  downstream_fit <- NULL

  if (response_type == "survival") {

    downstream_data <- data.frame(
      time = y,
      delta = delta,
      reduced_predictors
    )

    downstream_fit <- suppressWarnings(
      survival::coxph(
        survival::Surv(time, delta) ~ .,
        data = downstream_data,
        ties = "efron"
      )
    )

  } else if (response_type == "continuous") {

    downstream_data <- data.frame(
      y = y,
      reduced_predictors
    )

    downstream_fit <- stats::lm(
      y ~ .,
      data = downstream_data
    )

  } else {

    y_fac <- as.factor(y)

    downstream_data <- data.frame(
      y = y_fac,
      reduced_predictors
    )

    if (nlevels(y_fac) == 2L) {

      downstream_fit <- stats::glm(
        y ~ .,
        data = downstream_data,
        family = stats::binomial()
      )

    } else {

      if (!requireNamespace("nnet", quietly = TRUE)) {
        stop("Package `nnet` is required for multiclass response.", call. = FALSE)
      }

      downstream_fit <- nnet::multinom(
        y ~ .,
        data = downstream_data,
        trace = FALSE
      )
    }
  }

  out <- list(
    call = match.call(),
    X = X,
    y = y,
    delta = delta,
    X_work = X_work,
    center = center,
    scale = scale,
    standardize = standardize,
    response_type = response_type,
    sdr_method = sdr_method,
    cov_method = cov_method,
    stabilize = stabilize,
    stabilization = stabilization,
    Sigma_raw = Sigma_raw,
    Sigma = Sigma,
    covariance = Sigma,
    kernel = sdr_fit$kernel,
    eigenvalues = sdr_fit$eigenvalues,
    dense_directions = dense_directions,
    directions = directions,
    z_directions = sdr_fit$z_directions,
    scores = scores,
    reduced_predictors = reduced_predictors,
    slices = sdr_fit$slices,
    slice_metadata = sdr_fit$slice_metadata,
    nslices = nslices,
    requested_d = requested_d,
    d = selected_d,
    d_max = d_max,
    d_candidates = candidate_dims,
    d_table = d_table,
    selector = selector,
    selection_grid = selection_grid,
    lambda_grid = lambda_grid,
    best_lambda = best_lambda,
    criteria_grid = criteria_grid,
    comparator_scores = comparator_scores,
    criterion_dimensions = criterion_dimensions,
    criterion_lambdas = criterion_lambdas,
    penalty_weights = penalty_weights_final,
    adapt_weights = adapt_weights,
    weight_mode = weight_mode,
    support_penalty = support_penalty,
    complexity = "C1F",
    selected_sparsity = selected_fit$sparsity,
    downstream_fit = downstream_fit,
    sdr_center = sdr_center,
    loadings = loadings
  )

  class(out) <- "risdr"

  out
}


#' Extract SDR loadings
#'
#' @param directions Matrix of SDR directions.
#' @param variables Variable names.
#'
#' @return A data frame of loadings.
#' @export
extract_loadings <- function(directions, variables = NULL) {

  directions <- as.matrix(directions)

  if (is.null(variables)) {
    variables <- paste0("X", seq_len(nrow(directions)))
  }

  if (length(variables) != nrow(directions)) {
    stop("Length of `variables` must equal number of rows in `directions`.", call. = FALSE)
  }

  out <- data.frame(
    Variable = variables,
    directions,
    check.names = FALSE
  )

  names(out)[-1] <- paste0("Direction_", seq_len(ncol(directions)))

  out
}


#' Print risdr object
#'
#' @param x Object of class "risdr".
#' @param ... Additional arguments passed to internal methods.
#'
#' @return Invisibly returns x.
#' @param ... Additional arguments passed to internal methods.
#' @export
print.risdr <- function(x, ...) {

  cat("Regularised and Information-Theoretic SDR fit\n")
  cat("--------------------------------------------------\n")
  cat("SDR method       :", toupper(x$sdr_method), "\n")
  cat("Covariance       :", toupper(x$cov_method), "\n")
  cat("Stabilised       :", x$stabilize, "\n")
  cat("Stabilisation    :", x$stabilization, "\n")
  cat("Selected d       :", x$d, "\n")
  cat("Selector         :", toupper(x$selector), "\n")
  cat("Number of slices :", x$nslices, "\n")
  cat("Observations     :", nrow(x$X), "\n")
  cat("Predictors       :", ncol(x$X), "\n")

  invisible(x)
}


#' Summarise risdr object
#'
#' @param object Object of class "risdr".
#'
#' @return A list summary.
#' @param ... Additional arguments passed to internal methods.
#' @export
summary.risdr <- function(object, ...) {

  out <- list(
    method = object$sdr_method,
    covariance = object$cov_method,
    selected_dimension = object$d,
    selector = object$selector,
    eigenvalues = head(object$eigenvalues, 10),
    dimension_table = object$d_table,
    covariance_diagnostics = cov_diagnostics(object$Sigma)
  )

  class(out) <- "summary.risdr"

  out
}


#' Print summary of risdr object
#'
#' @param x Object of class "summary.risdr".
#' @param ...
#'
#' @return Invisibly returns x.
#' @param ... Additional arguments passed to internal methods.
#' @export
print.summary.risdr <- function(x, ...) {

  cat("Summary of risdr fit\n")
  cat("--------------------------------------------------\n")
  cat("Method              :", toupper(x$method), "\n")
  cat("Covariance          :", toupper(x$covariance), "\n")
  cat("Selected dimension  :", x$selected_dimension, "\n")
  cat("Selector            :", toupper(x$selector), "\n\n")

  cat("Leading eigenvalues:\n")
  print(x$eigenvalues)

  cat("\nDimension selection table:\n")
  print(x$dimension_table)

  cat("\nCovariance diagnostics:\n")
  print(x$covariance_diagnostics[1:4])

  invisible(x)
}


#' Predict method for risdr objects
#'
#' @param object Object of class "risdr".
#' @param newX New predictor matrix or data frame.
#' @param d Optional structural dimension.
#' @param ...
#'
#' @return Numeric vector of predictions.
#' @param ... Additional arguments passed to internal methods.
#' @export
predict.risdr <- function(object, newX, d = NULL, ...) {

  if (!inherits(object, "risdr")) {
    stop("`object` must be of class 'risdr'.", call. = FALSE)
  }

  newX <- check_X(newX)

  if (ncol(newX) != ncol(object$X)) {
    stop("`newX` must have the same number of columns as the training X.", call. = FALSE)
  }

  colnames(newX) <- colnames(object$X)

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

  scores_new <- compute_scores(
    newX = newX_sdr_centered,
    directions = object$directions
  )

  if (is.null(d)) {
    d <- object$d
  }

  predict_downstream_lm(
    fit_lm = object$downstream_fit,
    scores_new = scores_new,
    d = d
  )
}
