# General covariance stabilisation dispatcher

Stabilises a covariance matrix using one of several available methods.

## Usage

``` r
stabilize_cov(
  Sigma,
  method = c("eigenfloor", "ridge", "nearest_pd"),
  eps = 1e-06,
  lambda = 1e-04,
  keep_diag = TRUE
)
```

## Arguments

- Sigma:

  A square symmetric covariance matrix.

- method:

  Stabilisation method.

- eps:

  Positive eigenvalue floor for eigenfloor method.

- lambda:

  Ridge parameter for ridge method.

- keep_diag:

  Logical. Used by nearest positive definite method.

## Value

A stabilised covariance matrix.

## Examples

``` r
Sigma <- matrix(c(1, 1, 1, 1), nrow = 2)
stabilize_cov(Sigma, method = "eigenfloor")
#>           [,1]      [,2]
#> [1,] 1.0000005 0.9999995
#> [2,] 0.9999995 1.0000005
```
