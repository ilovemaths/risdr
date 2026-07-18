# AR(1) covariance matrix

AR(1) covariance matrix

## Usage

``` r
ar1_covariance(p, rho)
```

## Arguments

- p:

  Dimension.

- rho:

  Correlation parameter.

## Value

Covariance matrix.

## Examples

``` r
ar1_covariance(p = 4, rho = 0.5)
#>       [,1] [,2] [,3]  [,4]
#> [1,] 1.000 0.50 0.25 0.125
#> [2,] 0.500 1.00 0.50 0.250
#> [3,] 0.250 0.50 1.00 0.500
#> [4,] 0.125 0.25 0.50 1.000
```
