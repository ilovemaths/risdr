# risdr 0.3.0 release notes

## Status

This archive is a development release candidate for repository review.
It is not yet a CRAN release and should not be tagged publicly until the
release gates below are closed.

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

R source, test, analysis, vignette-chunk, DESCRIPTION, YAML, and Rd
validation passed in the preparation environment. Semantic smoke tests
passed under webR 4.6.0. The user completed documentation generation and
an initial native test run. Its three failures were corrected in this
archive. A second native `devtools::test()` run and
`R CMD check --as-cran` remain mandatory before public release. See
`VALIDATION.md` for the exact record.

## Release gates

1.  Complete and review the corrected A/B1/B2 simulation run.
2.  Run native local and multi-platform checks and record 0 errors, 0
    warnings, and 0 notes.
3.  Add final repository and issue-tracker URLs.

Maximum Entropy Covariance is the confirmed, authoritative expansion of
MEC.
