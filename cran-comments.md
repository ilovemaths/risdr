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

This is a corrected resubmission of the first submission of `risdr` to CRAN.

The `inst/CITATION` file has been corrected for evaluation when the
package is not installed. The original file called `packageDescription()`
and subsequently retained two `meta$Version` expressions. These have now
been replaced with `meta[["Version"]]`, which supports the named atomic
metadata supplied during CRAN incoming checks.

The corrected CITATION file has been tested directly with atomic metadata
from DESCRIPTION and in a clean R session.

The words identified by the incoming spell check are intentional:

- Ledoit, Olorede, and Yahya are author surnames;
- MEC denotes Maximum Entropy Covariance; and
- `et al.` is a standard bibliographic abbreviation.

The package has no downstream dependencies.
