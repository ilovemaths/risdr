# Adjusted coefficient of determination

Adjusted coefficient of determination

## Usage

``` r
adjusted_r_squared(y_true, y_pred, d)
```

## Arguments

- y_true:

  Observed response values.

- y_pred:

  Predicted response values.

- d:

  Number of predictors in the downstream model.

## Value

Numeric adjusted R-squared.

## Examples

``` r
adjusted_r_squared(
  c(2, 4, 6, 8, 10),
  c(2.2, 3.8, 5.7, 8.1, 9.8),
  d = 1
)
#> [1] 0.9926667
```
