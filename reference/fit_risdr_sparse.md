# Fit regularised and information-theoretic sufficient dimension reduction

Fits an SDR model using a regularised covariance estimator, a selected
inverse-regression kernel, adaptive sparse direction estimation, and
information-criterion profiling jointly over structural dimension and
sparsity tuning parameter.

## Usage

``` r
fit_risdr_sparse(
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
  lambda_grid = seq(0, 0.3, length.out = 10L),
  adapt_weights = TRUE,
  weight_mode = c("c1f", "inverse_c1f", "uniform"),
  penalty_weights = NULL,
  support_penalty = FALSE,
  cov_fun = NULL,
  shrinkage = 1e-04,
  tol = 1e-10,
  ...
)
```

## Arguments

- X:

  Numeric predictor matrix or data frame.

- y:

  Response vector. For survival data, observed survival time.

- delta:

  Optional 0/1 event indicator for survival data.

- response_type:

  One of `"continuous"`, `"categorical"`, or `"survival"`.

- sdr_method:

  One of `"dr"`, `"sir"`, `"save"`, or `"phd"`.

- cov_method:

  One of `"mec"`, `"oas"`, `"lw"`, `"sample"`, `"ridge"`, or `"user"`.

- stabilize:

  Logical. Stage-3 thesis fits require covariance stabilisation and
  therefore currently require `TRUE`.

- stabilization:

  Stabilisation method passed to
  [`estimate_cov()`](https://ilovemaths.github.io/risdr/reference/estimate_cov.md).

- nslices:

  Number of response slices, or slices per censoring-status group for
  survival data.

- d:

  Optional fixed structural dimension. If `NULL`, selected by `selector`
  from candidates 1 through `d_max`.

- d_max:

  Maximum candidate structural dimension.

- selector:

  One of `"cicomp"`, `"icomp"`, `"bic"`, `"caic"`, or `"aic"`.

- standardize:

  Logical. Standardise predictor columns before fitting.

- complexity:

  Retained for compatibility. The Stage-3 thesis engine uses the
  scale-invariant C1F complexity in ICOMP/CICOMP.

- lambda_grid:

  Non-negative sparsity tuning grid.

- adapt_weights:

  Logical. Use covariance-derived adaptive weights.

- weight_mode:

  One of `"c1f"`, `"inverse_c1f"`, or `"uniform"`.

- penalty_weights:

  Optional user-supplied variable-level weights.

- support_penalty:

  Logical. If `TRUE`, active-support size contributes to the effective
  parameter count in the information criteria.

- cov_fun:

  Optional user-defined covariance estimator.

- shrinkage:

  Ridge shrinkage parameter used by
  [`estimate_cov()`](https://ilovemaths.github.io/risdr/reference/estimate_cov.md).

- tol:

  Numerical tolerance.

- ...:

  Additional arguments passed only to a user covariance estimator.

## Value

An object of class `risdr` containing the complete `(d, lambda)`
selection grid, profiled dimension table, selected sparse directions,
reduced predictors, covariance diagnostics, and compatibility fields.

## Details

For `d = NULL`, every candidate dimension from 1 through `d_max` is
evaluated over the complete `lambda_grid`. The requested selector then
chooses the final `(d, lambda)` pair. For explicit `d`, the same audit
grid is retained but the final dimension is fixed and only lambda is
selected within that dimension.

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
fit <- fit_risdr_sparse(
  X, time, delta = delta, response_type = "survival",
  sdr_method = "sir", cov_method = "oas", nslices = 4,
  d_max = 2, lambda_grid = c(0, 0.05)
)
fit$d
#> [1] 1
predict(fit, X[1:2, , drop = FALSE], type = "risk")
#>         1         2 
#> 0.9311306 0.5012283 
```
