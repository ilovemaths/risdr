# risdr 0.3.0 release notes

## Status

Version 0.3.0 is the first public development release of `risdr`. It was
published on GitHub and archived on Zenodo with DOI
10.5281/zenodo.21418002. It is not a CRAN release.

## Package changes

- Completed roxygen source documentation and manual coverage for the
  exported interface.
- Added five vignettes covering the core workflow, EPI case study,
  covariance regularisation, structural dimension selection, and
  simulation studies.
- Added topic-specific testthat coverage across numerical methods,
  validation, prediction, resampling, plots, simulation, and real-data
  helpers.
- Added explicit covariance, stabilisation, and SDR argument lists to
  prevent controls from leaking between components.
- Added one-observation prediction, named-column reordering, and
  validation for fixed alternative structural dimensions.
- Exported repeated predictive cross-validation and complexity-aware
  cross-validation.
- Added pkgdown, multi-platform R CMD check, coverage, issue-template,
  and contribution infrastructure.

## Reproducibility changes

- Added selected supplied EPI and simulation summaries as provenance
  fixtures.
- Added the aligned 180 by 70 EPI training and test predictor matrices
  and their paired responses, with SHA-256 provenance.
- Added `config.yml` and a checkpointed script for corrected Simulations
  A, B1, and B2.
- Added a user-supplied basis option to
  [`simulate_risdr_data()`](https://ilovemaths.github.io/risdr/reference/simulate_risdr_data.md).
- Corrected package simulation so that each training and test pair
  shares the same central subspace basis.
- Preserved historical simulation files under distinct legacy names.
  Corrected reruns use a `_corrected_v0_3_0` suffix.

## Validation status

The release passed 177 testthat expectations, a local CRAN-style check
with 0 errors, 0 warnings, and 0 notes, and the configured GitHub
Actions checks. The repository URL, issue tracker, pkgdown site, release
archive, and Zenodo record were published successfully.

## Post-release work

CRAN hardening continues under version 0.3.1. Corrected simulation
reruns remain separate reproducibility work and do not alter the
historical thesis results bundled as provenance fixtures.

Maximum Entropy Covariance is the confirmed, authoritative expansion of
MEC.
