# Nearest positive definite stabilisation

Stabilises a covariance matrix by projecting it to the nearest positive
definite matrix using Matrix::nearPD().

## Usage

``` r
stabilize_nearest_pd(Sigma, keep_diag = TRUE)
```

## Arguments

- Sigma:

  A square symmetric covariance matrix.

- keep_diag:

  Logical. If TRUE, keeps original diagonal where possible.

## Value

A symmetric positive definite covariance matrix.
