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
#> 1 1 638.1861 647.2180 650.2180 632.1862 650.2181
#> 2 2 639.3422 651.3848 655.3848 631.3436 655.3861
#> 3 3 639.8529 654.9061 659.9061 629.8567 659.9098
#> 4 4 640.3308 658.3946 664.3946 628.3386 664.4024
#> 5 5 642.3164 663.3909 670.3909 628.3290 670.4034
#> 6 6 637.9945 662.0795 670.0795 622.0150 670.1001
fit$d
#> [1] 1
```

Criterion weights provide a relative summary within the candidate set:

``` r

criterion_weights(fit$d_table, criterion = "CICOMP")
#>   d criterion    value     delta       weight
#> 1 1    CICOMP 650.2181  0.000000 9.222943e-01
#> 2 2    CICOMP 655.3861  5.168020 6.960625e-02
#> 3 3    CICOMP 659.9098  9.691763 7.249866e-03
#> 4 4    CICOMP 664.4024 14.184296 7.669884e-04
#> 5 5    CICOMP 670.4034 20.185345 3.816608e-05
#> 6 6    CICOMP 670.1001 19.881974 4.441746e-05
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
#> [1] 1
cv$cv_table
#>   d     RMSE      MAE     MAPE          R2 Adjusted_R2 Correlation   RMSE_SD
#> 1 1 2.095089 1.552059 361.6320 -0.02819197 -0.06491311   0.4261178 0.5331072
#> 2 2 2.098665 1.550435 362.1234 -0.03115274 -0.10753442   0.4191588 0.5268017
#> 3 3 2.108495 1.579356 356.3630 -0.01607828 -0.13331809   0.4096309 0.5437988
#> 4 4 2.139602 1.612496 327.6082 -0.05374925 -0.22234913   0.3911879 0.5151870
#> 5 5 2.138439 1.606254 299.8583 -0.04344924 -0.26083450   0.3971983 0.5317053
#>      MAE_SD  MAPE_SD     R2_SD Adjusted_R2_SD Correlation_SD
#> 1 0.2536350 304.2057 0.3950910      0.4092014      0.1699296
#> 2 0.2516049 302.7517 0.3901099      0.4190070      0.1680101
#> 3 0.2326813 287.3636 0.3037666      0.3388166      0.1175357
#> 4 0.2265528 266.0102 0.3207313      0.3720483      0.1339375
#> 5 0.2479694 215.8790 0.2949635      0.3564142      0.1153398
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
#> 1 1  2.095089 1.552059 -0.02819197      -0.06491311        0.4261178 508.5422
#> 2 2  2.098665 1.550435 -0.03115274      -0.10753442        0.4191588 510.2400
#> 3 3  2.108495 1.579356 -0.01607828      -0.13331809        0.4096309 510.1828
#> 4 4  2.139602 1.612496 -0.05374925      -0.22234913        0.3911879 507.9913
#> 5 5  2.138439 1.606254 -0.04344924      -0.26083450        0.3971983 509.4803
#>   mean_BIC mean_CAIC mean_ICOMP mean_CICOMP   sd_RMSE RMSE_scaled BIC_scaled
#> 1 516.9047  519.9047   502.5425    519.9050 0.5331072  0.00000000  0.0000000
#> 2 521.3900  525.3900   502.2442    525.3942 0.5268017  0.08033452  0.3710539
#> 3 524.1202  529.1202   500.1893    529.1268 0.5437988  0.30117707  0.5969167
#> 4 524.7163  530.7163   496.0073    530.7322 0.5151870  1.00000000  0.6462252
#> 5 528.9927  535.9927   495.5109    536.0234 0.5317053  0.97387131  1.0000000
#>   CAIC_scaled CICOMP_scaled     CVBIC    CVCAIC  CVCICOMP
#> 1   0.0000000     0.0000000 0.0000000 0.0000000 0.0000000
#> 2   0.3409561     0.3405560 0.4513884 0.4212906 0.4208905
#> 3   0.5728202     0.5721290 0.8980938 0.8739973 0.8733060
#> 4   0.6720268     0.6717304 1.6462252 1.6720268 1.6717304
#> 5   1.0000000     1.0000000 1.9738713 1.9738713 1.9738713
cv_icomp[c(
  "selected_d_rmse",
  "selected_d_cvbic",
  "selected_d_cvcaic",
  "selected_d_cvcicomp"
)]
#> $selected_d_rmse
#> [1] 1
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
#> d1 1 0.07915268      0.1794692 0.2586219
#> d2 2 0.07247804      0.6667209 0.7391990
#> d3 3 0.06566875      0.7876633 0.8533320
#> d4 4 0.06425206      0.8755804 0.9398325
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
