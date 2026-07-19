# Simulation Study

## Objectives

The completed research programme separates three simulation questions:

1.  Simulation A compares covariance estimators while holding DR fixed.
2.  Simulation B1 compares SDR subspace estimation while holding OAS
    fixed.
3.  Simulation B2 compares structural dimension recovery while holding
    OAS fixed.

This separation avoids declaring one method universally best when the
evaluation objectives differ.

## Data-generating mechanism

[`simulate_risdr_data()`](https://ilovemaths.github.io/risdr/reference/simulate_risdr_data.md)
generates

``` math
\mathbf{X}\sim N_p(\mathbf{0},\boldsymbol{\Sigma}),\qquad
\Sigma_{jk}=\rho^{|j-k|},
```

and constructs a response from the sufficient predictors
`\mathbf{B}^{\mathsf{T}}\mathbf{X}`.

``` r

library(risdr)

sim <- simulate_risdr_data(
  n = 120,
  p = 30,
  d = 2,
  rho = 0.8,
  sigma = 1,
  model = "linear_quadratic",
  beta_type = "coordinate",
  seed = 9201
)

dim(sim$X)
#> [1] 120  30
crossprod(sim$beta)
#>       beta1 beta2
#> beta1     1     0
#> beta2     0     1
```

## A single replication

``` r

one <- run_one_simulation(
  n = 100,
  p = 20,
  d = 2,
  rho = 0.6,
  sigma = 1,
  model = "linear_quadratic",
  sdr_method = "dr",
  cov_method = "oas",
  nslices = 6,
  d_max = 5,
  seed = 9202
)

one
#>     n  p true_d selected_d rho sigma            model sdr_method cov_method
#> 1 100 20      2          1 0.6     1 linear_quadratic         dr        oas
#>   selector subspace_distance    RMSE      MAE    MAPE         R2 Adjusted_R2
#> 1   cicomp          1.320158 2.18873 1.490271 314.531 0.04857807  0.03886969
#>   Correlation
#> 1   0.4162502
```

Subspace distance is the Frobenius distance between the projection
matrices:

``` math
\left\|
\widehat{\mathbf{P}}_{\mathbf{B}}
-\mathbf{P}_{\mathbf{B}}
\right\|_F.
```

The measure is invariant to rotations and sign changes within an
estimated subspace.

## A small reproducible study

``` r

small_study <- run_risdr_simulation(
  R = 2,
  rho_values = c(0.3, 0.8),
  methods = c("sir", "dr"),
  cov_methods = c("ridge", "oas"),
  n = 80,
  p = 15,
  d = 2,
  nslices = 5,
  d_max = 4,
  seed = 9203
)

summarise_simulation(small_study)
#>   rho sdr_method cov_method subspace_distance     RMSE      MAE          R2
#> 1 0.3         dr        oas          1.525298 1.993248 1.530878  0.09422162
#> 2 0.8         dr        oas          1.451363 1.888500 1.375991 -0.03539802
#> 3 0.3        sir        oas          1.591776 1.945704 1.443395  0.10572643
#> 4 0.8        sir        oas          1.790102 2.210610 1.578302 -0.01912106
#> 5 0.3         dr      ridge          1.765966 2.158093 1.659933 -0.14241246
#> 6 0.8         dr      ridge          1.538678 2.200191 1.639793  0.19368471
#> 7 0.3        sir      ridge          1.680301 1.755262 1.372652  0.05101130
#> 8 0.8        sir      ridge          1.701325 2.063218 1.474070  0.01778571
#>     Adjusted_R2 Correlation
#> 1  0.0576814062  0.35614342
#> 2 -0.0486723583  0.38306151
#> 3  0.0942613855  0.35977379
#> 4 -0.0383973649  0.29618806
#> 5 -0.1652264152  0.01675292
#> 6  0.1768756718  0.47358402
#> 7  0.0388447801  0.40795067
#> 8 -0.0005688661  0.36378528
```

The thesis simulations use substantially more replications. Small values
are used here only to keep package checks proportionate.

## Legacy Simulation A fixture

``` r

simulation_a <- utils::read.csv(system.file(
  "extdata",
  "simulation",
  "simulation_A_final_covariance_DR_summary_tidy.csv",
  package = "risdr"
))

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

OAS and ridge produce the lowest average condition numbers in the
supplied Simulation A record. Its external-prediction columns require a
corrected rerun under a shared true basis.

## Simulation B1 fixture

``` r

ranking_b1 <- utils::read.csv(system.file(
  "extdata",
  "simulation",
  "simulation_B1_overall_ranking.csv",
  package = "risdr"
))

ranking_b1[order(ranking_b1$avg_subspace_distance), ]
#>   sdr_method avg_subspace_distance avg_RMSE      avg_R2 avg_condition_number
#> 1         DR              1.895500 2.309850 -0.35607222             211.3530
#> 2        SIR              1.895578 2.455239 -0.53662222             211.5089
#> 3        PHD              1.912528 2.168078 -0.19206111             212.3132
#> 4       SAVE              1.937872 2.078517 -0.07530556             210.7767
#>   avg_runtime_seconds
#> 1          0.27097778
#> 2          0.08057778
#> 3          0.09651667
#> 4          0.17836667
```

DR has the best average subspace ranking in this supplied summary,
although the margin over SIR is small and scenario-level results should
also be examined. This legacy table is retained for traceability pending
the targeted rerun.

## Simulation B2 fixture

``` r

ranking_b2 <- utils::read.csv(system.file(
  "extdata",
  "simulation",
  "simulation_B2_overall_ranking.csv",
  package = "risdr"
))

ranking_b2[
  order(ranking_b2$avg_dimension_recovery_rate, decreasing = TRUE),
]
#>   sdr_method avg_dimension_recovery_rate avg_selected_d avg_sd_selected_d
#> 1         DR                 0.290833333       2.146667        1.16188889
#> 2        PHD                 0.207500000       2.266667        1.34311111
#> 3        SIR                 0.167777778       2.720000        1.23361111
#> 4       SAVE                 0.004166667       1.002778        0.04033333
#>   avg_condition_number avg_runtime_seconds
#> 1             210.5465          0.46459444
#> 2             210.9296          0.09940000
#> 3             211.0959          0.08013333
#> 4             211.7987          0.16837778
```

DR attains an average structural dimension recovery rate of
approximately 29.1 per cent in the supplied B2 ranking. Recovery remains
difficult across the complete design, so the result should be
interpreted comparatively rather than as evidence of uniformly accurate
dimension identification. B2 uses one training sample per replication
and is not affected by the train-test basis mismatch, but it should be
regenerated alongside the corrected simulation package for a single
auditable record.

## Reproducibility requirements

The repository includes `analysis/reproduce_simulations.R` and
`config.yml`. The corrected workflow reuses each training basis in its
corresponding test sample while preserving the original scenario order,
test predictors, error draws, and seed rule. It writes outputs with a
`_corrected_v0_3_0` suffix. From the repository root, run:

``` sh
Rscript analysis/reproduce_simulations.R config.yml
```

The default configuration retains the original scenario grid and 200
replications. A copied configuration with one replication can be used
for a preflight smoke run.

Each reported simulation should retain:

- the full scenario grid;
- the master seed and replication-specific seed rule;
- successful and failed replications;
- full replication-level outputs;
- the aggregation script;
- software and package versions;
- runtime and numerical-conditioning diagnostics.

## References
