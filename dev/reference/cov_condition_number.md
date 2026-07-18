# Covariance condition number

Computes the spectral condition number of a covariance matrix.

## Usage

``` r
cov_condition_number(Sigma, eps = 1e-12)
```

## Arguments

- Sigma:

  A covariance matrix.

- eps:

  Small positive value used to avoid division by zero.

## Value

Numeric condition number.

## Examples

``` r
Sigma <- cov(mtcars[, c("disp", "hp", "wt")])
cov_condition_number(Sigma)
#> [1] 94175.83
```
