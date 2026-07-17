# Ridge stabilisation of covariance matrix

Stabilises a covariance matrix by adding a positive multiple of the
identity matrix.

## Usage

``` r
stabilize_ridge(Sigma, lambda = 1e-04)
```

## Arguments

- Sigma:

  A square symmetric covariance matrix.

- lambda:

  Ridge stabilisation parameter.

## Value

A symmetric positive definite covariance matrix.
