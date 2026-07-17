# General SDR kernel dispatcher

General SDR kernel dispatcher

## Usage

``` r
compute_sdr(
  X,
  y,
  method = c("dr", "sir", "save", "phd"),
  Sigma = NULL,
  nslices = 6,
  ...
)
```

## Arguments

- X:

  Numeric predictor matrix.

- y:

  Numeric response vector.

- method:

  SDR method.

- Sigma:

  Covariance matrix.

- nslices:

  Number of slices.

- ...:

  Additional arguments passed to internal methods.

## Value

SDR fit components.
