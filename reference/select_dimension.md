# Select structural dimension

Fits linear models on SDR scores for candidate dimensions and computes
information criteria.

## Usage

``` r
select_dimension(
  scores,
  y,
  d_max = 10,
  complexity = c("C1", "C1F"),
  eps = 1e-10
)
```

## Arguments

- scores:

  Matrix of SDR scores.

- y:

  Numeric response vector.

- d_max:

  Maximum candidate dimension.

- complexity:

  Complexity measure for ICOMP.

- eps:

  Eigenvalue floor.

## Value

A data frame of criteria by candidate dimension.
