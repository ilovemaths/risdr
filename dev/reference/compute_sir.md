# Compute Sliced Inverse Regression

Compute Sliced Inverse Regression

## Usage

``` r
compute_sir(
  X,
  y,
  Sigma = NULL,
  nslices = 6,
  slice_type = c("quantile", "equal_width"),
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

- eps:

  Eigenvalue floor.

## Value

A list containing SIR kernel, eigenvalues, directions, scores, and
slices.
