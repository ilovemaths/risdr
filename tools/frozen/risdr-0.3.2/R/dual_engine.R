# ============================================================
# R/dual_engine.R
# Dual high-dimensional RISDR engine
# ============================================================

#' Dual PCA score construction for p much larger than n
#'
#' Constructs low-rank sample-space scores without forming a p by p covariance
#' matrix. This is useful when the number of predictors is very large.
#'
#' @param X Numeric predictor matrix with observations in rows.
#' @param dual_rank Number of dual components to retain.
#' @param variance_explained Optional cumulative variance threshold.
#' @param center Logical; if TRUE, centre predictors.
#' @param scale_X Logical; if TRUE, scale predictors.
#' @param eps Numerical tolerance.
#'
#' @return A list containing scores, loadings, singular values, centre, scale,
#'   and retained rank.
#' @export
dual_pca_scores <- function(
    X,
    dual_rank = NULL,
    variance_explained = NULL,
    center = TRUE,
    scale_X = TRUE,
    eps = 1e-10
) {

  X <- as.matrix(X)

  if (!is.numeric(X)) {
    stop("`X` must be numeric.", call. = FALSE)
  }

  n <- nrow(X)
  p <- ncol(X)

  x_center <- if (center) colMeans(X, na.rm = TRUE) else rep(0, p)

  Xc <- sweep(X, 2, x_center, "-")

  x_scale <- rep(1, p)

  if (scale_X) {
    x_scale <- apply(Xc, 2, stats::sd, na.rm = TRUE)
    x_scale[!is.finite(x_scale) | x_scale < eps] <- 1
    Xc <- sweep(Xc, 2, x_scale, "/")
  }

  # Work in sample space: n by n, not p by p.
  G <- tcrossprod(Xc) / max(1, n - 1)
  G <- (G + t(G)) / 2

  eig <- eigen(G, symmetric = TRUE)

  values <- pmax(eig$values, 0)
  positive <- which(values > eps)

  if (length(positive) == 0L) {
    stop("No positive dual eigenvalues found.", call. = FALSE)
  }

  values <- values[positive]
  U <- eig$vectors[, positive, drop = FALSE]

  if (!is.null(variance_explained)) {
    if (variance_explained <= 0 || variance_explained > 1) {
      stop("`variance_explained` must be in (0, 1].", call. = FALSE)
    }

    cumvar <- cumsum(values) / sum(values)
    dual_rank <- which(cumvar >= variance_explained)[1]
  }

  if (is.null(dual_rank)) {
    dual_rank <- min(100L, length(values))
  }

  dual_rank <- min(as.integer(dual_rank), length(values), n - 1L)

  values_r <- values[seq_len(dual_rank)]
  U_r <- U[, seq_len(dual_rank), drop = FALSE]

  singular_values <- sqrt(values_r * max(1, n - 1))

  scores <- U_r %*% diag(singular_values, nrow = dual_rank)

  # Predictor-space loadings are computed by multiplication, not p by p eigen.
  loadings <- t(Xc) %*% U_r %*% diag(1 / pmax(singular_values, eps), nrow = dual_rank)

  rownames(loadings) <- colnames(X)
  colnames(loadings) <- paste0("DualComp", seq_len(dual_rank))
  colnames(scores) <- paste0("DualComp", seq_len(dual_rank))
  rownames(scores) <- rownames(X)

  list(
    scores = scores,
    loadings = loadings,
    singular_values = singular_values,
    eigenvalues = values_r,
    center = x_center,
    scale = x_scale,
    dual_rank = dual_rank
  )
}


