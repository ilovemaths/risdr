# risdr 0.3.1 CRAN release-candidate checklist

## Completed hardening

- [x] Confirm Maximum Entropy Covariance as the authoritative MEC definition.
- [x] Add the supplied processed EPI inputs and integrity checks.
- [x] Complete roxygen documentation and executable examples.
- [x] Pass all 177 testthat expectations.
- [x] Pass a local CRAN-style check with 0 errors, 0 warnings, and 0 notes.
- [x] Pass the GitHub Actions check matrix, coverage workflow, and pkgdown
  build.
- [x] Pass selected R-hub Windows, macOS, ATLAS, `nosuggests`, and `donttest`
  checks.
- [x] Pass URL and spelling audits.
- [x] Confirm the GitHub repository, issue tracker, pkgdown site, licence, and
  citation records.

## Final candidate validation

- [x] Apply the Pass 4 archive to a clean `main` branch.
- [x] Run `devtools::document()` and review the generated changes.
- [x] Run `devtools::test()` with no failures, errors, or unexpected warnings.
- [x] Run `pkgdown::build_site(preview = FALSE)` successfully.
- [x] Run `devtools::check(args = "--as-cran")` with 0 errors, 0 warnings, and
  0 notes.
- [x] Confirm `urlchecker::url_check(path = ".")` reports that all URLs are
  correct.
- [x] Confirm `spelling::spell_check_package()` reports no spelling errors.
- [ ] Commit and push the validated 0.3.1 candidate.
- [ ] Confirm the final GitHub Actions workflows are green.
- [ ] Build and inspect the source tarball from the committed candidate.
- [ ] Submit the source tarball and `cran-comments.md` through the CRAN web
  form.

## After CRAN acceptance

- [ ] Tag the accepted commit as `v0.3.1`.
- [ ] Publish the GitHub v0.3.1 release with source archive, release notes,
  change manifest, and checksums.
- [ ] Allow Zenodo to archive v0.3.1 and record its version DOI.
- [ ] Update repository citation metadata for the newly archived version.
- [ ] Begin the next development version without altering the accepted tag.
