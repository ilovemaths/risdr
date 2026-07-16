# Getting Started with risdr

## Purpose

Sufficient dimension reduction seeks a low-dimensional projection
`\mathbf{B}^{\mathsf{T}}\mathbf{X}` that retains the information in the
predictors `\mathbf{X}` about a response `Y`. The working condition is

``` math
Y \perp\!\!\!\perp \mathbf{X}\mid \mathbf{B}^{\mathsf{T}}\mathbf{X}.
```

`risdr` combines classical inverse-regression estimators with covariance
regularisation, structural dimension criteria, prediction, and
resampling. The implemented SDR methods are SIR (Li 1991), SAVE (Cook
1998), DR (Li and Wang 2007), and pHd (Li 1992).

## A reproducible example

``` r

library(risdr)

sim <- simulate_risdr_data(
  n = 160,
  p = 20,
  d = 2,
  rho = 0.6,
  sigma = 0.7,
  model = "linear_quadratic",
  seed = 2026
)
```

The simulation object contains the predictor matrix, response, true
central subspace basis, sufficient predictors, population covariance
matrix, signal, noise, and generation settings.

``` r

str(sim[c("X", "y", "beta", "Sigma", "n", "p", "d")], max.level = 1)
#> List of 7
#>  $ X    : num [1:160, 1:20] -0.1856 0.3702 1.0379 -1.3835 0.0863 ...
#>   ..- attr(*, "dimnames")=List of 2
#>  $ y    : num [1:160] 0.529 0.825 0.23 2.94 0.33 ...
#>  $ beta : num [1:20, 1:2] -1 0 0 0 0 0 0 0 0 0 ...
#>   ..- attr(*, "dimnames")=List of 2
#>  $ Sigma: num [1:20, 1:20] 1 0.6 0.36 0.216 0.13 ...
#>  $ n    : int 160
#>  $ p    : int 20
#>  $ d    : int 2
```

## Fit an SDR model

``` r

fit <- fit_risdr(
  X = sim$X,
  y = sim$y,
  sdr_method = "dr",
  cov_method = "oas",
  nslices = 6,
  d_max = 6,
  selector = "cicomp",
  standardize = TRUE,
  stabilize = TRUE
)

fit
#> Regularised and Information-Theoretic SDR fit
#> --------------------------------------------------
#> SDR method       : DR 
#> Covariance       : OAS 
#> Stabilised       : TRUE 
#> Stabilisation    : eigenfloor 
#> Selected d       : 1 
#> Selector         : CICOMP 
#> Number of slices : 6 
#> Observations     : 160 
#> Predictors       : 20
summary(fit)
#> Summary of risdr fit
#> --------------------------------------------------
#> Method              : DR 
#> Covariance          : OAS 
#> Selected dimension  : 1 
#> Selector            : CICOMP 
#> 
#> Leading eigenvalues:
#>  [1] 3.634354 2.243110 2.134463 1.943940 1.770799 1.691899 1.498929 1.477956
#>  [9] 1.344769 1.231138
#> 
#> Dimension selection table:
#>   d      AIC      BIC     CAIC    ICOMP   CICOMP
#> 1 1 560.7544 569.9800 572.9800 554.7545 572.9800
#> 2 2 559.4677 571.7684 575.7684 551.4737 575.7744
#> 3 3 560.9913 576.3672 581.3672 551.0004 581.3762
#> 4 4 561.0808 579.5318 585.5318 549.1041 585.5552
#> 5 5 561.6532 583.1794 590.1794 547.6779 590.2041
#> 6 6 563.4381 588.0395 596.0395 547.4700 596.0714
#> 
#> Covariance diagnostics:
#> $min_eigenvalue
#> [1] 0.2623297
#> 
#> $max_eigenvalue
#> [1] 3.79275
#> 
#> $condition_number
#> [1] 14.45795
#> 
#> $effective_rank
#> [1] 20
```

The fitted object stores the training transformations, covariance
estimate, kernel, eigenvalues, directions, scores, dimension-selection
table, and downstream linear model.

## Inspect the structural dimension

``` r

fit$d_table
#>   d      AIC      BIC     CAIC    ICOMP   CICOMP
#> 1 1 560.7544 569.9800 572.9800 554.7545 572.9800
#> 2 2 559.4677 571.7684 575.7684 551.4737 575.7744
#> 3 3 560.9913 576.3672 581.3672 551.0004 581.3762
#> 4 4 561.0808 579.5318 585.5318 549.1041 585.5552
#> 5 5 561.6532 583.1794 590.1794 547.6779 590.2041
#> 6 6 563.4381 588.0395 596.0395 547.4700 596.0714
criterion_weights(fit$d_table, criterion = "CICOMP")
#>   d criterion    value     delta       weight
#> 1 1    CICOMP 572.9800  0.000000 7.909083e-01
#> 2 2    CICOMP 575.7744  2.794353 1.955870e-01
#> 3 3    CICOMP 581.3762  8.396212 1.188261e-02
#> 4 4    CICOMP 585.5552 12.575162 1.470498e-03
#> 5 5    CICOMP 590.2041 17.224054 1.438700e-04
#> 6 6    CICOMP 596.0714 23.091362 7.654213e-06
```

