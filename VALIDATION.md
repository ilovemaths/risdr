# Validation record for risdr 0.3.1

Date: 19 July 2026

## Completed before the release-candidate update

- Generated package documentation successfully with `devtools::document()`.
- Passed 177 testthat expectations with no failures, warnings, or skips.
- Passed a local Windows CRAN-style check with 0 errors, 0 warnings, and
  0 notes.
- Passed GitHub Actions checks on macOS with R release, Windows with R release,
  and Ubuntu with R devel, R release, and R oldrel-1.
- Passed the GitHub Actions coverage and pkgdown workflows.
- Passed R-hub checks on Windows R-devel, macOS ARM64 R-devel, Fedora Linux
  with ATLAS, Fedora Linux without suggested packages, and Ubuntu Linux with
  `--run-donttest`.
- Passed URL checking after publication of the pkgdown site.
- Passed package and vignette spelling checks using `inst/WORDLIST`.
- Confirmed that `CITATION.cff` is excluded from source-package builds while
  `inst/CITATION` remains available in the installed package.

## Release-candidate changes

- Set the candidate package version to 0.3.1 because 0.3.0 is already an
  immutable public GitHub and Zenodo release.
- Made the installed-package citation report the installed package version.
- Retained DOI 10.5281/zenodo.21418002 exclusively as the identifier for the
  archived 0.3.0 release.
- Replaced three intentionally over-large structural-dimension requests in
  examples with the admissible maximum, preventing expected warning output.
- Updated release status, CRAN comments, validation records, and release
  checklists.

## Final local validation completed

The Pass 4 changes affect documentation and release metadata rather than the
statistical implementation. The following checks were rerun successfully
on Windows 11 with R 4.6.0:

```r
devtools::document()
devtools::test()
pkgdown::build_site(preview = FALSE)
devtools::check(args = "--as-cran")
urlchecker::url_check(path = ".")
spelling::spell_check_package(
  pkg = ".",
  vignettes = TRUE,
  use_wordlist = TRUE
)
```

All local Pass 4 checks completed successfully with 0 errors, 0 warnings, and 0 notes.
The candidate remains pending the final GitHub Actions and R-hub checks.
