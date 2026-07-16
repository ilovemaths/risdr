# ============================================================
# R/plots.R
# Diagnostic plotting functions for risdr
# ============================================================


#' Scree plot of SDR eigenvalues
#'
#' @param fit Object of class "risdr".
#' @param n_eigen Number of eigenvalues to display.
#' @param type Plot type passed to base R plot().
#' @param ... Additional graphical arguments passed to [graphics::plot()].
#'
#' @return Invisibly returns eigenvalues plotted.
#' @export
plot_scree <- function(fit, n_eigen = 20, type = "b", ...) {

  if (!inherits(fit, "risdr")) {
    stop("`fit` must be an object of class 'risdr'.", call. = FALSE)
  }

  values <- fit$eigenvalues
  n_eigen <- min(n_eigen, length(values))

  plot(
    seq_len(n_eigen),
    values[seq_len(n_eigen)],
    type = type,
    pch = 19,
    xlab = "Component index",
    ylab = "Eigenvalue",
    main = paste0("Scree Plot: ", toupper(fit$sdr_method)),
    ...
  )

  invisible(values[seq_len(n_eigen)])
}


#' Sufficient summary plot
#'
#' Plots the response against a selected SDR direction.
#'
#' @param fit Object of class "risdr".
#' @param direction SDR direction to plot.
#' @param ... Additional graphical arguments passed to [graphics::plot()].
#'
#' @return Invisibly returns plotted data.
#' @export
plot_sufficient <- function(fit, direction = 1, ...) {

  if (!inherits(fit, "risdr")) {
    stop("`fit` must be an object of class 'risdr'.", call. = FALSE)
  }

  if (!is.numeric(direction) || length(direction) != 1 ||
      direction < 1 || direction > ncol(fit$scores)) {
    stop("`direction` must be a valid SDR direction index.", call. = FALSE)
  }

  direction <- as.integer(direction)

  x <- fit$scores[, direction]
  y <- fit$y

  plot(
    x,
    y,
    pch = 19,
    xlab = paste0("SDR Direction ", direction),
    ylab = "Response",
    main = paste0("Sufficient Summary Plot: Direction ", direction),
    ...
  )

  invisible(data.frame(direction_score = x, response = y))
}


#' Two-direction sufficient summary plot
#'
#' Plots the first two selected SDR scores, optionally coloured by response.
#'
#' @param fit Object of class "risdr".
#' @param directions Integer vector of length 2.
#' @param colour_by_y Logical. If TRUE, colours points by response quantile group.
#' @param groups Number of response colour groups.
#' @param ... Additional graphical arguments passed to [graphics::plot()].
#'
#' @return Invisibly returns plotted data.
#' @export
plot_sufficient2d <- function(
    fit,
    directions = c(1, 2),
    colour_by_y = TRUE,
    groups = 4,
    ...
) {

  if (!inherits(fit, "risdr")) {
    stop("`fit` must be an object of class 'risdr'.", call. = FALSE)
  }

  if (length(directions) != 2) {
    stop("`directions` must be an integer vector of length 2.", call. = FALSE)
  }

  colour_by_y <- check_flag(colour_by_y, "colour_by_y")
  directions <- as.integer(directions)

  if (any(directions < 1) || any(directions > ncol(fit$scores))) {
    stop("Requested directions exceed the available SDR scores.", call. = FALSE)
  }

  x <- fit$scores[, directions[1]]
  y <- fit$scores[, directions[2]]

  if (colour_by_y) {
    group_id <- make_slices(fit$y, nslices = groups)
    plot_col <- group_id
  } else {
    plot_col <- 1
  }

  plot(
    x,
    y,
    pch = 19,
    col = plot_col,
    xlab = paste0("SDR Direction ", directions[1]),
    ylab = paste0("SDR Direction ", directions[2]),
    main = paste0("Two-Direction SDR Plot: ", toupper(fit$sdr_method)),
    ...
  )

  invisible(
    data.frame(
      direction_1 = x,
      direction_2 = y,
      response = fit$y
    )
  )
}


