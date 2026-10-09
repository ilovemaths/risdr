# Fit dual high-dimensional RISDR

Constructs a low-rank PCA score representation, fits the unified RISDR
core in that score space, maps the dense and selected sparse SDR
directions back to the original predictor coordinates, and ranks
variables using the Euclidean loading norm across only the selected
sparse directions.

## Usage

``` r
fit_risdr_dual(
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
  lambda_grid = seq(0, 0.3, length.out = 10L),
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
)
```

## Arguments

- X:

  Numeric high-dimensional predictor matrix.

- y:

  Response vector. For survival data, observed time.

- delta:

  Optional 0/1 event indicator.

- response_type:

  One of `"continuous"`, `"categorical"`, or `"survival"`.

- dual_rank:

  Maximum retained PCA rank.

- variance_explained:

  Optional cumulative variance threshold.

- d:

  Optional fixed structural dimension. If `NULL`, selected by
  `selector`.

- d_max:

  Maximum candidate structural dimension.

- nslices:

  Number of slices, or slices per censoring-status group.

- sdr_method:

  SDR method.

- cov_method:

  Covariance method.

- selector:

  Information criterion used to select `(d, lambda)`.

- lambda_grid:

  Sparsity tuning grid.

- adapt_weights:

  Logical. Use adaptive penalty weights.

- weight_mode:

  Adaptive weighting mode.

- support_penalty:

  Logical. Include active support in criterion df.

- standardize_dual:

  Logical. Standardise retained PCA scores inside
  [`fit_risdr_sparse()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse.md).

- gene_select_top:

  Optional number of top-ranked variables.

- gene_select_quantile:

  Quantile used when `gene_select_top` is NULL.

- center:

  Logical. Centre predictors before dual PCA.

- scale_X:

  Logical. Scale predictors before dual PCA.

- verbose:

  Logical. Emit progress messages.

- ...:

  Additional arguments passed to
  [`fit_risdr_sparse()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse.md).

## Value

An object of class `risdr_dual`.

## Details

The inner RISDR standardisation scale is explicitly undone before
mapping directions through the PCA loadings. The returned reduced
predictors are taken directly from the fitted core and are therefore
exactly aligned with the model used for information-criterion selection.

This entry point uses the frozen sparse thesis engine. The existing
[`fit_risdr()`](https://ilovemaths.github.io/risdr/reference/fit_risdr.md)
and
[`fit_risdr_realdata()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_realdata.md)
interfaces retain their continuous-response behaviour from version
0.3.1. Survival fits use Efron Cox partial likelihood. Apparent fit
statistics and loading ranks are exploratory and do not establish
external predictive validity.

## Examples

``` r
set.seed(2026)
X <- matrix(rnorm(80 * 6), 80)
colnames(X) <- paste0("G", 1:6)
time <- rexp(80, rate = exp(0.5 * X[, 1]))
delta <- rep(c(0L, 1L), 40)
fit <- fit_risdr_dual(
  X, time, delta = delta, response_type = "survival",
  sdr_method = "sir", cov_method = "oas", nslices = 4,
  dual_rank = 4, verbose = FALSE, d_max = 2, lambda_grid = c(0, 0.05)
)
fit$d
#> [1] 1
predict(fit, X[1:2, , drop = FALSE], type = "risk")
#>         1         2 
#> 0.9553409 0.4922246 
```
