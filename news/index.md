# Changelog

## risdr 0.3.0

### Package interface

- Promoted repeated predictive cross-validation and complexity-aware
  cross-validation to the exported API.
- Added explicit `cov_args`, `stabilization_args`, and `sdr_args`
  controls to prevent component arguments from leaking into unrelated
  functions.
- Improved prediction for one-row inputs, reordered named columns, and
  alternative structural dimensions.
- Restricted the real-data workflow to its verified continuous-response
  scope.

### Numerical and validation changes

- Added ridge and Ledoit-Wolf covariance methods to central method
  validation.
- Replaced the observation-wise Ledoit-Wolf accumulation loop with an
  algebraically equivalent vectorised calculation.
- Vectorised the principal Hessian directions kernel calculation.
- Strengthened integer, missing-value, covariance, slice,
  survival-indicator, and resampling validation.
- Corrected `rho = 0` handling for AR(1) simulation and guarded
  sparse-basis generation when the predictor dimension is small.
- Added a user-supplied true-basis option and ensured that simulated
  training and test samples share the same central subspace.
- Made projection matrices robust to non-orthonormal full-rank bases.
- Return `NA` with a warning when MAPE is undefined because an observed
  value is zero.

### Documentation and release engineering

- Added five vignettes, a structured pkgdown configuration, a
  professional README, contribution guidance, issue templates, and
  release documentation.
- Expanded the testthat suite across validation, covariance estimation,
  SDR kernels, prediction, dimension selection, resampling, simulation,
  plotting, and real-data helpers.
- Added multi-platform R CMD check, test coverage, and pkgdown
  workflows.
- Added selected supplied thesis outputs under `inst/extdata` as
  provenance fixtures. Legacy simulation prediction outputs are
  explicitly marked for targeted rerun because the original script
  regenerated the true basis in the test sample.
- Added the supplied aligned EPI training and test matrices, with
  dimensions, column alignment, and SHA-256 provenance recorded in
  `inst/extdata/README.md`.
- Added a configurable corrected reproduction script for Simulations A,
  B1, and B2. Corrected files use distinct names and do not overwrite
  legacy outputs.

### Compatibility

- The principal user-facing function names from the supplied baseline
  are retained.
- Version metadata now records the agreed development release number,
  0.3.0.
