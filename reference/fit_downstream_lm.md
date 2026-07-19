# Fit downstream regression model on SDR scores

Fits a linear regression model using the first d SDR scores.

## Usage

``` r
fit_downstream_lm(scores, y, d)
```

## Arguments

- scores:

  Matrix of SDR scores.

- y:

  Numeric response vector.

- d:

  Structural dimension.

## Value

A fitted lm object.

## Examples

``` r
scores <- as.matrix(mtcars[, c("wt", "hp")])
fit_downstream_lm(scores, y = mtcars$mpg, d = 2)
#> 
#> Call:
#> stats::lm(formula = y ~ ., data = dat)
#> 
#> Coefficients:
#> (Intercept)         SDR1         SDR2  
#>    37.22727     -3.87783     -0.03177  
#> 
```
