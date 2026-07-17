# Compute Principal Hessian Directions

Compute Principal Hessian Directions

## Usage

``` r
compute_phd(X, y, Sigma = NULL, eps = 1e-08)
```

## Arguments

- X:

  Numeric predictor matrix.

- y:

  Numeric response vector.

- Sigma:

  Covariance matrix used for standardisation.

- eps:

  Eigenvalue floor.

## Value

A list containing pHd kernel, eigenvalues, directions, scores.
