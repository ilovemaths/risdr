# Standardise predictors using covariance matrix

Computes the covariance-standardised predictor matrix.

## Usage

``` r
standardize_by_cov(X, Sigma, center = NULL, eps = 1e-08)
```

## Arguments

- X:

  Numeric predictor matrix.

- Sigma:

  Covariance matrix.

- center:

  Optional centring vector.

- eps:

  Eigenvalue floor.

## Value

A list containing standardised predictors and centring vector.

## Details

Specifically, this function centres the predictor matrix and multiplies
it by the inverse square root of the covariance matrix.

`Sigma` denotes a positive definite covariance matrix and `center`
denotes the sample mean vector when it is not supplied explicitly.
