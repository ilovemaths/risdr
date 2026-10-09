# Compute adaptive penalty weights from C1F variable contributions

For `mode = "c1f"`, the regularised covariance matrix is decomposed into
original-coordinate C1F contributions. Variables with larger
contribution receive smaller soft-threshold weights, matching the
direction of the historical C1F weighting rule while avoiding the
invalid mapping of eigenvalue indices directly to predictor indices.
`inverse_c1f` reverses that weighting. `uniform` returns equal weights.

## Usage

``` r
compute_penalty_weights(
  Sigma,
  mode = c("c1f", "inverse_c1f", "uniform"),
  tol = 1e-10
)
```

## Arguments

- Sigma:

  Regularised covariance matrix.

- mode:

  One of `"c1f"`, `"inverse_c1f"`, or `"uniform"`.

- tol:

  Numerical tolerance.

## Value

Numeric vector of variable-level penalty weights with mean one.
