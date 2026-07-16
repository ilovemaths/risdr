# risdr 0.3.0 release checklist

## Methodology and results

Confirm Maximum Entropy Covariance as the authoritative MEC definition.

Complete the corrected A/B1/B2 simulation run.

Review corrected summaries against the thesis interpretation.

Add the supplied processed EPI inputs and integrity checks.

## Native package checks

Run `devtools::document()` and review generated changes.

Run `devtools::test()` with no failures, errors, or unexpected warnings.

Run `R CMD build` from a clean checkout.

Run `R CMD check --as-cran` with 0 errors, 0 warnings, and 0 notes.

Confirm the multi-platform GitHub Actions matrix is green.

Review test coverage and address material untested branches.

Build and inspect every pkgdown article.

## Repository release

Add the final repository URL and issue tracker to `DESCRIPTION`.

Confirm the private security-reporting contact.

Confirm repository visibility, licence, branch protection, and Pages
settings.

Tag `v0.3.0` from the validated commit.

Attach the source archive, release notes, change manifest, and
checksums.

Archive the tagged release on Zenodo only after the public release is
final.

## CRAN preparation

Update `cran-comments.md` with the actual check environments and
results.

Run reverse-dependency checks if downstream packages exist.

Review package title, description, URLs, spelling, examples, and
references against current CRAN policy.

Submit only after all methodological and package check gates are closed.
