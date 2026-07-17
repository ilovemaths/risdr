# Repeated cross-validation for predictive assessment

Repeats V-fold cross-validation for a fixed SDR and covariance-estimator
combination. Failed folds are retained with diagnostic messages.

## Usage

``` r
evaluate_prediction_cv(
  X,
  y,
  sdr_method = c("dr", "sir", "save", "phd"),
  cov_method = c("sample", "ridge", "oas", "lw", "mec"),
  d,
  v = 5,
  repeats = 10,
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

- d:

  Fixed structural dimension.

- v:

  Number of folds.

- repeats:

  Number of cross-validation repetitions.

- nslices:

  Number of response slices.

- standardize:

  Logical. Standardise within each training fold.

- stabilize:

  Logical. Stabilise the estimated covariance matrix.

- stabilization:

  Covariance stabilisation method.

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

A list containing a one-row summary and fold-level results.
