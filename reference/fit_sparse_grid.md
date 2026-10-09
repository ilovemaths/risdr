# Fit sparse SDR directions over a lambda grid

Accepts either an explicit dense direction matrix or a historical kernel
object containing `directions` or `vectors`.

## Usage

``` r
fit_sparse_grid(
  kernel_obj = NULL,
  directions = NULL,
  d = 2L,
  lambda_grid = seq(0, 0.5, length.out = 25L),
  penalty_weights = NULL,
  adapt_weights = FALSE,
  Sigma = NULL,
  weight_mode = c("c1f", "inverse_c1f", "uniform"),
  tol = 1e-10
)
```

## Arguments

- kernel_obj:

  Optional historical kernel object.

- directions:

  Optional dense direction matrix.

- d:

  Structural dimension.

- lambda_grid:

  Numeric vector of tuning values.

- penalty_weights:

  Optional user-supplied penalty weights.

- adapt_weights:

  Logical; derive weights from `Sigma` when TRUE.

- Sigma:

  Optional covariance matrix.

- weight_mode:

  Adaptive weighting mode.

- tol:

  Numerical tolerance.

## Value

Sparse-grid object.
