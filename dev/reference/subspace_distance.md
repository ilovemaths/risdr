# Subspace distance

Computes Frobenius distance between projection matrices.

## Usage

``` r
subspace_distance(B_hat, B)
```

## Arguments

- B_hat:

  Estimated basis matrix.

- B:

  True basis matrix.

## Value

Numeric subspace distance.

## Examples

``` r
B <- matrix(c(1, 0, 0, 0, 1, 0), nrow = 3)
transformed <- B %*% diag(c(2, 3))
subspace_distance(transformed, B)
#> [1] 0
```
