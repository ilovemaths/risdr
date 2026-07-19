# Ledoit-Wolf type covariance estimator

Computes a practical Ledoit-Wolf type shrinkage estimator toward a
scaled identity target.

## Usage

``` r
cov_lw(X)
```

## Arguments

- X:

  Numeric matrix or data frame.

## Value

A covariance matrix.

## Examples

``` r
X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
Sigma <- cov_lw(X)
attr(Sigma, "shrinkage")
#> [1] 0.04804693
```
