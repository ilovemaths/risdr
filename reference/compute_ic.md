# Compute one reduced-model information criterion

Compute one reduced-model information criterion

## Usage

``` r
compute_ic(
  y,
  Z,
  criterion = c("cicomp", "icomp", "aic", "caic", "bic"),
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

- criterion:

  Criterion name.

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

Scalar criterion value.
