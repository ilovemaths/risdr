# Maximum Entropy Covariance estimator

Computes a maximum-entropy motivated covariance estimator for SDR.

## Usage

``` r
cov_mec(
  X,
  y,
  nslices = 6,
  response_type = c("continuous", "categorical", "survival"),
  delta = NULL,
  alpha = NULL,
  eps = 1e-06,
  ...
)
```

## Arguments

- X:

  Numeric matrix or data frame.

- y:

  Numeric response vector.

- nslices:

  Number of response slices.

- response_type:

  Response type. One of `"continuous"`, `"categorical"`, or
  `"survival"`.

- delta:

  Optional event indicator for survival data.

- alpha:

  Convex weight assigned to the entropy-maximising slice covariance. If
  NULL, alpha is chosen adaptively from the condition number of the
  pooled covariance.

- eps:

  Small positive eigenvalue floor used for log-determinant stability.

- ...:

  Additional arguments passed to internal methods.

## Value

A covariance matrix with attributes containing the shrinkage weight and
entropy diagnostics.

## Details

The estimator uses response slicing to obtain slice-specific covariance
matrices, selects the covariance matrix with maximum log-determinant
entropy, and combines it with the pooled covariance matrix through
convex shrinkage.

For censored survival responses, the function accepts `delta` and
applies a survival-aware response construction before slicing.
