# Ridge-type covariance estimator

Computes a convex shrinkage covariance estimator of the form
\$\$\Sigma\_{\lambda} = (1 - \lambda)S + \lambda T,\$\$ where \\S\\ is
the sample covariance matrix and \\T\\ is a scaled identity target.

## Usage

``` r
cov_ridge(X, lambda = 0.1)
```

## Arguments

- X:

  Numeric matrix or data frame.

- lambda:

  Shrinkage intensity in \\\[0,1\]\\.

## Value

A covariance matrix.

## Examples

``` r
X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
cov_ridge(X, lambda = 0.2)
#>             disp         hp         wt
#> disp 13626.14814 5376.92694   86.14736
#> hp    5376.92694 5098.20182   35.35413
#> wt      86.14736   35.35413 1338.27418
```
