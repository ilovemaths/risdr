# risdr
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21418002.svg)](https://doi.org/10.5281/zenodo.21418002)

`risdr` provides a reproducible framework for comparative sufficient
dimension reduction with covariance regularisation and information-theoretic
structural dimension selection. The current modelling interface supports
continuous responses.

The package implements:

- sliced inverse regression (SIR);
- sliced average variance estimation (SAVE);
- directional regression (DR);
- principal Hessian directions (pHd);
- sample, ridge, Oracle Approximating Shrinkage (OAS), Ledoit-Wolf (LW), and
  Maximum Entropy Covariance (MEC) estimators;
- AIC, BIC, CAIC, ICOMP, and CICOMP structural dimension criteria;
- V-fold, repeated, and complexity-aware cross-validation;
- prediction diagnostics, subspace recovery measures, simulation utilities,
  and base R plotting methods.

## Development status

## Development status

Version 0.3.0 is the first public development release of `risdr` and is 
permanently archived on Zenodo. Development continues under version 0.3.0.9000. 
The package has not yet been submitted to CRAN.

## Installation

Install the package from a local source directory with:

```r
install.packages("path/to/risdr", repos = NULL, type = "source")
```

During repository development, use:

```r
devtools::install("path/to/risdr")
```

## Minimal example

```r
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

```r
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

```r
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

See the package vignettes for the complete workflow, EPI case study, simulation
design, covariance regularisation, and structural dimension selection.

## Scope and reproducibility

All stochastic examples expose seeds. Training-set centring and scaling are
stored in fitted objects and reused for prediction. The package records failed
resampling fits rather than silently discarding them.

The supplied processed EPI training and test matrices are included under
`inst/extdata/epi`, together with selected summary outputs from the completed
thesis. The original single-file EPI corpus is not redistributed. Simulation
fixtures are legacy records and must not be treated as newly validated v0.3.0
results.

The corrected Simulation A, B1, and B2 workflow is configured in `config.yml`
and can be run from the repository root with:

```sh
Rscript analysis/reproduce_simulations.R config.yml
```

Corrected files receive a `_corrected_v0_3_0` suffix, so the workflow cannot
overwrite the supplied legacy results.

## Licence

`risdr` is released under GPL version 3 or later.
