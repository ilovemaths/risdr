# Evaluate predictions

Computes common prediction metrics.

## Usage

``` r
evaluate_prediction(y_true, y_pred, d = NULL)
```

## Arguments

- y_true:

  Observed response values.

- y_pred:

  Predicted response values.

- d:

  Optional number of reduced predictors.

## Value

A data frame of prediction metrics.

## Examples

``` r
evaluate_prediction(
  y_true = c(2, 4, 6, 8, 10),
  y_pred = c(2.2, 3.8, 5.7, 8.1, 9.8),
  d = 1
)
#>        RMSE MAE MAPE     R2 Adjusted_R2 Correlation
#> 1 0.2097618 0.2 4.65 0.9945   0.9926667   0.9978635
```
