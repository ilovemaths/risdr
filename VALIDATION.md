# Validation record for risdr 0.3.0

Date: 16 July 2026

## Completed in the preparation environment

- Parsed every package R source file under R 4.6.0.
- Parsed every testthat and analysis R file.
- Parsed all executable R chunks in the five vignettes.
- Parsed all five complete vignette documents with Pandoc and resolved
  their BibTeX citations.
- Parsed every Rd file and passed each through
  [`tools::checkRd()`](https://rdrr.io/r/tools/checkRd.html).
- Passed the strict base-R package-description validation.
- Ran semantic smoke tests covering all SDR kernels, all five covariance
  methods, model fitting, one-row and multi-row prediction, information
  criteria, ordinary and complexity-aware cross-validation, repeated
  predictive cross-validation, the Ladle diagnostic, the
  continuous-response real-data wrapper, shared-basis simulation, and a
  complete simulation replication.
- Parsed all repository, workflow, pkgdown, and simulation YAML files.
- Confirmed that every exported function has a corresponding manual
  alias and roxygen parameter and return-value documentation.
- Passed [`tools::codoc()`](https://rdrr.io/r/tools/codoc.html),
  [`tools::checkDocFiles()`](https://rdrr.io/r/tools/QC.html), and
  [`tools::checkDocStyle()`](https://rdrr.io/r/tools/QC.html) against
  the source tree.
- Confirmed that package prose contains no em dash and that project
  files contain no absolute Windows paths.

## Native R test feedback

The user ran `devtools::document()` successfully and then ran
`devtools::test()`. The first native test run reported 165 passes and
three failures. The failures identified:

- partial matching of `d` to the real-data wrapper’s `delta` argument;
- harmless dimnames in an orthonormality comparison;
- QR sign indeterminacy when an already orthonormal basis was supplied.

Version 0.3.0 now exposes `d` explicitly in
[`fit_risdr_realdata()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_realdata.md),
preserves an already orthonormal supplied basis, and compares the Gram
matrix without dimnames. Targeted semantic checks for all three
corrections pass under webR. A second native test run is still required.

The preparation environment does not provide a native R installation.
After these corrections, run:

``` r

devtools::test()
devtools::check(args = "--as-cran")
```

Run `devtools::document()` once more if roxygen-generated files differ
from the files in this archive.

The GitHub Actions workflows are configured to run documentation
generation, test coverage, pkgdown, and multi-platform R CMD check after
repository publication. A 0 error, 0 warning, 0 note status must be
recorded before a CRAN submission or public release is described as
CRAN-ready.

## Methodological release gates

1.  Run the corrected Simulation A and B1 workflow because the supplied
    legacy script regenerated the random-sparse basis for each test
    sample.
2.  Regenerate Simulation B2 in the same auditable run.
3.  Complete the native R checks listed above.
