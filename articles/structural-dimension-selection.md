# Structural Dimension Selection

## Selection problem

An SDR kernel produces an ordered basis, but the structural dimension
`d` must still be selected. `risdr` supports AIC, BIC, CAIC, ICOMP,
CICOMP, predictive cross-validation, a complexity-aware cross-validation
family, and a bootstrap ladle diagnostic. ICOMP adds a
covariance-complexity penalty to fit (Bozdogan 2000).

## Information criteria

``` r

library(risdr)

sim <- simulate_risdr_data(
  n = 150,
  p = 18,
  d = 2,
  rho = 0.6,
  seed = 8101
)

fit <- fit_risdr(
  sim$X,
  sim$y,
  sdr_method = "dr",
  cov_method = "oas",
  d_max = 6,
  selector = "cicomp"
)

fit$d_table
#>   d      AIC      BIC     CAIC    ICOMP   CICOMP
#> 1 1 660.3921 669.4240 672.4240 654.3921 672.4240
#> 2 2 658.7907 670.8332 674.8332 650.8030 674.8455
#> 3 3 659.0935 674.1466 679.1466 649.1082 679.1614
#> 4 4 656.7210 674.7848 680.7848 644.7438 680.8077
#> 5 5 650.6017 671.6761 678.6761 636.6444 678.7189
#> 6 6 652.1950 676.2800 684.2800 636.2426 684.3277
fit$d
#> [1] 1
```

Criterion weights provide a relative summary within the candidate set:

``` r

criterion_weights(fit$d_table, criterion = "CICOMP")
#>   d criterion    value     delta      weight
#> 1 1    CICOMP 672.4240  0.000000 0.717825375
#> 2 2    CICOMP 674.8455  2.421476 0.213895706
#> 3 3    CICOMP 679.1614  6.737312 0.024718952
#> 4 4    CICOMP 680.8077  8.383612 0.010852770
#> 5 5    CICOMP 678.7189  6.294824 0.030840050
#> 6 6    CICOMP 684.3277 11.903631 0.001867146
```

They are not posterior probabilities and do not establish that a
candidate set contains the true dimension.

## Predictive cross-validation

``` r

cv <- select_dimension_cv(
  sim$X,
  sim$y,
  sdr_method = "dr",
  cov_method = "oas",
  d_max = 5,
  v = 5,
  metric = "RMSE",
  seed = 8101
)

cv$selected_d
#> [1] 2
cv$cv_table
#>   d     RMSE      MAE     MAPE          R2 Adjusted_R2 Correlation   RMSE_SD
#> 1 1 2.245596 1.588181 268.1170 -0.06934088  -0.1075316   0.3330946 0.5269132
#> 2 2 2.224684 1.588382 263.9522 -0.06095109  -0.1395401   0.3638340 0.5314714
#> 3 3 2.227418 1.649312 289.6680 -0.06525169  -0.1881654   0.3596575 0.4792602
#> 4 4 2.297328 1.694058 306.2271 -0.15397446  -0.3386104   0.3148823 0.4433852
#> 5 5 2.266083 1.673718 296.4463 -0.13528239  -0.3717996   0.3431146 0.3907415
#>      MAE_SD  MAPE_SD     R2_SD Adjusted_R2_SD Correlation_SD
#> 1 0.2326622 181.3742 0.3853092      0.3990702      0.2456884
#> 2 0.2809521 180.6300 0.4262835      0.4578601      0.2668035
#> 3 0.2198026 219.1790 0.4108788      0.4582879      0.2213941
#> 4 0.2120002 212.2074 0.4959519      0.5753043      0.2254864
#> 5 0.2074032 223.7808 0.5028499      0.6076103      0.2398700
```

All standardisation and covariance estimation occur inside the training
fold. This prevents validation observations from influencing the fitted
projection.

## Complexity-aware cross-validation

For candidate `d`, the combined criterion rescales prediction error and
an information criterion to `[0,1]`, then uses

``` math
\operatorname{CVIC}(d)
= \widetilde{\operatorname{RMSE}}(d)
+ \lambda\widetilde{\operatorname{IC}}(d).
```

