# Compute Directional Regression

Computes Directional Regression using the canonical pairwise-slice
formulation.

## Usage

``` r
compute_dr(
  X,
  y,
  Sigma = NULL,
  nslices = 6,
  slice_type = c("quantile", "equal_width"),
  stabilize_slices = TRUE,
  stabilization = c("eigenfloor", "ridge", "nearest_pd"),
  eps = 1e-08
)
```

## Arguments

- X:

  Numeric predictor matrix.

- y:

  Numeric response vector.

- Sigma:

  Covariance matrix used for standardisation.

- nslices:

  Number of response slices.

- slice_type:

  Slicing strategy.

- stabilize_slices:

  Logical. Stabilise slice covariance matrices.

- stabilization:

  Stabilisation method.

- eps:

  Eigenvalue floor.

## Value

A list containing DR kernel, eigenvalues, directions, scores, and
slices.

## Details

Directional Regression is computed using the pairwise-slice formulation.

\$\$ M\_{DR} = \sum_h \sum_k p_h p_k (2I_p - A\_{hk}) (2I_p -
A\_{hk})^\top \$\$

where

\$\$ A\_{hk} = \Sigma_h + \Sigma_k + (\mu_h - \mu_k) (\mu_h -
\mu_k)^\top \$\$

## Examples

``` r
X <- as.matrix(mtcars[, c("disp", "hp", "wt")])
fit <- compute_dr(X, y = mtcars$mpg, nslices = 4)
head(fit$eigenvalues)
#> [1] 4.067756 1.959709 1.590711
```
