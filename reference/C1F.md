# C1F complexity and induced adaptive weights

Computes cumulative scale-invariant covariance complexity from leading
eigenvalues and converts the complexity profile to relative weights.

## Usage

``` r
C1F(evals, positive_only = TRUE, cumulative = TRUE, tol = 1e-10)
```

## Arguments

- evals:

  Numeric vector of eigenvalues.

- positive_only:

  Logical; retain only positive eigenvalues.

- cumulative:

  Logical; compute cumulative C1F values.

- tol:

  Numerical tolerance.

## Value

A list with C1F values, induced weights, and processed eigenvalues.
