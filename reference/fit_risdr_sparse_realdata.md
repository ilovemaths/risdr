# Fit RISDR to real high-dimensional data

Fit RISDR to real high-dimensional data

## Usage

``` r
fit_risdr_sparse_realdata(
  X,
  y,
  delta = NULL,
  response_type = c("continuous", "binary", "multiclass", "categorical", "survival"),
  variance_quantile = 0.25,
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

- ...:

  Additional arguments passed to fit_risdr_sparse().

## Value

Fitted RISDR workflow object. Fit RISDR to a real-data predictor matrix

Applies outcome cleaning, low-variance screening, the unified RISDR
core, and descriptive loading-based variable ranking. The wrapper
returns the reduced predictors computed by the core itself so that
centring and standardisation are not silently bypassed.

`"multiclass"`, `"categorical"`, or `"survival"`. low-variance screen.

An object of class `risdr_realdata`.

## Details

This entry point uses the frozen sparse thesis engine. The existing
[`fit_risdr()`](https://ilovemaths.github.io/risdr/reference/fit_risdr.md)
and
[`fit_risdr_realdata()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_realdata.md)
interfaces retain their continuous-response behaviour from version
0.3.1. Survival fits use Efron Cox partial likelihood. Apparent fit
statistics and loading ranks are exploratory and do not establish
external predictive validity.
