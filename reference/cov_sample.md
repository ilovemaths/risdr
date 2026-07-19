# Sample covariance matrix

Computes the usual unbiased sample covariance matrix.

## Usage

``` r
cov_sample(X)
```

## Arguments

- X:

  Numeric matrix or data frame.

## Value

A covariance matrix.

## Examples

``` r
X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
cov_sample(X)
#>            disp         hp         wt
#> disp 15360.7998 6721.15867 107.684204
#> hp    6721.1587 4700.86694  44.192661
#> wt     107.6842   44.19266   0.957379
```
