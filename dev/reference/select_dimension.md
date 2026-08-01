# Select structural dimension

Fits linear models on SDR scores for candidate dimensions and computes
information criteria.

## Usage

``` r
select_dimension(
  scores,
  y,
  d_max = 10,
  complexity = c("C1", "C1F"),
  eps = 1e-10
)
```

## Arguments

- scores:

  Matrix of SDR scores.

- y:

  Numeric response vector.

- d_max:

  Maximum candidate dimension.

- complexity:

  Complexity measure for ICOMP.

- eps:

  Eigenvalue floor.

## Value

A data frame of criteria by candidate dimension.

## Examples

``` r
scores <- as.matrix(mtcars[, c("wt", "hp", "disp")])
dimension_table <- select_dimension(
  scores = scores,
  y = mtcars$mpg,
  d_max = 2
)
dimension_table
#>   d      AIC      BIC     CAIC    ICOMP   CICOMP
#> 1 1 166.0294 170.4266 173.4266 163.7341 177.1313
#> 2 2 156.6523 162.5153 166.5153 161.0673 178.9303
```
