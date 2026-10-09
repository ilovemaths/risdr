# Run from the package root, after loading the candidate installation.
library(risdr)
e <- new.env(parent = baseenv())
for (file in list.files("tools/frozen/risdr-0.3.2/R", pattern = "\\.R$", full.names = TRUE))
  sys.source(file, e)
generator <- readLines("tools/generate-thesis-engine.R")
last_definition <- grep("^doc_text <-", generator)[1L] - 1L
eval(parse(text = generator[seq_len(last_definition)]))
reverse <- setNames(names(mapping), unname(mapping))
restore <- function(x) {
  if (is.symbol(x)) {
    key <- as.character(x)
    return(if (key %in% names(reverse)) as.name(reverse[[key]]) else x)
  }
  if (is.character(x) && length(x) == 1L && x %in% unname(class_mapping))
    return(names(class_mapping)[match(x, class_mapping)])
  if (is.call(x)) {
    head <- if (is.symbol(x[[1L]])) as.character(x[[1L]]) else ""
    if (head %in% c("::", ":::")) return(x)
    if (head %in% c("$", "@")) {x[[2L]] <- restore(x[[2L]]); return(x)}
  }
  if (is.call(x) || is.pairlist(x))
    for (i in seq_along(x)) if (!is.null(x[[i]]) && !identical(x[[i]], quote(expr = ))) x[[i]] <- restore(x[[i]])
  x
}
for (name in names(mapping)) {
  original <- get(name, e)
  packaged <- get(mapping[[name]], asNamespace("risdr"))
  stopifnot(identical(formals(original), restore(formals(packaged))))
  stopifnot(identical(body(original), restore(body(packaged))))
}
cat("PASS: all", length(mapping), "frozen function bodies and formals match after name/class restoration.\n")
# Numerical fixtures compare both screened and dual selected fits.
set.seed(20260828)
X <- matrix(rnorm(100 * 12), 100); colnames(X) <- paste0("G", 1:12)
time <- exp(1 + 0.4 * X[, 1] + rnorm(100, sd = 0.5))
delta <- as.integer(X[, 1] + rnorm(100) > 0)
args <- list(X = X, y = time, delta = delta, response_type = "survival",
             sdr_method = "sir", cov_method = "oas", d_max = 3,
             lambda_grid = c(0, 0.05, 0.1))
for (pair in list(c("fit_risdr", "fit_risdr_sparse"),
                  c("fit_risdr_realdata", "fit_risdr_sparse_realdata"),
                  c("fit_risdr_dual", "fit_risdr_dual"))) {
  use_args <- args
  if (pair[1] == "fit_risdr_dual") use_args <- c(args, list(dual_rank = 6, verbose = FALSE))
  # Frozen functions resolve against their own private, unmodified source environment.
  original <- do.call(get(pair[1], e), use_args)
  packaged <- do.call(get(pair[2], asNamespace("risdr")), use_args)
  get_core <- function(x) if (!is.null(x$fit_dual)) x$fit_dual else if (!is.null(x$fit)) x$fit else x
  a <- get_core(original); b <- get_core(packaged)
  for (field in c("selection_grid", "directions", "reduced_predictors", "best_lambda", "d"))
    stopifnot(isTRUE(all.equal(a[[field]], b[[field]], tolerance = 1e-12)))
  if (!is.null(original$selected_variables))
    stopifnot(isTRUE(all.equal(original$selected_variables, packaged$selected_variables, tolerance = 1e-12)))
}
cat("PASS: sparse, screened, and dual synthetic results reproduce frozen source to 1e-12.\n")
