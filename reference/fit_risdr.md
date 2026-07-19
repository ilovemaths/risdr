# Fit regularised and information-theoretic SDR model

Fits sufficient dimension reduction models with optional covariance
regularisation and information-theoretic structural dimension selection.

## Usage

``` r
fit_risdr(
  X,
  y,
  sdr_method = c("dr", "sir", "save", "phd"),
  cov_method = c("sample", "ridge", "oas", "lw", "mec"),
  stabilize = TRUE,
  stabilization = c("eigenfloor", "ridge", "nearest_pd"),
  nslices = 6,
  d = NULL,
  d_max = 10,
  selector = c("cicomp", "icomp", "bic", "caic", "aic"),
  standardize = TRUE,
  complexity = c("C1", "C1F"),
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

  SDR method: "dr", "sir", "save", or "phd".

- cov_method:

  Covariance estimator: "sample", "ridge", "oas", "lw", or "mec".

- stabilize:

  Logical. If TRUE, stabilises the estimated covariance matrix.

- stabilization:

  Stabilisation method.

- nslices:

  Number of slices for inverse regression methods.

- d:

  Optional structural dimension. If NULL, selected by criterion.

- d_max:

  Maximum candidate structural dimension.

- selector:

  Criterion for selecting d.

- standardize:

  Logical. If TRUE, column-standardises X before covariance estimation.

- complexity:

  Complexity measure for ICOMP: "C1" or "C1F".

- cov_args:

  Named list of arguments for the selected covariance estimator.

- stabilization_args:

  Named list of arguments for covariance stabilisation.

- sdr_args:

  Named list of arguments for the selected SDR kernel.

- ...:

  Backward-compatible component arguments. New code should use the three
  explicit argument lists.

## Value

An object of class "risdr".

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

fit
#> Regularised and Information-Theoretic SDR fit
#> --------------------------------------------------
#> SDR method       : SIR 
#> Covariance       : OAS 
#> Stabilised       : TRUE 
#> Stabilisation    : eigenfloor 
#> Selected d       : 1 
#> Selector         : CICOMP 
#> Number of slices : 4 
#> Observations     : 60 
#> Predictors       : 6 
```
