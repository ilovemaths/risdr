# Covariance eigenvalue summary

Provides diagnostic eigenvalue summaries for a covariance matrix.

## Usage

``` r
cov_diagnostics(Sigma, tol = 1e-06)
```

## Arguments

- Sigma:

  A covariance matrix.

- tol:

  Threshold for effective rank.

## Value

A list of covariance diagnostics.

## Examples

``` r
Sigma <- cov(mtcars[, c("disp", "hp", "wt")])
cov_diagnostics(Sigma)
#> $min_eigenvalue
#> [1] 0.1976047
#> 
#> $max_eigenvalue
#> [1] 18609.58
#> 
#> $condition_number
#> [1] 94175.83
#> 
#> $effective_rank
#> [1] 3
#> 
#> $eigenvalues
#> [1] 1.860958e+04 1.452843e+03 1.976047e-01
#> 
```
