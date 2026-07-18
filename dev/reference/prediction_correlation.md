# Prediction correlation

Prediction correlation

## Usage

``` r
prediction_correlation(y_true, y_pred)
```

## Arguments

- y_true:

  Observed response values.

- y_pred:

  Predicted response values.

## Value

Pearson correlation.

## Examples

``` r
prediction_correlation(
  c(2, 4, 6, 8),
  c(2.2, 3.8, 5.7, 8.1)
)
#> [1] 0.9958095
```
