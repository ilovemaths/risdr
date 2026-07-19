# Compute model selection criteria

Computes AIC, BIC, CAIC, ICOMP, and CICOMP for a fitted linear model.

## Usage

``` r
compute_information_criteria(fit, complexity = c("C1", "C1F"), eps = 1e-10)
```

## Arguments

- fit:

  A fitted lm object.

- complexity:

  Character string. Complexity measure, either "C1" or "C1F".

- eps:

  Eigenvalue floor.

## Value

Named numeric vector of criteria.

## Examples

``` r
fit <- stats::lm(mpg ~ wt + hp, data = mtcars)
compute_information_criteria(fit)
#>      AIC      BIC     CAIC    ICOMP   CICOMP 
#> 156.6523 162.5153 166.5153 161.0673 178.9303 
```
