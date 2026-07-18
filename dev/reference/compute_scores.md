# Compute SDR scores for new data

Projects new predictor observations onto estimated SDR directions.

## Usage

``` r
compute_scores(newX, directions)
```

## Arguments

- newX:

  New predictor matrix or data frame.

- directions:

  Matrix of SDR directions.

## Value

Matrix of SDR scores.

## Examples

``` r
X <- as.matrix(mtcars[1:5, c("wt", "hp", "disp")])
directions <- diag(3)[, 1:2, drop = FALSE]
compute_scores(X, directions)
#>                    SDR1 SDR2
#> Mazda RX4         2.620  110
#> Mazda RX4 Wag     2.875  110
#> Datsun 710        2.320   93
#> Hornet 4 Drive    3.215  110
#> Hornet Sportabout 3.440  175
```