#' Fit dual high-dimensional RISDR
#'
#' Constructs a low-rank PCA score representation, fits the unified RISDR
#' core in that score space, maps the dense and selected sparse SDR directions
#' back to the original predictor coordinates, and ranks variables using the
#' Euclidean loading norm across only the selected sparse directions.
#'
#' The inner RISDR standardisation scale is explicitly undone before mapping
#' directions through the PCA loadings. The returned reduced predictors are
#' taken directly from the fitted core and are therefore exactly aligned with
#' the model used for information-criterion selection.
#'
#' @param X Numeric high-dimensional predictor matrix.
#' @param y Response vector. For survival data, observed time.
#' @param delta Optional 0/1 event indicator.
#' @param response_type One of `"continuous"`, `"categorical"`, or
#'   `"survival"`.
#' @param dual_rank Maximum retained PCA rank.
#' @param variance_explained Optional cumulative variance threshold.
#' @param d Optional fixed structural dimension. If `NULL`, selected by
#'   `selector`.
#' @param d_max Maximum candidate structural dimension.
#' @param nslices Number of slices, or slices per censoring-status group.
#' @param sdr_method SDR method.
#' @param cov_method Covariance method.
#' @param selector Information criterion used to select `(d, lambda)`.
#' @param lambda_grid Sparsity tuning grid.
#' @param adapt_weights Logical. Use adaptive penalty weights.
#' @param weight_mode Adaptive weighting mode.
#' @param support_penalty Logical. Include active support in criterion df.
#' @param standardize_dual Logical. Standardise retained PCA scores inside
#'   [fit_risdr()].
#' @param gene_select_top Optional number of top-ranked variables.
#' @param gene_select_quantile Quantile used when `gene_select_top` is NULL.
#' @param center Logical. Centre predictors before dual PCA.
#' @param scale_X Logical. Scale predictors before dual PCA.
#' @param verbose Logical. Emit progress messages.
#' @param ... Additional arguments passed to [fit_risdr()].
#' @return An object of class `risdr_dual`.
#' @export
fit_risdr_dual <- function(
    X,
    y,
    delta = NULL,
    response_type = c("continuous", "categorical", "survival"),
    dual_rank = 100L,
    variance_explained = NULL,
    d = NULL,
    d_max = 10L,
    nslices = 4L,
    sdr_method = c("dr", "sir", "save", "phd"),
    cov_method = c("mec", "oas", "lw", "sample", "ridge"),
    selector = c("cicomp", "icomp", "aic", "caic", "bic"),
    lambda_grid = seq(0, 0.30, length.out = 10L),
    adapt_weights = TRUE,
    weight_mode = c("c1f", "inverse_c1f", "uniform"),
    support_penalty = FALSE,
    standardize_dual = TRUE,
    gene_select_top = NULL,
    gene_select_quantile = 0.99,
    center = TRUE,
    scale_X = TRUE,
    verbose = TRUE,
    ...
) {

  response_type <- match.arg(response_type)
  sdr_method <- match.arg(sdr_method)
  cov_method <- match.arg(cov_method)
  selector <- match.arg(selector)
  weight_mode <- match.arg(weight_mode)

  X <- as.matrix(X)

  if (!is.numeric(X)) {
    stop("`X` must be numeric.", call. = FALSE)
  }

  if (length(y) != nrow(X)) {
    stop("Length of `y` must equal nrow(`X`).", call. = FALSE)
  }

  gene_names <- colnames(X)

  if (
    is.null(gene_names) ||
    anyNA(gene_names) ||
    any(!nzchar(gene_names)) ||
    anyDuplicated(gene_names)
  ) {
    stop(
      "Dual RISDR requires non-missing, non-empty, unique predictor names.",
      call. = FALSE
    )
  }

  if (response_type == "survival" && is.null(delta)) {
    stop("`delta` must be supplied for survival response.", call. = FALSE)
  }

  if (!is.null(gene_select_top)) {

    gene_select_top <- as.integer(gene_select_top)

    if (
      length(gene_select_top) != 1L ||
      is.na(gene_select_top) ||
      gene_select_top < 1L
    ) {
      stop("`gene_select_top` must be a positive integer.", call. = FALSE)
    }
  }

  if (
    !is.numeric(gene_select_quantile) ||
    length(gene_select_quantile) != 1L ||
    is.na(gene_select_quantile) ||
    gene_select_quantile < 0 ||
    gene_select_quantile > 1
  ) {
    stop("`gene_select_quantile` must lie in [0, 1].", call. = FALSE)
  }

  if (verbose) {
    message(
      "[fit_risdr_dual] Step 1/6: removing incomplete outcome records..."
    )
  }

  keep <- stats::complete.cases(y)

  if (!is.null(delta)) {
    keep <- keep & stats::complete.cases(delta)
  }

  X <- X[
    keep,
    ,
    drop = FALSE
  ]

  y <- y[keep]

  if (!is.null(delta)) {
    delta <- delta[keep]
  }

  if (nrow(X) < 3L) {
    stop("Too few complete outcome records remain.", call. = FALSE)
  }

  if (verbose) {
    message(
      "[fit_risdr_dual] Data dimensions after cleaning: n = ",
      nrow(X),
      ", p = ",
      ncol(X)
    )
  }

  if (verbose) {
    message(
      "[fit_risdr_dual] Step 2/6: constructing dual PCA scores..."
    )
  }

  dual <- dual_pca_scores(
    X = X,
    dual_rank = dual_rank,
    variance_explained = variance_explained,
    center = center,
    scale_X = scale_X
  )

  if (verbose) {
    message(
      "[fit_risdr_dual] Retained dual rank: ",
      dual$dual_rank
    )
  }

  if (verbose) {
    message(
      "[fit_risdr_dual] Step 3/6: fitting RISDR in dual score space..."
    )
  }

  fit_dual <- fit_risdr(
    X = dual$scores,
    y = y,
    delta = delta,
    response_type = response_type,
    d = d,
    d_max = d_max,
    nslices = nslices,
    sdr_method = sdr_method,
    cov_method = cov_method,
    selector = selector,
    lambda_grid = lambda_grid,
    adapt_weights = adapt_weights,
    weight_mode = weight_mode,
    support_penalty = support_penalty,
    standardize = standardize_dual,
    ...
  )

  selected_d <- as.integer(
    fit_dual$d
  )

  if (
    length(selected_d) != 1L ||
    is.na(selected_d) ||
    selected_d < 1L ||
    selected_d > ncol(fit_dual$directions)
  ) {
    stop(
      "Invalid selected structural dimension returned by fit_risdr(): ",
      fit_dual$d,
      call. = FALSE
    )
  }

  if (verbose) {
    message(
      "[fit_risdr_dual] Step 4/6: mapping dual directions back to gene space..."
    )
  }

  B_selected_work <- as.matrix(
    fit_dual$directions
  )

  B_dense_work <- as.matrix(
    fit_dual$dense_directions
  )

  inner_scale <- if (
    isTRUE(fit_dual$standardize)
  ) {
    as.numeric(fit_dual$scale)
  } else {
    rep(1, nrow(B_selected_work))
  }

  if (
    length(inner_scale) != nrow(B_selected_work) ||
    any(!is.finite(inner_scale)) ||
    any(inner_scale <= 0)
  ) {
    stop(
      "Inner RISDR standardisation scale does not align with dual directions.",
      call. = FALSE
    )
  }

  B_selected_dual_input <- sweep(
    B_selected_work,
    1L,
    inner_scale,
    "/"
  )

  B_dense_dual_input <- sweep(
    B_dense_work,
    1L,
    inner_scale,
    "/"
  )

  gene_directions <-
    dual$loadings %*%
    B_dense_dual_input

  selected_gene_directions <-
    dual$loadings %*%
    B_selected_dual_input

  rownames(gene_directions) <- gene_names
  rownames(selected_gene_directions) <- gene_names

  colnames(gene_directions) <- paste0(
    "RISDR_DenseDim",
    seq_len(ncol(gene_directions))
  )

  colnames(selected_gene_directions) <- paste0(
    "RISDR_Dim",
    seq_len(selected_d)
  )

  if (verbose) {
    message(
      "[fit_risdr_dual] Step 5/6: ranking genes by selected sparse-direction norm..."
    )
  }

  loading_norm <- sqrt(
    rowSums(
      selected_gene_directions^2
    )
  )

  if (!is.null(gene_select_top)) {

    selected_idx <- order(
      loading_norm,
      decreasing = TRUE
    )[
      seq_len(
        min(
          gene_select_top,
          length(loading_norm)
        )
      )
    ]

  } else {

    cutoff <- stats::quantile(
      loading_norm,
      probs = gene_select_quantile,
      na.rm = TRUE
    )

    selected_idx <- which(
      loading_norm >= cutoff
    )
  }

  selected_variables <- data.frame(
    index = selected_idx,
    variable = gene_names[selected_idx],
    loading_norm = loading_norm[selected_idx],
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
    fit_dual$reduced_predictors
  )

  if (
    nrow(reduced_predictors) != nrow(X) ||
    ncol(reduced_predictors) != selected_d
  ) {
    stop(
      "Dual core reduced predictors have unexpected dimensions.",
      call. = FALSE
    )
  }

  if (verbose) {
    message(
      "[fit_risdr_dual] Step 6/6: dual RISDR fit completed."
    )
  }

  out <- list(
    call = match.call(),
    fit_dual = fit_dual,
    dual = dual,
    response_type = response_type,
    requested_d = d,
    d = selected_d,
    d_max = fit_dual$d_max,
    best_lambda = fit_dual$best_lambda,
    dual_rank = dual$dual_rank,
    dense_dual_directions_input_scale = B_dense_dual_input,
    selected_dual_directions_input_scale = B_selected_dual_input,
    gene_directions = gene_directions,
    selected_gene_directions = selected_gene_directions,
    gene_direction_scale = if (isTRUE(scale_X)) {
      "dual-PCA standardised predictor coordinates"
    } else {
      "dual-PCA centred predictor coordinates"
    },
    selected_variables = selected_variables,
    reduced_predictors = reduced_predictors,
    y = y,
    delta = delta,
    kept_rows = keep,
    gene_select_top = gene_select_top,
    gene_select_quantile = gene_select_quantile,
    standardize_dual = standardize_dual,
    center = center,
    scale_X = scale_X
  )

  class(out) <- "risdr_dual"

  out
}

#' Print method for dual RISDR objects
#'
#' @param x Object of class `risdr_dual`.
#' @param ... Additional arguments passed to internal methods.
#'
#' @export
print.risdr_dual <- function(x, ...) {

  cat("\nDual high-dimensional RISDR fit\n")
  cat("--------------------------------\n")
  cat("Response type       :", x$response_type, "\n")
  cat("Dual rank retained  :", x$dual_rank, "\n")
  cat("Structural dimension:", x$d, "\n")
  cat("Selected variables  :", nrow(x$selected_variables), "\n")
  cat("Selected dimension  :", x$fit_dual$d, "\n")
  cat("Selection criterion :", x$fit_dual$selector, "\n")

  invisible(x)
}


#' Summary method for dual RISDR objects
#'
#' @param object Object of class `risdr_dual`.
#' @param top_n Number of selected variables to print.
#' @param ... Additional arguments passed to internal methods.
#'
#' @export
summary.risdr_dual <- function(object, top_n = 20L, ...) {

  print(object)

  cat("\nTop selected variables\n")
  print(utils::head(object$selected_variables, top_n))

  cat("\nDual-space model summary\n")
  print(summary(object$fit_dual))

  invisible(object)
}
