# Ladle-type structural dimension diagnostic

Computes a simple ladle-type diagnostic by combining normalised
eigenvalue information with a bootstrap-based subspace instability
measure.

## Usage

``` r
select_dimension_ladle(
  X,
  y,
  sdr_method = c("dr", "sir", "save", "phd"),
  cov_method = c("sample", "ridge", "oas", "lw", "mec"),
  d_max = 10,
  B = 100,
  nslices = 6,
  standardize = TRUE,
  stabilize = TRUE,
  stabilization = c("eigenfloor", "ridge", "nearest_pd"),
  seed = NULL,
  cov_args = list(),
  stabilization_args = list(),
  sdr_args = list(),
  ...
)
```

## Arguments

- X:

  Numeric predictor matrix or data frame.

- y:

  Numeric continuous response vector.

- sdr_method:

  SDR method.

- cov_method:

  Covariance estimator.

- d_max:

  Maximum candidate structural dimension.

- B:

  Number of bootstrap replications.

- nslices:

  Number of slices.

- standardize:

  Logical. If TRUE, standardises predictors.

- stabilize:

  Logical. If TRUE, stabilises covariance matrix.

- stabilization:

  Stabilisation method.

- seed:

  Optional random seed.

- cov_args:

  Named list of covariance-estimator arguments.

- stabilization_args:

  Named list of stabilisation arguments.

- sdr_args:

  Named list of SDR-kernel arguments.

- ...:

  Backward-compatible component arguments.

## Value

A list containing ladle table, selected dimension, and bootstrap
distances.
