# Sparse and survival SDR: the frozen thesis engine

## Choosing the interface

Version 0.4.0 extends the existing `risdr` package.
[`fit_risdr()`](https://ilovemaths.github.io/risdr/reference/fit_risdr.md)
continues to use the continuous-response engine published in 0.3.1,
including its component argument lists, defaults, prediction, and
cross-validation tools. The additional engine has explicit entry points:

| Entry point | Purpose |
|:---|:---|
| [`fit_risdr_sparse()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse.md) | Joint dimension and sparsity selection |
| [`fit_risdr_sparse_realdata()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse_realdata.md) | Outcome cleaning and variance screening |
| [`fit_risdr_dual()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_dual.md) | Sample-space PCA and mapping to predictor coordinates |

The sparse engine accepts continuous, categorical, and right-censored
survival responses. It requires covariance stabilisation and uses C1F
complexity. It does not replace the existing C1/C1F continuous-response
selector.

The locally frozen thesis package was versioned 0.3.2. Its
[`fit_risdr()`](https://ilovemaths.github.io/risdr/reference/fit_risdr.md)
calls map to
[`fit_risdr_sparse()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse.md)
in this release, and its
[`fit_risdr_realdata()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_realdata.md)
calls map to
[`fit_risdr_sparse_realdata()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse_realdata.md).
The numerical engine is preserved; private helper names and the sparse
fit classes isolate it from the existing API. The original thesis
results remain associated with the frozen 0.3.2 sources.

## A reproducible censored-survival example

This example uses synthetic data and does not reproduce the thesis
cohort.

``` r

set.seed(2026)
X <- matrix(rnorm(100 * 8), nrow = 100)
colnames(X) <- paste0("Gene", seq_len(ncol(X)))
event_time <- rexp(100, rate = exp(0.5 * X[, 1] - 0.3 * X[, 2]))
censor_time <- rexp(100, rate = 0.5)
time <- pmin(event_time, censor_time)
delta <- as.integer(event_time <= censor_time)
table(delta)
#> delta
#>  0  1 
#> 32 68
```

The event indicator is 1 for an observed event and 0 for a
right-censored record. Time units must be consistent and recorded by the
analyst. Four quantile slices are formed within each censoring-status
group, yielding up to eight occupied slices. The engine uses these
labels in SIR, SAVE, and canonical pairwise-slice DR. This slicing
convention is part of the frozen methodology; it does not by itself
establish robustness to informative censoring.

``` r

fit <- fit_risdr_sparse(
  X, time, delta = delta, response_type = "survival",
  sdr_method = "sir", cov_method = "oas", nslices = 4,
  d_max = 3, selector = "cicomp", lambda_grid = c(0, 0.05, 0.1),
  support_penalty = FALSE
)
c(d = fit$d, lambda = fit$best_lambda)
#>      d lambda 
#>    1.0    0.1
fit$selection_grid
#>   d lambda n_active active_fraction      AIC      BIC     CAIC    ICOMP
#> 1 1   0.00        8           1.000 485.0674 487.6725 488.6725 485.0674
#> 2 1   0.05        5           0.625 484.2954 486.9006 487.9006 484.2954
#> 3 1   0.10        5           0.625 482.9405 485.5456 486.5456 482.9405
#> 4 2   0.00        8           1.000 485.4539 490.6643 492.6643 485.4606
#> 5 2   0.05        8           1.000 484.2702 489.4806 491.4806 484.2745
#> 6 2   0.10        8           1.000 482.8664 488.0768 490.0768 482.8739
#> 7 3   0.00        8           1.000 487.2037 495.0192 498.0192 487.2273
#> 8 3   0.05        8           1.000 486.1039 493.9194 496.9194 486.1231
#> 9 3   0.10        8           1.000 484.6162 492.4317 495.4317 484.6356
#>     CICOMP    logLik k_eff         C1F valid error_message
#> 1 488.6725 -241.5337     1 0.000000000  TRUE          <NA>
#> 2 487.9006 -241.1477     1 0.000000000  TRUE          <NA>
#> 3 486.5456 -240.4702     1 0.000000000  TRUE          <NA>
#> 4 492.6709 -240.7270     2 0.003324267  TRUE          <NA>
#> 5 491.4849 -240.1351     2 0.002146379  TRUE          <NA>
#> 6 490.0842 -239.4332     2 0.003725648  TRUE          <NA>
#> 7 498.0429 -240.6018     3 0.011829932  TRUE          <NA>
#> 8 496.9386 -240.0519     3 0.009616082  TRUE          <NA>
#> 9 495.4511 -239.3081     3 0.009667642  TRUE          <NA>
```

For each dimension and lambda, a Cox model is fitted to the
corresponding reduced predictors using Efron ties. Write its partial log
likelihood as `ell`, and the effective count as `k`. With the thesis
default `support_penalty = FALSE`, `k = d` for survival outcomes. The
criteria are:

- AIC: `-2 * ell + 2 * k`;
- BIC: `-2 * ell + k * log(n)`;
- CAIC: `-2 * ell + k * (log(n) + 1)`;
- ICOMP: `-2 * ell + 2 * k + 2 * C1F`;
- CICOMP: `-2 * ell + k * (log(n) + 1) + 2 * C1F`.

C1F is computed from the covariance of the reduced predictors. The final
pair minimises the requested criterion across the candidate grid. An
explicitly fixed `d` instead selects lambda within that dimension.
Failed candidates are recorded in the grid. All comparisons must use
compatible outcomes and samples.

## Variable selection

Adaptive weights distribute C1F over predictor coordinates using squared
covariance eigenvector entries. They are normalised to mean one.
Weighted soft thresholding operates on the direction entries. The frozen
safeguard restores a dense direction if thresholding removes it
entirely, so support size need not decrease monotonically over every
lambda grid.

``` r

B <- fit$directions
support <- data.frame(variable = rownames(B), norm = sqrt(rowSums(B^2)))
support <- support[support$norm > 1e-8, , drop = FALSE]
support[order(support$norm, decreasing = TRUE), , drop = FALSE]
#>       variable        norm
#> Gene2    Gene2 0.842527323
#> Gene1    Gene1 0.491998983
#> Gene5    Gene5 0.194854769
#> Gene8    Gene8 0.100299929
#> Gene7    Gene7 0.007500305
```

The screened wrapper applies its variance filter after cleaning
incomplete outcomes. Its `selected_variables` table reports the active
row norms of the selected direction matrix. A nonzero loading or a high
rank is a descriptive selection result, not a significance test or a
validated biological marker.

## The dual workflow

``` r

dual <- fit_risdr_dual(
  X, time, delta = delta, response_type = "survival",
  dual_rank = 5, d_max = 3, sdr_method = "sir", cov_method = "oas",
  lambda_grid = c(0, 0.05, 0.1), gene_select_top = 4, verbose = FALSE
)
dual$selected_variables
#>       index variable loading_norm
#> Gene2     2    Gene2    0.6182322
#> Gene5     5    Gene5    0.4941704
#> Gene8     8    Gene8    0.2693501
#> Gene7     7    Gene7    0.1941564
```

The dual path forms the sample-space Gram matrix, avoiding a full
predictor covariance. It retains PCA scores and fits the sparse engine
in that score space. The inner standardisation is undone before mapping
selected directions through PCA loadings. The ranking uses the row
Euclidean norms of those selected mapped directions. Dense-direction
mappings are separately retained. Sparsity among retained PCA
coordinates does not generally yield zero loadings for original
predictors. `gene_select_top` and `gene_select_quantile` therefore
define a ranking rule and must be reported separately from coordinate
sparsity.

## Prediction and diagnostics

``` r

predict(fit, X[1:2, , drop = FALSE], type = "scores")
#>               Z1
#> [1,] -0.96069592
#> [2,]  0.07133456
predict(fit, X[1:2, , drop = FALSE], type = "risk")
#>        1        2 
#> 0.560253 1.043958
predict(dual, X[1:2, , drop = FALSE], type = "scores")
#>              Z1
#> [1,] -0.9523254
#> [2,]  0.2836475
```

Survival predictions are Cox linear predictors or relative risks, not
survival times. Training predictor names are checked and reordered; the
training centres and scales are reused. The prediction adapters do not
change the frozen fits.

``` r

survival::cox.zph(fit$downstream_fit, transform = "km", terms = TRUE, global = TRUE)
#>        chisq df   p
#> Z1     0.149  1 0.7
#> GLOBAL 0.149  1 0.7
```

Proportional-hazards diagnostics apply to the downstream model actually
fitted. A small diagnostic p value indicates evidence of departure from
proportional hazards; a nonsignificant value is not proof of the
assumption. The model above uses all selected coordinates. A diagnostic
for a separate first-coordinate model addresses that separate model.

Apparent in-sample criteria, concordance, and Kaplan-Meier separation do
not constitute external validation. For out-of-sample assessment, repeat
all outcome-dependent selection and preprocessing within training
partitions. The existing continuous-response cross-validation utilities
do not evaluate the new survival engine. An independent cohort remains
necessary for external validation of a particular application.
