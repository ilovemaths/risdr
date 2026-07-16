# Covariance Regularisation

## Motivation

Inverse-regression methods commonly require covariance standardisation.
When predictors are strongly collinear or the predictor dimension is not
small relative to the sample size, the sample covariance matrix may be
poorly conditioned or singular. Regularisation changes the bias-variance
trade-off to obtain a more stable inverse.

`risdr` includes sample covariance, ridge shrinkage, OAS (Chen et al.
2010), LW (Ledoit and Wolf 2004), and MEC.

## Comparison on a controlled design

``` r

library(risdr)

sim <- simulate_risdr_data(
  n = 100,
  p = 40,
  d = 2,
  rho = 0.9,
  seed = 7001
)

estimates <- list(
  sample = cov_sample(sim$X),
  ridge = cov_ridge(sim$X, lambda = 0.10),
  oas = cov_oas(sim$X),
  lw = cov_lw(sim$X),
  mec = cov_mec(sim$X, sim$y, nslices = 6)
)

diagnostics <- do.call(
  rbind,
  lapply(names(estimates), function(name) {
    value <- cov_diagnostics(estimates[[name]])
    data.frame(
      estimator = name,
      minimum_eigenvalue = value$min_eigenvalue,
      maximum_eigenvalue = value$max_eigenvalue,
      condition_number = value$condition_number,
      effective_rank = value$effective_rank
    )
  })
)

diagnostics
#>   estimator minimum_eigenvalue maximum_eigenvalue condition_number
#> 1    sample        0.013663062           13.59163         994.7718
#> 2     ridge        0.109488283           12.32966         112.6117
#> 3       oas        0.074309851           12.65522         170.3035
#> 4        lw        0.078515511           12.59984         160.4758
#> 5       mec        0.001871314           15.44685        8254.5483
#>   effective_rank
#> 1             40
#> 2             40
#> 3             40
#> 4             40
#> 5             40
```

Condition number and effective rank describe numerical behaviour, not
predictive adequacy. They should be interpreted alongside downstream and
subspace metrics.

## Ridge estimator

For sample covariance `\mathbf{S}` and scaled identity target
`\mathbf{T}`, the ridge estimator is

``` math
\widehat{\boldsymbol{\Sigma}}_{\lambda}
= (1-\lambda)\mathbf{S}+\lambda\mathbf{T},
\qquad 0\leq\lambda\leq 1.
```

``` r

ridge_fit <- fit_risdr(
  sim$X,
  sim$y,
  sdr_method = "sir",
  cov_method = "ridge",
  d = 2,
  d_max = 5,
  cov_args = list(lambda = 0.15)
)
```

## Post-estimation stabilisation

Covariance estimation and numerical stabilisation are separate
operations. An estimated covariance may be stabilised using an
eigenvalue floor, an additive ridge term, or a nearest positive-definite
projection.

``` r

sample_covariance <- cov_sample(sim$X)

floor_covariance <- stabilize_cov(
  sample_covariance,
  method = "eigenfloor",
  eps = 1e-6
)

ridge_covariance <- stabilize_cov(
  sample_covariance,
  method = "ridge",
  lambda = 1e-4
)

nearest_covariance <- stabilize_cov(
  sample_covariance,
  method = "nearest_pd",
  keep_diag = TRUE
)
```

The
[`fit_risdr()`](https://ilovemaths.github.io/risdr/reference/fit_risdr.md)
interface separates these controls:

``` r

separated_controls <- fit_risdr(
  sim$X,
  sim$y,
  sdr_method = "dr",
  cov_method = "ridge",
  stabilization = "eigenfloor",
  d = 2,
  d_max = 5,
  cov_args = list(lambda = 0.10),
  stabilization_args = list(eps = 1e-7)
)
```

## Legacy Simulation A outputs

``` r

simulation_path <- system.file(
  "extdata",
  "simulation",
  "simulation_A_final_covariance_DR_summary_tidy.csv",
  package = "risdr"
)
simulation_a <- utils::read.csv(simulation_path)

aggregate(
  cbind(
    mean_subspace_distance,
    mean_RMSE,
    mean_condition_number,
    mean_runtime_seconds
  ) ~ cov_method,
  data = simulation_a,
  FUN = mean
)
#>   cov_method mean_subspace_distance mean_RMSE mean_condition_number
#> 1         LW               1.894428  2.309378          2.134967e+02
#> 2        MEC               1.965678  2.704028          1.713922e+07
#> 3        OAS               1.895389  2.293333          2.123284e+02
#> 4      RIDGE               1.897106  2.388906          1.390600e+02
#> 5     SAMPLE               1.950800  3.732978          9.276394e+06
#>   mean_runtime_seconds
#> 1            0.3466222
#> 2            0.3374833
#> 3            0.2410333
#> 4            0.2114944
#> 5            0.2414333
```

The supplied Simulation A record favours OAS and ridge for conditioning.
Its prediction columns require rerun because the original script
regenerated the random true basis for the test sample. The table is
retained here for provenance and must not be treated as a newly
validated v0.3.0 result.

## Maximum Entropy Covariance

The Maximum Entropy Covariance (MEC) estimator follows the covariance
estimation approach proposed by Olorede and Yahya (2019) for sufficient
dimension reduction in high-dimensional and undersized-sample settings.
The estimator uses response slicing, selects the slice covariance with
the largest stabilised log determinant, and combines it with the pooled
covariance through convex shrinkage. This definition is authoritative
for the package documentation, software papers, and subsequent releases.

## References

Chen, Yilun, Ami Wiesel, Yonina C. Eldar, and Alfred O. Hero. 2010.
“Shrinkage Algorithms for MMSE Covariance Estimation.” *IEEE
Transactions on Signal Processing* 58 (10): 5016–29.
<https://doi.org/10.1109/TSP.2010.2053029>.

Ledoit, Olivier, and Michael Wolf. 2004. “A Well-Conditioned Estimator
for Large-Dimensional Covariance Matrices.” *Journal of Multivariate
Analysis* 88 (2): 365–411.
<https://doi.org/10.1016/S0047-259X(03)00096-4>.

Olorede, Kabir Opeyemi, and Waheed Babatunde Yahya. 2019. *A New
Covariance Estimator for Sufficient Dimension Reduction in
High-Dimensional and Undersized Sample Problems*.
<https://arxiv.org/abs/1909.13017>.
