# Compute slice proportions

Computes empirical slice probabilities.

## Usage

``` r
slice_proportions(slices)
```

## Arguments

- slices:

  Integer slice memberships.

## Value

Numeric vector of slice proportions.

## Examples

``` r
slices <- make_slices(mtcars$mpg, nslices = 4)
slice_proportions(slices)
#>       1       2       3       4 
#> 0.25000 0.28125 0.25000 0.21875 
```
