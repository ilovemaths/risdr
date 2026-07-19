# Summarise response slices

Produces a summary table of slice frequencies and response ranges.

## Usage

``` r
slice_summary(y, slices)
```

## Arguments

- y:

  Numeric response vector.

- slices:

  Integer slice memberships.

## Value

A data frame summarising slices.

## Examples

``` r
slices <- make_slices(mtcars$mpg, nslices = 4)
slice_summary(mtcars$mpg, slices)
#>   slice n proportion y_min y_max   y_mean
#> 1     1 8    0.25000  10.4  15.2 13.56250
#> 2     2 9    0.28125  15.5  19.2 17.55556
#> 3     3 8    0.25000  19.7  22.8 21.45000
#> 4     4 7    0.21875  24.4  33.9 29.25714
```
