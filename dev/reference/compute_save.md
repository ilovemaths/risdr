# Compute Sliced Average Variance Estimation

Compute Sliced Average Variance Estimation

## Usage

``` r
compute_save(
  X,
  y,
  Sigma = NULL,
  nslices = 6,
  slice_type = c("quantile", "equal_width"),
  stabilize_slices = TRUE,
  stabilization = c("eigenfloor", "ridge", "nearest_pd"),
  eps = 1e-08
)
```

## Arguments

- X:

  Numeric predictor matrix.

- y:

  Numeric response vector.

- Sigma:

  Covariance matrix used for standardisation.

- nslices:

  Number of response slices.

- slice_type:

  Slicing strategy.

- stabilize_slices:

  Logical. Stabilise slice covariance matrices.

- stabilization:

  Stabilisation method.

- eps:

  Eigenvalue floor.

## Value

A list containing SAVE kernel, eigenvalues, directions, scores, and
slices.

## Examples

``` r
X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
fit <- compute_save(X, y = mtcars$mpg, nslices = 4)
head(fit$eigenvalues)
#> [1] 0.9789691 0.8509684 0.5671544
```
