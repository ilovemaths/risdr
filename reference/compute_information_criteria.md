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
