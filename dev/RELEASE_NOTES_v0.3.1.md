# risdr 0.3.1 release-candidate notes

## Status

Version 0.3.1 is the first CRAN release candidate for `risdr`. It is not
yet a CRAN release and must not be tagged until the final candidate
checks have passed and the CRAN submission outcome is known.

## CRAN hardening

- Added executable examples across the principal package workflows.
- Reviewed and reduced package dependencies to those used by package
  code, tests, examples, and vignettes.
- Added R-hub checking and a package spelling dictionary.
- Declared both `knitr` and `rmarkdown` as vignette builders.
- Confirmed the repository, issue tracker, pkgdown site, URLs, and
  citation records.
- Excluded the repository-level `CITATION.cff` file from CRAN source
  builds.
- Corrected structural-dimension examples so that successful examples do
  not emit expected dimension-reduction warnings.

## Validation entering Pass 4

- 177 testthat expectations passed.
- Local `R CMD check --as-cran` completed with 0 errors, 0 warnings, and
  0 notes.
- GitHub Actions checks passed on Windows, macOS, Ubuntu R-devel, Ubuntu
  R-release, and Ubuntu R-oldrel-1.
- Coverage, pkgdown, GitHub Pages, URL, and spelling checks passed.
- Selected R-hub Windows, macOS ARM64, ATLAS, `nosuggests`, and
  `donttest` checks passed.

## Citation status

DOI 10.5281/zenodo.21418002 identifies the archived 0.3.0 release and is
not assigned to the 0.3.1 candidate. The installed package citation
reports the installed version and the GitHub repository. After CRAN
acceptance and the v0.3.1 GitHub release, Zenodo can issue the
appropriate DOI for that release.

## Final release gates

The complete documentation, test, pkgdown, URL, spelling, CRAN-style,
and GitHub Actions checks must be rerun on the committed 0.3.1
candidate. The source tarball submitted to CRAN must be built from that
validated commit.
