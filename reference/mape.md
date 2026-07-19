# Mean absolute percentage error

Mean absolute percentage error

## Usage

``` r
mape(y_true, y_pred)
```

## Arguments

- y_true:

  Observed response values.

- y_pred:

  Predicted response values.

## Value

Numeric MAPE.

## Examples

``` r
mape(c(2, 4, 6, 8), c(2.2, 3.8, 5.7, 8.1))
#> [1] 5.3125
```
