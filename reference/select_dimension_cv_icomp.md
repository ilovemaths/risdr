# Complexity-aware cross-validation for structural dimension selection

Combines out-of-fold prediction error with rescaled BIC, CAIC, or CICOMP
penalties. The tuning constant `lambda` controls the contribution of the
information-criterion component.

## Usage

``` r
select_dimension_cv_icomp(
  X,
  y,
  sdr_method = c("dr", "sir", "save", "phd"),
  cov_method = c("sample", "ridge", "oas", "lw", "mec"),
  d_max = 10,
  v = 5,
  nslices = 6,
  standardize = TRUE,
  stabilize = TRUE,
  stabilization = c("eigenfloor", "ridge", "nearest_pd"),
  complexity = c("C1", "C1F"),
  lambda = 1,
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

- v:

  Number of cross-validation folds.

- nslices:

  Number of response slices.

- standardize:

  Logical. Standardise within each training fold.

- stabilize:

  Logical. Stabilise the estimated covariance matrix.

- stabilization:

  Covariance stabilisation method.

- complexity:

  Covariance complexity measure.

- lambda:

  Non-negative information-criterion weight.

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

A list containing selected dimensions, the aggregated cross-validation
table, and fold-level results.
