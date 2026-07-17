# Fit RISDR to real high-dimensional data

Fit RISDR to real high-dimensional data

## Usage

``` r
fit_risdr_realdata(
  X,
  y,
  delta = NULL,
  response_type = c("continuous", "binary", "multiclass", "survival"),
  variance_quantile = 0.25,
  d = NULL,
  ...
)
```

## Arguments

- X:

  Predictor matrix.

- y:

  Response vector.

- delta:

  Optional survival censoring indicator.

- response_type:

  Response type.

- variance_quantile:

  Variance filtering threshold.

- d:

  Optional fixed structural dimension passed to
  [`fit_risdr()`](https://ilovemaths.github.io/risdr/dev/reference/fit_risdr.md).

- ...:

  Additional arguments passed to fit_risdr().

## Value

Fitted RISDR workflow object.
