# Cross-validation dimension selection for SDR

Selects structural dimension by V-fold cross-validation. For each
candidate dimension, SDR is fitted on the training folds, a downstream
linear regression is fitted using the reduced predictors, and prediction
error is evaluated on the validation fold.

## Usage

``` r
select_dimension_cv(
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
  metric = c("RMSE", "MAE"),
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

  Number of folds.

- nslices:

  Number of slices.

- standardize:

  Logical. If TRUE, standardises predictors inside each training fold.

- stabilize:

  Logical. If TRUE, stabilises covariance matrix.

- stabilization:

  Stabilisation method.

- metric:

  Prediction metric used for selection.

- seed:

  Optional random seed.

- cov_args:

  Named list of arguments for the covariance estimator.

- stabilization_args:

  Named list of arguments for covariance stabilisation.

- sdr_args:

  Named list of arguments for the SDR kernel.

- ...:

  Backward-compatible component arguments.

## Value

A list containing the CV table, selected dimension, and fold-level
results.