``` r

cv_icomp <- select_dimension_cv_icomp(
  sim$X,
  sim$y,
  sdr_method = "dr",
  cov_method = "oas",
  d_max = 5,
  v = 5,
  lambda = 1,
  seed = 8101
)

cv_icomp$cv_table
#>   d mean_RMSE mean_MAE     mean_R2 mean_Adjusted_R2 mean_Correlation mean_AIC
#> 1 1  2.245596 1.588181 -0.06934088       -0.1075316        0.3330946 525.9738
#> 2 2  2.224684 1.588382 -0.06095109       -0.1395401        0.3638340 525.5015
#> 3 3  2.227418 1.649312 -0.06525169       -0.1881654        0.3596575 522.7045
#> 4 4  2.297328 1.694058 -0.15397446       -0.3386104        0.3148823 522.1382
#> 5 5  2.266083 1.673718 -0.13528239       -0.3717996        0.3431146 522.3231
#>   mean_BIC mean_CAIC mean_ICOMP mean_CICOMP   sd_RMSE RMSE_scaled BIC_scaled
#> 1 534.3363  537.3363   519.9741    537.3366 0.5269132  0.28786345  0.0000000
#> 2 536.6514  540.6514   517.5090    540.6590 0.5314714  0.00000000  0.3087223
#> 3 536.6419  541.6419   512.7192    541.6566 0.4792602  0.03762589  0.3074508
#> 4 538.8632  544.8632   510.1631    544.8880 0.4433852  1.00000000  0.6036523
#> 5 541.8355  548.8355   508.3647    548.8772 0.3907415  0.56987646  1.0000000
#>   CAIC_scaled CICOMP_scaled     CVBIC    CVCAIC  CVCICOMP
#> 1   0.0000000     0.0000000 0.2878634 0.2878634 0.2878634
#> 2   0.2882958     0.2878924 0.3087223 0.2882958 0.2878924
#> 3   0.3744289     0.3743355 0.3450767 0.4120548 0.4119614
#> 4   0.6545592     0.6543393 1.6036523 1.6545592 1.6543393
#> 5   1.0000000     1.0000000 1.5698765 1.5698765 1.5698765
cv_icomp[c(
  "selected_d_rmse",
  "selected_d_cvbic",
  "selected_d_cvcaic",
  "selected_d_cvcicomp"
)]
#> $selected_d_rmse
#> [1] 2
#> 
#> $selected_d_cvbic
#> [1] 1
#> 
#> $selected_d_cvcaic
#> [1] 1
#> 
#> $selected_d_cvcicomp
#> [1] 1
```

`lambda` should be examined through sensitivity analysis. It is a
decision weight, not a parameter estimated by the likelihood.

## Ladle diagnostic

``` r

ladle <- select_dimension_ladle(
  sim$X,
  sim$y,
  sdr_method = "dr",
  cov_method = "oas",
  d_max = 4,
  B = 20,
  seed = 8101
)

ladle$selected_d
#> [1] 1
ladle$ladle_table
#>    d eigen_part stability_part     ladle
#> d1 1 0.08260507      0.1227946 0.2053996
#> d2 2 0.07765258      0.7236369 0.8012895
#> d3 3 0.06772307      0.8745900 0.9423130
#> d4 4 0.06367012      0.8922107 0.9558809
```

The implemented ladle is a diagnostic combining residual eigenvalue mass
with bootstrap subspace instability. It should be reported as a
complementary diagnostic rather than treated as an infallible selector.

## Decision protocol

A defensible selection report should state:

1.  the candidate range for `d`;
2.  the SDR and covariance estimators;
3.  the slicing and stabilisation settings;
4.  every criterion examined;
5.  the resampling design and seed;
6.  whether selectors agree;
7.  the sensitivity of substantive conclusions to `d`.

## References

Bozdogan, Hamparsum. 2000. “Akaike’s Information Criterion and Recent
Developments in Information Complexity.” *Journal of Mathematical
Psychology* 44 (1): 62–91. <https://doi.org/10.1006/jmps.1999.1277>.
