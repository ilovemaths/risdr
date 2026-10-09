# Compute all reduced-model information criteria

Compute all reduced-model information criteria

## Usage

``` r
compute_ic_values(
  y,
  Z,
  response_type = c("continuous", "categorical", "survival"),
  delta = NULL,
  n_active = NULL,
  support_penalty = FALSE,
  tol = 1e-10
)
```

## Arguments

- y:

  Response vector.

- Z:

  Reduced predictors.

- response_type:

  Response type.

- delta:

  Optional event indicator.

- n_active:

  Optional active-support size.

- support_penalty:

  Include active-support size in effective df.

- tol:

  Numerical tolerance.

## Value

Named numeric vector containing AIC, BIC, CAIC, ICOMP, CICOMP,
log-likelihood, effective df, and C1F.
