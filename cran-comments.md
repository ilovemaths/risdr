## Update from CRAN 0.3.1 to 0.4.0

This update adds sparse fitting for continuous, categorical and right-censored
survival responses, joint dimension and sparsity selection, a dual PCA workflow,
and prediction methods. The existing fit_risdr() interfaces and defaults are
retained. The maintainer, email address and GPL (>= 3) licence are unchanged.

## Final source archive

Source commit: 186f967d6c0b0f9378c20a1cd35285c20a27192a.
Archive: risdr_0.4.0.tar.gz, built on 10 October 2026.
SHA-256: 79d56c23669339bf8f5c1f8462d3503fc81e84acfa8ca582eeb750978398bd67.

## Full archive checks

Both checks completed on 10 October 2026 with 0 errors, 0 warnings and 0 notes:

- Local Windows 11 x64 (build 26200), R 4.6.1 (2026-06-24 ucrt):
  R CMD check --as-cran, including CRAN incoming feasibility checks.
- Win-builder, Windows Server 2022 x64 (build 20348),
  R-devel (2026-10-09 r90655 ucrt), check started at 13:05:05 UTC.

Examples, tests, vignette rebuilds and the PDF and HTML manuals passed in both
checks. Win-builder reported 488 passing assertions, with no failures,
warnings or skips.

A relative README provenance link previously produced a Win-builder NOTE.
It has been replaced by an immutable GitHub URL. The corrected archive passed
the Win-builder recheck without notes.

## Additional platform checks

GitHub Actions checked source commit 186f967 on 10 October 2026:

- macOS Tahoe 26.6.2: R 4.6.1.
- Windows Server 2022 x64 (build 26100): R 4.6.1.
- Ubuntu 24.04.5 LTS: R 4.6.1, R-devel (2026-10-08 r90650), and R 4.5.3.

All five jobs reported Status: OK and 488 passing assertions, with no failures,
warnings or skips. These jobs used --no-manual --as-cran, NOT_CRAN=true and
_R_CHECK_CRAN_INCOMING_=false. They check the source commit, rather than the
identical uploaded tarball bytes, and supplement the full archive checks above.

https://github.com/ilovemaths/risdr/actions/runs/38053926554

## Reverse dependencies

The maintainer's CRAN source-index query on 10 October 2026 found no reverse
Depends, Imports, LinkingTo, Suggests or Enhances entries for risdr.
