# Contributing to risdr

Contributions should preserve numerical reproducibility, backward
compatibility where practical, and the documented continuous-response
scope.

## Development workflow

1.  Create a focused branch from `main`.
2.  Add or update roxygen2 documentation for every public interface
    change.
3.  Add regression tests for numerical changes and failure-path tests
    for new validation.
4.  Run `devtools::document()`, `devtools::test()`, and
    `devtools::check(args = "--as-cran")`.
5.  Update `NEWS.md` when behaviour visible to users changes.
6.  Submit a pull request describing the statistical and software
    implications.

Do not alter accepted thesis results or estimator definitions without a
traceable methodological justification and explicit review.
