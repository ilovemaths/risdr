# General covariance estimator dispatcher

Dispatches to the requested covariance estimator. For MEC, the function
supports continuous, categorical, and censored survival responses by
passing `response_type` and `delta` to
[`cov_mec()`](https://ilovemaths.github.io/risdr/dev/reference/cov_mec.md).

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

## Examples

``` r
X <- as.matrix(mtcars[, c("disp", "hp", "wt")])

estimate_cov(X, method = "oas")
#>             disp         hp        wt
#> disp 14251.72868 6023.65641  96.50905
#> hp    6023.65641 4698.05255  39.60648
#> wt      96.50905   39.60648 485.88591
#> attr(,"shrinkage")
#> [1] 0.07486667
estimate_cov(
  X,
  y = mtcars$mpg,
  method = "mec",
  nslices = 4
)
#>            [,1]        [,2]       [,3]
#> [1,] 6453.60813  119.899005 65.6710881
#> [2,]  119.89900 3094.797811 -3.3171616
#> [3,]   65.67109   -3.317162  0.8010292
#> attr(,"alpha")
#> [1] 0.95
#> attr(,"entropy_slice")
#> [1] 1
#> attr(,"slice_entropy")
#> [1] 14.550077 13.234394 11.199660  9.706499
#> attr(,"response_type")
#> [1] "continuous"
```
