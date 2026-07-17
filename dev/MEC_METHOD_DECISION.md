# MEC methodological decision

MEC means Maximum Entropy Covariance throughout `risdr`.

The authoritative implementation is
[`cov_mec()`](https://ilovemaths.github.io/risdr/dev/reference/cov_mec.md),
which constructs response-specific slices, selects the slice covariance
with the largest stabilised log determinant, and combines it with the
pooled covariance through convex shrinkage. Package documentation,
release notes, and software papers must use this expansion and
mathematical definition consistently.
