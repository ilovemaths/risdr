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
