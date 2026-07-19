# Information criterion weights

Computes relative weights from any information criterion column.

## Usage

``` r
criterion_weights(
  d_table,
  criterion = c("AIC", "BIC", "CAIC", "ICOMP", "CICOMP")
)
```

## Arguments

- d_table:

  Dimension selection table.

- criterion:

  Criterion column name.

## Value

Data frame with criterion differences and weights.

## Examples

``` r
scores <- as.matrix(mtcars[, c("wt", "hp", "disp")])
dimension_table <- select_dimension(scores, mtcars$mpg, d_max = 2)
criterion_weights(dimension_table, criterion = "BIC")
#>   d criterion    value    delta     weight
#> 1 1       BIC 170.4266 7.911354 0.01878603
#> 2 2       BIC 162.5153 0.000000 0.98121397
```
