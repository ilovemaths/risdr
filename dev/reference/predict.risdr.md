# Predict method for risdr objects

Predict method for risdr objects

## Usage

``` r
# S3 method for class 'risdr'
predict(object, newX, d = NULL, ...)
```

## Arguments

- object:

  Object of class "risdr".

- newX:

  New predictor matrix or data frame.

- d:

  Optional structural dimension.

- ...:

  Additional arguments passed to internal methods.

## Value

Numeric vector of predictions.

## Examples

``` r
simulated <- simulate_risdr_data(
  n = 60,
  p = 6,
  d = 2,
  seed = 2026
)

fit <- fit_risdr(
  X = simulated$X,
  y = simulated$y,
  sdr_method = "sir",
  cov_method = "oas",
  nslices = 4,
  d = 1,
  d_max = 3
)

predict(fit, newX = simulated$X[1:5, , drop = FALSE])
#> [1] 1.4537697 0.3564072 0.3778502 0.7143796 0.8060729
```
