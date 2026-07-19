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

## Examples

``` r
scores <- as.matrix(mtcars[, c("wt", "hp", "disp")])
dimension_table <- select_dimension(scores, mtcars$mpg, d_max = 2)
choose_dimension(dimension_table, selector = "bic")
#> [1] 2
```
