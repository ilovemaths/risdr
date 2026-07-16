# Check new predictor observations

Validates predictor input used only for projection or prediction. Unlike
[`check_X()`](https://ilovemaths.github.io/risdr/reference/check_X.md),
this helper permits a single observation.

## Usage

``` r
check_new_X(X, min_cols = 1L)
```

## Arguments

- X:

  A numeric matrix or data frame.

- min_cols:

  Minimum permitted number of columns.

## Value

A numeric matrix.
