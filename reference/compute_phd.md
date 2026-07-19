# Compute Principal Hessian Directions

Compute Principal Hessian Directions

## Usage

``` r
compute_phd(X, y, Sigma = NULL, eps = 1e-08)
```

## Arguments

- X:

  Numeric predictor matrix.

- y:

  Numeric response vector.

- Sigma:

  Covariance matrix used for standardisation.

- eps:

  Eigenvalue floor.

## Value

A list containing pHd kernel, eigenvalues, directions, scores.

## Examples

``` r
X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
fit <- compute_phd(X, y = mtcars$mpg)
head(fit$eigenvalues)
#> [1] -3.654174 -1.229633  0.534509
```
