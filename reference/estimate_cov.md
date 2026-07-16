# General covariance estimator dispatcher

Dispatches to the requested covariance estimator. For MEC, the function
supports continuous, categorical, and censored survival responses by
passing `response_type` and `delta` to
[`cov_mec()`](https://ilovemaths.github.io/risdr/reference/cov_mec.md).

## Usage

``` r
estimate_cov(
  X,
  y = NULL,
  method = c("sample", "ridge", "oas", "lw", "mec"),
  nslices = 6,
  response_type = c("continuous", "categorical", "survival"),
  delta = NULL,
  ...
)
```

## Arguments

- X:

  Numeric matrix or data frame.

- y:

  Optional response vector required for MEC.

- method:

  Covariance estimator.

- nslices:

  Number of slices for MEC.

- response_type:

  Response type. One of `"continuous"`, `"categorical"`, or
  `"survival"`.

- delta:

  Optional event indicator for survival data.

- ...:

  Additional arguments passed to internal covariance estimators.

## Value

A covariance matrix.
