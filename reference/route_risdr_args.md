# Route component-specific arguments

Separates legacy arguments supplied through `...` from explicit
covariance, stabilisation, and SDR argument lists. Explicit component
lists take precedence over matching legacy arguments.

## Usage

``` r
route_risdr_args(
  dots,
  cov_method,
  stabilization,
  sdr_method,
  cov_args = list(),
  stabilization_args = list(),
  sdr_args = list()
)
```

## Arguments

- dots:

  Named list created from `...`.

- cov_method:

  Covariance estimator.

- stabilization:

  Covariance stabilisation method.

- sdr_method:

  SDR method.

- cov_args:

  Explicit covariance-estimator arguments.

- stabilization_args:

  Explicit stabilisation arguments.

- sdr_args:

  Explicit SDR-kernel arguments.

## Value

A list with `cov_args`, `stabilization_args`, and `sdr_args`.
