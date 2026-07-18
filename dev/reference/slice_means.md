# Compute slice means

Computes slice-specific means of predictors.

## Usage

``` r
slice_means(X, slices)
```

## Arguments

- X:

  Numeric matrix.

- slices:

  Integer slice memberships.

## Value

Matrix of slice means with rows corresponding to slices.

## Examples

``` r
X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
slices <- make_slices(mtcars$mpg, nslices = 4)
slice_means(X, slices)
#>              disp        hp       wt
#> slice_1 370.35000 225.62500 4.276750
#> slice_2 282.31111 163.88889 3.568333
#> slice_3 151.61250 112.37500 2.774375
#> slice_4  95.22857  73.57143 2.061143
```