Information criteria answer a model-selection question, while predictive
cross-validation estimates out-of-fold error. Both should be considered
when the selected dimension is consequential.

``` r

cv <- select_dimension_cv(
  X = sim$X,
  y = sim$y,
  sdr_method = "dr",
  cov_method = "oas",
  d_max = 5,
  v = 5,
  nslices = 6,
  metric = "RMSE",
  seed = 2026
)

cv$selected_d
#> [1] 5
cv$cv_table
#>   d     RMSE      MAE     MAPE        R2 Adjusted_R2 Correlation   RMSE_SD
#> 1 1 1.509921 1.150112 277.4364 0.2987924   0.2754188   0.5873461 0.3460575
#> 2 2 1.522493 1.170013 277.8302 0.2819188   0.2323960   0.5846151 0.3108127
#> 3 3 1.531634 1.175546 274.6675 0.2731524   0.1952758   0.5812997 0.3076956
#> 4 4 1.528949 1.154160 250.3702 0.2753834   0.1680328   0.5867733 0.3005304
#> 5 5 1.497563 1.131756 256.1141 0.3084383   0.1754457   0.6062244 0.3178904
#>      MAE_SD  MAPE_SD      R2_SD Adjusted_R2_SD Correlation_SD
#> 1 0.1984016 97.72818 0.08730388     0.09021401     0.06870146
#> 2 0.1601640 88.99401 0.07229332     0.07727906     0.05240008
#> 3 0.1592277 77.72723 0.06296755     0.06971407     0.04719015
#> 4 0.1607890 70.43618 0.05217703     0.05990696     0.05018539
#> 5 0.1738771 59.61053 0.04237436     0.05052327     0.06083891
```

## Prediction

Prediction applies the training centre, scale, SDR centre, and estimated
directions to new observations before invoking the downstream model.

``` r

predicted <- predict(fit, sim$X[1:12, , drop = FALSE])
evaluate_prediction(
  y_true = sim$y[1:12],
  y_pred = predicted,
  d = fit$d
)
#>       RMSE      MAE     MAPE        R2 Adjusted_R2 Correlation
#> 1 1.786263 1.238927 330.4118 0.2916926   0.2208618   0.6042497
```

Named columns may be supplied in a different order. They are checked and
reordered to the training layout. A single new observation is also
valid.

## Component-specific controls

Arguments for covariance estimation, covariance stabilisation, and SDR
kernels are supplied separately. This prevents a control intended for
one component from being passed to another component.

``` r

fit_ridge <- fit_risdr(
  X = sim$X,
  y = sim$y,
  sdr_method = "sir",
  cov_method = "ridge",
  d = 2,
  d_max = 5,
  cov_args = list(lambda = 0.15),
  stabilization_args = list(eps = 1e-7),
  sdr_args = list(slice_type = "quantile")
)
```

## Diagnostics

``` r

plot_scree(fit, n_eigen = 10)
plot_sufficient(fit, direction = 1)
plot_dimension_selection(fit)
```

![](getting-started_files/figure-html/unnamed-chunk-8-1.png)![](getting-started_files/figure-html/unnamed-chunk-8-2.png)![](getting-started_files/figure-html/unnamed-chunk-8-3.png)

Loadings and sufficient summary plots are descriptive. Signs of
eigenvectors are not identified, so sign reversals across numerically
equivalent fits do not change the estimated subspace.

## Current scope

The verified modelling interface in version 0.3.0 is for continuous
responses. The standalone MEC covariance helper accepts additional
working response forms, but binary, multiclass, and censored survival
modelling are not yet claimed as complete `risdr` workflows.

## References

Cook, R. Dennis. 1998. *Regression Graphics: Ideas for Studying
Regressions Through Graphics*. Wiley.
<https://doi.org/10.1002/9780470316931>.

Li, Bing, and Shaoli Wang. 2007. “On Directional Regression for
Dimension Reduction.” *Journal of the American Statistical Association*
102 (479): 997–1008. <https://doi.org/10.1198/016214507000000536>.

Li, Ker-Chau. 1991. “Sliced Inverse Regression for Dimension Reduction.”
*Journal of the American Statistical Association* 86 (414): 316–27.
<https://doi.org/10.1080/01621459.1991.10475035>.

Li, Ker-Chau. 1992. “On Principal Hessian Directions for Data
Visualization and Dimension Reduction: Another Application of Stein’s
Lemma.” *Journal of the American Statistical Association* 87 (420):
1025–39. <https://doi.org/10.1080/01621459.1992.10476258>.
