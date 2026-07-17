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
