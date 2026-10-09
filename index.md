# risdr

[![CRAN
status](https://www.r-pkg.org/badges/version/risdr)](https://CRAN.R-project.org/package=risdr)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21728850.svg)](https://doi.org/10.5281/zenodo.21728850)

`risdr` provides a reproducible framework for comparative sufficient
dimension reduction with covariance regularisation and
information-theoretic structural dimension selection. The existing
[`fit_risdr()`](https://ilovemaths.github.io/risdr/reference/fit_risdr.md)
interface supports continuous responses. Version 0.4.0 adds explicit
sparse, categorical, and survival interfaces without changing the 0.3.1
API.

The package implements:

- sliced inverse regression (SIR);
- sliced average variance estimation (SAVE);
- directional regression (DR);
- principal Hessian directions (pHd);
- sample, ridge, Oracle Approximating Shrinkage (OAS), Ledoit-Wolf (LW),
  and Maximum Entropy Covariance (MEC) estimators;
- AIC, BIC, CAIC, ICOMP, and CICOMP structural dimension criteria;
- V-fold, repeated, and complexity-aware cross-validation;
- prediction diagnostics, subspace recovery measures, simulation
  utilities, and base R plotting methods.

## Sparse and survival workflow

[`fit_risdr_sparse()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse.md)
implements the frozen thesis engine, including joint selection of
structural dimension and sparsity.
[`fit_risdr_dual()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_dual.md)
performs sample-space PCA for large predictor sets.
[`fit_risdr_sparse_realdata()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse_realdata.md)
adds outcome cleaning and a variance screen.

``` r

set.seed(2026)
X <- matrix(rnorm(100 * 8), nrow = 100)
colnames(X) <- paste0("Gene", seq_len(ncol(X)))
event_time <- rexp(100, rate = exp(0.5 * X[, 1]))
censor_time <- rexp(100, rate = 0.5)
time <- pmin(event_time, censor_time)
delta <- as.integer(event_time <= censor_time)
fit <- fit_risdr_sparse(
  X, time, delta = delta, response_type = "survival",
  sdr_method = "sir", cov_method = "oas", nslices = 4,
  d_max = 3, lambda_grid = c(0, 0.05, 0.1)
)
fit$selection_grid
predict(fit, X[1:2, , drop = FALSE], type = "risk")
```

Survival selection uses Efron Cox partial likelihood and defaults to
`support_penalty = FALSE`. C1F weights are contributions in predictor
coordinates. Dual variable rankings use the selected mapped directions;
thresholding PCA coordinates does not imply a sparse original-gene
support. These are exploratory methods. Independent validation and
proportional-hazards diagnostics must be performed separately for a
particular application.

See
[`vignette("sparse-survival", package = "risdr")`](https://ilovemaths.github.io/risdr/articles/sparse-survival.md)
and
[THESIS_PROVENANCE.md](https://ilovemaths.github.io/risdr/THESIS_PROVENANCE.md)
for migration and provenance.

## Development status

Version 0.4.0 is the sparse and survival release candidate. CRAN
currently publishes 0.3.1. The frozen thesis package was locally
versioned 0.3.2; its analysis provenance remains tied to that frozen
version.

Version 0.3.1 is the first CRAN release of `risdr`, published on 28 July
2026. It is available from CRAN with DOI \[10.32614/CRAN.package.risdr\]
(<https://doi.org/10.32614/CRAN.package.risdr>). The release is also
archived on Zenodo under version DOI \[10.5281/zenodo.21728851\]
(<https://doi.org/10.5281/zenodo.21728851>). The Zenodo concept DOI
\[10.5281/zenodo.21728850\] (<https://doi.org/10.5281/zenodo.21728850>)
identifies all archived versions.

## Installation

Install the current CRAN release with:

``` r

install.packages("risdr")
library(risdr)
```

Install the current development version from GitHub with:

``` r

install.packages(
  paste0(
    "https://github.com/ilovemaths/risdr/",
    "archive/refs/heads/main.tar.gz"
  ),
  repos = NULL,
  type = "source"
)
```

## Minimal example

``` r

library(risdr)

set.seed(2026)

sim <- simulate_risdr_data(
  n = 160,
  p = 20,
  d = 2,
  rho = 0.6,
  model = "linear_quadratic",
  seed = 2026
)

fit <- fit_risdr(
  X = sim$X,
  y = sim$y,
  sdr_method = "dr",
  cov_method = "oas",
  nslices = 6,
  d_max = 6,
  selector = "cicomp"
)

fit
summary(fit)

prediction <- predict(fit, sim$X[1:10, , drop = FALSE])
evaluate_prediction(sim$y[1:10], prediction, d = fit$d)
```

Component-specific arguments are separated explicitly:

``` r

fit_ridge <- fit_risdr(
  X = sim$X,
  y = sim$y,
  sdr_method = "sir",
  cov_method = "ridge",
  d = 2,
  d_max = 4,
  cov_args = list(lambda = 0.15),
  stabilization_args = list(eps = 1e-7),
  sdr_args = list(slice_type = "quantile")
)
```

## Structural dimension assessment

``` r

cv <- select_dimension_cv(
  X = sim$X,
  y = sim$y,
  sdr_method = "dr",
  cov_method = "oas",
  d_max = 5,
  v = 5,
  seed = 2026
)

cv$selected_d
cv$cv_table
```

See the package vignettes for the complete workflow, EPI case study,
simulation design, covariance regularisation, and structural dimension
selection.

## Scope and reproducibility

All stochastic examples expose seeds. Training-set centring and scaling
are stored in fitted objects and reused for prediction. The package
records failed resampling fits rather than silently discarding them.

The supplied processed EPI training and test matrices are included under
`inst/extdata/epi`, together with selected summary outputs from the
completed thesis. The original single-file EPI corpus is not
redistributed. Simulation fixtures are legacy records and must not be
treated as newly validated results.

The corrected Simulation A, B1, and B2 workflow is configured in
`config.yml` and can be run from the repository root with:

``` sh
Rscript analysis/reproduce_simulations.R config.yml
```

Corrected files receive a `_corrected_v0_3_0` suffix, so the workflow
cannot overwrite the supplied legacy results.

## Licence

`risdr` is released under GPL version 3 or later.
