# Eigenvalue floor stabilisation

Stabilises a symmetric covariance matrix by replacing eigenvalues
smaller than a positive threshold with that threshold.

## Usage

``` r
stabilize_eigenfloor(Sigma, eps = 1e-06)
```

## Arguments

- Sigma:

  A square symmetric covariance matrix.

- eps:

  Positive eigenvalue floor.

## Value

A symmetric positive definite covariance matrix.
