# Effective covariance rank

Computes the number of eigenvalues exceeding a threshold.

## Usage

``` r
cov_effective_rank(Sigma, tol = 1e-06)
```

## Arguments

- Sigma:

  A covariance matrix.

- tol:

  Positive threshold.

## Value

Effective rank.

## Examples

``` r
Sigma <- cov(mtcars[, c("disp", "hp", "wt")])
cov_effective_rank(Sigma)
#> [1] 3
```
