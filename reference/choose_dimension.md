# Choose dimension from criteria table

Choose dimension from criteria table

## Usage

``` r
choose_dimension(
  d_table,
  selector = c("cicomp", "icomp", "bic", "caic", "aic")
)
```

## Arguments

- d_table:

  Data frame returned by select_dimension().

- selector:

  Criterion used for selection.

## Value

Selected structural dimension.
