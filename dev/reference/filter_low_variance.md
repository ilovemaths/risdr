# Filter low-variance predictors

Removes predictors with variance below a specified quantile.

## Usage

``` r
filter_low_variance(X, variance_quantile = 0.25)
```

## Arguments

- X:

  Predictor matrix.

- variance_quantile:

  Quantile threshold.

## Value

Filtered matrix.
