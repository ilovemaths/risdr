# Dual PCA score construction for p much larger than n

Constructs low-rank sample-space scores without forming a p by p
covariance matrix. This is useful when the number of predictors is very
large.

## Usage

``` r
dual_pca_scores(
  X,
  dual_rank = NULL,
  variance_explained = NULL,
  center = TRUE,
  scale_X = TRUE,
  eps = 1e-10
)
```

## Arguments

- X:

  Numeric predictor matrix with observations in rows.

- dual_rank:

  Number of dual components to retain.

- variance_explained:

  Optional cumulative variance threshold.

- center:

  Logical; if TRUE, centre predictors.

- scale_X:

  Logical; if TRUE, scale predictors.

- eps:

  Numerical tolerance.

## Value

A list containing scores, loadings, singular values, centre, scale, and
retained rank.
