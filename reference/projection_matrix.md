# Projection matrix

Projection matrix

## Usage

``` r
projection_matrix(B)
```

## Arguments

- B:

  Basis matrix.

## Value

Projection matrix.

## Examples

``` r
B <- matrix(c(1, 0, 0, 0, 1, 0), nrow = 3)
projection_matrix(B)
#>      [,1] [,2] [,3]
#> [1,]    1    0    0
#> [2,]    0    1    0
#> [3,]    0    0    0
```
