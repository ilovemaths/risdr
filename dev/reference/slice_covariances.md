# Compute slice covariance matrices

Computes slice-specific covariance matrices.

## Usage

``` r
slice_covariances(
  X,
  slices,
  stabilize = TRUE,
  stabilization = c("eigenfloor", "ridge", "nearest_pd"),
  eps = 1e-06
)
```

## Arguments

- X:

  Numeric matrix.

- slices:

  Integer slice memberships.

- stabilize:

  Logical. If TRUE, stabilises each slice covariance matrix.

- stabilization:

  Stabilisation method.

- eps:

  Eigenvalue floor.

## Value

A list of covariance matrices.
