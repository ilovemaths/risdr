# risdr v0.3.1 change manifest

| Area | v0.3.0 post-release condition | v0.3.1 release-candidate action |
|----|----|----|
| Versioning | Development continued as 0.3.0.9000 | Set the first CRAN candidate to 0.3.1 without altering the v0.3.0 tag |
| Examples | Principal workflows lacked executable examples | Added and validated executable examples across the public interface |
| Example output | Three dimension-selection examples requested an inadmissible maximum and warned | Changed the examples to request the admissible maximum directly |
| Dependencies | Development and website packages remained in `Suggests` | Retained package-facing dependencies and moved workflow-only needs to `Config/Needs` |
| Vignettes | The `knitr::rmarkdown` engine required `rmarkdown` during `nosuggests` checking | Declared both `knitr` and `rmarkdown` in `VignetteBuilder` |
| Spelling | No package-specific spelling dictionary | Added `inst/WORDLIST` and completed the package spelling audit |
| URLs | The pkgdown site was not initially published | Published the site and passed the URL audit |
| Cross-platform checks | GitHub Actions checks were configured | Added R-hub and passed selected Windows, macOS, ATLAS, `nosuggests`, and `donttest` checks |
| Package citation | The installed citation was fixed at version 0.3.0 | Made it report the installed version and retained the v0.3.0 DOI only as an archive reference |
| Repository citation | `CITATION.cff` describes the archived v0.3.0 release | Clarified its scope and continued to exclude it from CRAN source builds |
| CRAN records | Initial comments did not include R-hub | Recorded the full local, GitHub Actions, and selected R-hub environments |
| Release records | v0.3.0 candidate records predated public release | Recorded the completed v0.3.0 release and added v0.3.1 candidate notes and gates |

No statistical method, numerical result, or frozen thesis conclusion is
changed by this release-candidate pass.