#' Plot SDR loadings
#'
#' Displays the largest absolute loadings for a selected SDR direction.
#'
#' @param fit Object of class "risdr".
#' @param direction Direction index.
#' @param top Number of variables to display.
#' @param ... Additional graphical arguments passed to [graphics::barplot()].
#'
#' @return Invisibly returns loading table.
#' @export
plot_loadings <- function(fit, direction = 1, top = 15, ...) {

  if (!inherits(fit, "risdr")) {
    stop("`fit` must be an object of class 'risdr'.", call. = FALSE)
  }

  if (!is.numeric(direction) || length(direction) != 1 ||
      direction < 1 || direction > ncol(fit$directions)) {
    stop("`direction` must be a valid direction index.", call. = FALSE)
  }

  direction <- as.integer(direction)

  load <- data.frame(
    Variable = rownames_or_names(fit$directions, fallback = colnames(fit$X)),
    Loading = fit$directions[, direction]
  )

  load$AbsLoading <- abs(load$Loading)
  load <- load[order(load$AbsLoading, decreasing = TRUE), , drop = FALSE]

  top <- min(top, nrow(load))
  load_top <- load[seq_len(top), , drop = FALSE]

  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))

  par(mar = c(5, 8, 4, 2))

  barplot(
    rev(load_top$Loading),
    names.arg = rev(load_top$Variable),
    horiz = TRUE,
    las = 1,
    xlab = "Loading",
    main = paste0("Top Loadings: Direction ", direction),
    ...
  )

  invisible(load)
}


#' Prediction plot
#'
#' Plots observed versus predicted values.
#'
#' @param y_true Observed response values.
#' @param y_pred Predicted response values.
#' @param ... Additional graphical arguments passed to [graphics::plot()].
#'
#' @return Invisibly returns plotted data.
#' @export
plot_prediction <- function(y_true, y_pred, ...) {

  check_prediction_vectors(y_true, y_pred)

  plot(
    y_true,
    y_pred,
    pch = 19,
    xlab = "Observed",
    ylab = "Predicted",
    main = "Observed versus Predicted Values",
    ...
  )

  abline(0, 1, lty = 2)

  invisible(data.frame(observed = y_true, predicted = y_pred))
}


#' Residual plot
#'
#' Plots residuals against predicted values.
#'
#' @param y_true Observed response values.
#' @param y_pred Predicted response values.
#' @param ... Additional graphical arguments passed to [graphics::plot()].
#'
#' @return Invisibly returns plotted data.
#' @export
plot_residuals <- function(y_true, y_pred, ...) {

  check_prediction_vectors(y_true, y_pred)

  residuals <- y_true - y_pred

  plot(
    y_pred,
    residuals,
    pch = 19,
    xlab = "Predicted",
    ylab = "Residual",
    main = "Residual Plot",
    ...
  )

  abline(h = 0, lty = 2)

  invisible(data.frame(predicted = y_pred, residuals = residuals))
}


#' Plot dimension selection criteria
#'
#' @param fit Object of class "risdr".
#' @param criteria Character vector of criteria to plot.
#' @param ... Additional graphical arguments passed to [graphics::matplot()].
#'
#' @return Invisibly returns dimension table.
#' @export
plot_dimension_selection <- function(
    fit,
    criteria = c("AIC", "BIC", "CAIC", "ICOMP", "CICOMP"),
    ...
) {

  if (!inherits(fit, "risdr")) {
    stop("`fit` must be an object of class 'risdr'.", call. = FALSE)
  }

  dtab <- fit$d_table

  criteria <- intersect(criteria, names(dtab))

  if (length(criteria) == 0) {
    stop("No valid criteria found in `fit$d_table`.", call. = FALSE)
  }

  mat <- as.matrix(dtab[, criteria, drop = FALSE])

  matplot(
    dtab$d,
    mat,
    type = "b",
    pch = seq_along(criteria),
    lty = seq_along(criteria),
    xlab = "Structural dimension (d)",
    ylab = "Criterion value",
    main = "Structural Dimension Selection",
    ...
  )

  legend(
    "topright",
    legend = criteria,
    pch = seq_along(criteria),
    lty = seq_along(criteria),
    bty = "n"
  )

  invisible(dtab)
}


#' Helper for row names or fallback names
#'
#' @param x Matrix.
#' @param fallback Fallback names.
#'
#' @return Character vector.
#' @keywords internal
rownames_or_names <- function(x, fallback = NULL) {

  rn <- rownames(x)

  if (!is.null(rn)) {
    return(rn)
  }

  if (!is.null(fallback)) {
    return(fallback)
  }

  paste0("X", seq_len(nrow(x)))
}
