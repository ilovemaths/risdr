# ============================================================
# R/survival_slicing.R
# Survival-aware response slicing for inverse regression
# ============================================================

#' Slice response for inverse regression
#'
#' Constructs slice labels for continuous, categorical, or censored survival
#' responses. For censored survival data, double slicing is used by first
#' splitting on censoring status and then slicing observed time within each
#' status group.
#'
#' @param y Response vector. For survival data, observed time.
#' @param nslices Number of slices for continuous data or per censoring-status
#'   group for survival data.
#' @param response_type One of `"continuous"`, `"categorical"`, or
#'   `"survival"`.
#' @param delta Optional 0/1 event indicator for survival data.
#' @return A list containing integer slice labels and metadata.
#' @export
slice_response <- function(
    y,
    nslices = 5L,
    response_type = c("continuous", "categorical", "survival"),
    delta = NULL
) {

  response_type <- match.arg(response_type)

  if (length(nslices) != 1L || is.na(nslices) || nslices < 1L) {
    stop("`nslices` must be a positive integer.", call. = FALSE)
  }

  nslices <- as.integer(nslices)

  if (response_type == "continuous") {

    if (!is.numeric(y)) {
      stop("For continuous response, `y` must be numeric.", call. = FALSE)
    }

    if (anyNA(y)) {
      stop("`y` contains missing values.", call. = FALSE)
    }

    probs <- seq(0, 1, length.out = nslices + 1L)

    brks <- unique(
      stats::quantile(
        y,
        probs = probs,
        na.rm = TRUE,
        type = 7
      )
    )

    if (length(brks) <= 2L) {
      groups <- rep(1L, length(y))
    } else {
      groups <- cut(
        y,
        breaks = brks,
        include.lowest = TRUE,
        labels = FALSE
      )
    }

    groups <- as.integer(groups)

    return(
      list(
        groups = groups,
        nslices = length(unique(groups)),
        labels = sort(unique(groups)),
        response_type = "continuous",
        requested_nslices = nslices
      )
    )
  }

  if (response_type == "categorical") {

    if (anyNA(y)) {
      stop("`y` contains missing values.", call. = FALSE)
    }

    groups <- as.integer(as.factor(y))

    return(
      list(
        groups = groups,
        nslices = length(unique(groups)),
        labels = sort(unique(groups)),
        response_type = "categorical",
        requested_nslices = nslices
      )
    )
  }

  if (!is.numeric(y)) {
    stop("For survival response, observed time `y` must be numeric.", call. = FALSE)
  }

  if (is.null(delta)) {
    stop("For survival response, `delta` must be supplied.", call. = FALSE)
  }

  if (length(delta) != length(y)) {
    stop("`delta` must have the same length as `y`.", call. = FALSE)
  }

  if (anyNA(y) || anyNA(delta)) {
    stop("Survival time and `delta` must be complete before slicing.", call. = FALSE)
  }

  if (any(!is.finite(y)) || any(y <= 0)) {
    stop("Survival times must be finite and strictly positive.", call. = FALSE)
  }

  delta <- as.integer(delta)

  if (!all(delta %in% c(0L, 1L))) {
    stop("`delta` must contain only 0/1 values.", call. = FALSE)
  }

  groups <- integer(length(y))
  current_label <- 1L

  for (status in c(0L, 1L)) {

    idx <- which(delta == status)

    if (length(idx) == 0L) {
      next
    }

    y_sub <- y[idx]

    probs <- seq(0, 1, length.out = nslices + 1L)

    brks <- unique(
      stats::quantile(
        y_sub,
        probs = probs,
        na.rm = TRUE,
        type = 7
      )
    )

    if (length(brks) <= 2L) {

      groups[idx] <- current_label
      current_label <- current_label + 1L

    } else {

      raw_groups <- cut(
        y_sub,
        breaks = brks,
        include.lowest = TRUE,
        labels = FALSE
      )

      uniq <- sort(unique(raw_groups))

      relabel <- match(raw_groups, uniq) + current_label - 1L

      groups[idx] <- relabel
      current_label <- max(relabel) + 1L
    }
  }

  list(
    groups = groups,
    nslices = length(unique(groups)),
    labels = sort(unique(groups)),
    response_type = "survival",
    requested_nslices = nslices,
    status_counts = table(delta)
  )
}
