# Run SDR simulation study

Run SDR simulation study

## Usage

``` r
run_risdr_simulation(
  R = 200,
  rho_values = c(0.3, 0.6, 0.9),
  methods = c("sir", "save", "dr", "phd"),
  cov_methods = c("sample", "oas", "mec"),
  seed = NULL,
  ...
)
```

## Arguments

- R:

  Number of replications.

- rho_values:

  Correlation values.

- methods:

  SDR methods.

- cov_methods:

  Covariance methods.

- seed:

  Optional starting seed for reproducible replications.

- ...:

  Additional arguments passed to
  [`run_one_simulation()`](https://ilovemaths.github.io/risdr/dev/reference/run_one_simulation.md).

## Value

Data frame of simulation results.
