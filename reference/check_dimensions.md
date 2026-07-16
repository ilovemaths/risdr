# Check dimension arguments

Check dimension arguments

## Usage

``` r
check_dimensions(d = NULL, d_max = 10, p, n = NULL)
```

## Arguments

- d:

  Structural dimension.

- d_max:

  Maximum candidate structural dimension.

- p:

  Number of predictors.

- n:

  Optional sample size. When supplied, dimensions are also restricted to
  leave positive residual degrees of freedom in the downstream model.

## Value

A list containing checked d and d_max.
