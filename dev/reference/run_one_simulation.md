# Run one SDR simulation replication

Run one SDR simulation replication

## Usage

``` r
run_one_simulation(
  n = 200,
  p = 50,
  d = 2,
  rho = 0.6,
  sigma = 1,
  model = "linear_quadratic",
  beta_type = "coordinate",
  sdr_method = "dr",
  cov_method = "oas",
  nslices = 6,
  selector = "cicomp",
  d_max = 10,
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

  Correlation parameter.

- sigma:

  Error standard deviation.

- model:

  Data-generating model.

- beta_type:

  Type of true central subspace basis.

- sdr_method:

  SDR method.

- cov_method:

  Covariance method.

- nslices:

  Number of slices.

- selector:

  Dimension selection criterion.

- d_max:

  Maximum candidate dimension.

- seed:

  Optional random seed. The test sample uses `seed + 1`.

## Value

A data frame with simulation results.
