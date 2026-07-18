# Oracle Approximating Shrinkage covariance estimator

Computes a simplified Oracle Approximating Shrinkage (OAS) covariance
estimator for stabilising the sample covariance matrix.

## Usage

``` r
cov_oas(X)
```

## Arguments

- X:

  Numeric matrix or data frame.

## Value

A covariance matrix.

## Examples

``` r
X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
Sigma <- cov_oas(X)
attr(Sigma, "shrinkage")
#> [1] 0.07486667
```
