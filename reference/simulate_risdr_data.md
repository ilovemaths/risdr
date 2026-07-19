# Simulate SDR data

Simulates data from a sufficient dimension reduction model with an
autoregressive covariance structure. The function returns the true
orthonormal central subspace basis, which allows simulation studies to
evaluate both prediction accuracy and subspace recovery.

## Usage

``` r
simulate_risdr_data(
  n = 200,
  p = 50,
  d = 2,
  rho = 0.6,
  sigma = 1,
  signal_strength = 1,
  model = c("linear_quadratic", "symmetric", "interaction", "linear"),
  beta_type = c("coordinate", "random_sparse", "random_dense"),
  beta = NULL,
  seed = NULL
)
```

## Arguments

- n:

  Sample size.

- p:

  Number of predictors.

- d:

  Structural dimension.

- rho:

  AR(1) correlation parameter.

- sigma:

  Error standard deviation.

- signal_strength:

  Multiplicative strength of the regression signal.

- model:

  Data-generating model.

- beta_type:

  Type of true central subspace basis.

- beta:

  Optional user-supplied `p` by `d` central subspace basis. When
  supplied, its orthonormal basis is used and `beta_type` is ignored.

- seed:

  Optional random seed.

## Value

A list containing the simulated predictors, response, true basis, latent
sufficient predictors, population covariance matrix, signal, error, and
simulation settings.

## Examples

``` r
simulated <- simulate_risdr_data(
  n = 60,
  p = 6,
  d = 2,
  rho = 0.4,
  seed = 2026
)

dim(simulated$X)
#> [1] 60  6
head(simulated$y)
#> [1]  0.6492720 -3.9456499 -1.6755412 -2.0225007  3.7572592  0.5424327
crossprod(simulated$beta)
#>       beta1 beta2
#> beta1     1     0
#> beta2     0     1
```
