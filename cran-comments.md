## Test environments

- Local Windows 11 x64, R 4.6.0
- GitHub Actions, macOS, R release
- GitHub Actions, Windows, R release
- GitHub Actions, Ubuntu, R devel
- GitHub Actions, Ubuntu, R release
- GitHub Actions, Ubuntu, R oldrel-1
- R-hub, Windows, R-devel
- R-hub, macOS ARM64, R-devel
- R-hub, Fedora Linux with ATLAS, R-devel
- R-hub, Fedora Linux without suggested packages, R-devel
- R-hub, Ubuntu Linux with `--run-donttest`, R-devel

## R CMD check results

There were 0 errors, 0 warnings, and 0 notes in the local CRAN-style check.
The GitHub Actions matrix and the selected R-hub checks completed
successfully.

## Resubmission

This is a resubmission of the first submission of `risdr` to CRAN.

The pretest issue concerning `inst/CITATION` has been corrected.
The file no longer calls `packageDescription()`, which requires the
package to be installed. It now uses the `meta` object supplied by
the standard R citation mechanism.

The words identified by the incoming spell check are intentional:

- Ledoit, Olorede, and Yahya are author surnames;
- MEC denotes Maximum Entropy Covariance; and
- `et al.` is a standard bibliographic abbreviation.

The package has no downstream dependencies.
