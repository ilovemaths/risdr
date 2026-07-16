# Fit downstream regression model on SDR scores

Fits a linear regression model using the first d SDR scores.

## Usage

``` r
fit_downstream_lm(scores, y, d)
```

## Arguments

- scores:

  Matrix of SDR scores.

- y:

  Numeric response vector.

- d:

  Structural dimension.

## Value

A fitted lm object.
