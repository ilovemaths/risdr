## Update from CRAN 0.3.1 to 0.4.0

This is an update of the existing `risdr` package. The package name,
author and maintainer (Kabir Olorede, kabirolorede@gmail.com), licence
(GPL >= 3), CRAN DOI, and repository identity are unchanged.

The release adds an explicit sparse engine for continuous, categorical, and
right-censored survival responses, joint structural-dimension and sparsity
selection, and a dual PCA workflow. The existing continuous-response API is
retained. The additional engine derives from the locally frozen thesis package
0.3.2 and is isolated through renamed helpers and sparse fit classes.

## Validation

- Local platform: Ubuntu 24.04.3 LTS, x86_64, R 4.6.1 (2026-06-24).
- Existing CRAN regression suite and additional frozen-thesis and prediction
  regression cases pass.
- Full `R CMD build` rebuilds all six vignettes successfully.
- Source equivalence and synthetic reproduction are checked separately.
- `R CMD check --as-cran` on the source tarball: 0 errors, 0 warnings,
  0 notes. Examples, tests, vignette rebuilds, and PDF/HTML manuals pass.
  `_R_CHECK_CRAN_INCOMING_REMOTE_=false` was set because the remote incoming
  check did not complete in this environment. This is a local check result;
  remote URL/incoming and cross-platform checks remain to be completed.
- 39 regression tests, 245 assertions: no failures, errors, warnings, or skips.
- All 96 legacy CRAN function bodies and formals remain identical to 0.3.1.
- All 54 imported frozen function bodies and formals match after name/class
  restoration. Sparse, screened, and dual synthetic results match to 1e-12.
- Cross-platform validation is pending. Do not submit these comments until
  the current candidate has passed the Windows/macOS/R-devel release gates.
  No historical 0.3.2 check is claimed as a check of 0.4.0.

## Reverse dependencies

No reverse Depends, Imports, LinkingTo, Suggests, or Enhances entries were
found in CRAN's source PACKAGES index retrieved on 7 October 2026.

The source package contains small synthetic examples and tests; it does not
include patient-level thesis data or analysis checkpoints. The release-specific
provenance and source-generation tools are available in the GitHub repository
and excluded from the CRAN tarball.
