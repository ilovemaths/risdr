# Environmental Performance Index Case Study

## Role of the case study

The completed thesis analysed the 2024 Environmental Performance Index
corpus for 180 countries. After missingness screening, low-variance
filtering, and imputation, 70 predictor indicators were retained
alongside the EPI response. The `.old` columns formed the training data
and the aligned `.new` columns formed the test data.

The package includes the supplied processed predictor and response
matrices. The paired predictor matrices contain the same 70 named
indicators and no missing values. Selected supplied output tables are
retained separately as provenance fixtures.

## Bundled processed inputs

``` r

read_epi_file <- function(name) {
  utils::read.csv(
    system.file("extdata", "epi", name, package = "risdr"),
    check.names = FALSE
  )
}

X_train <- read_epi_file("X_old.csv")
X_test <- read_epi_file("X_new.csv")
y_train <- read_epi_file("y_old.csv")[[1L]]
y_test <- read_epi_file("y_new.csv")[[1L]]

stopifnot(
  nrow(X_train) == 180L,
  nrow(X_test) == 180L,
  ncol(X_train) == 70L,
  identical(names(X_train), names(X_test)),
  length(y_train) == nrow(X_train),
  length(y_test) == nrow(X_test)
)
```

## Original import and alignment protocol

The transformation from the original EPI corpus should follow the
structure below. It is not evaluated because the single source corpus is
separate from the processed analysis matrices.

``` r

library(dplyr)
library(readr)

epi_data <- read_csv("data-raw/epi2024results.csv", show_col_types = FALSE)

epi_old <- epi_data |>
  select(iso, country, ends_with(".old")) |>
  rename_with(\(x) sub("[.]old$", "", x))

epi_new <- epi_data |>
  select(iso, country, ends_with(".new")) |>
  rename_with(\(x) sub("[.]new$", "", x))

X_old_full <- epi_old |> select(-iso, -country)
X_new_full <- epi_new |> select(-iso, -country)

stopifnot(identical(names(X_old_full), names(X_new_full)))

missing_prop_old <- colMeans(is.na(X_old_full))
keep_names <- names(missing_prop_old[missing_prop_old < 0.40])

X_old_reduced <- X_old_full[, keep_names, drop = FALSE]
X_new_reduced <- X_new_full[, keep_names, drop = FALSE]

training_variance <- vapply(X_old_reduced, var, numeric(1), na.rm = TRUE)
keep_names <- names(training_variance[training_variance > 1e-6])

X_old_reduced <- X_old_reduced[, keep_names, drop = FALSE]
X_new_reduced <- X_new_reduced[, keep_names, drop = FALSE]

X_old_imputed <- VIM::kNN(X_old_reduced, k = 5, imp_var = FALSE)
X_new_imputed <- VIM::kNN(X_new_reduced, k = 5, imp_var = FALSE)

y_train <- X_old_imputed$EPI
X_train <- X_old_imputed |> select(-EPI)
y_test <- X_new_imputed$EPI
X_test <- X_new_imputed |> select(-EPI)
```

Filtering and imputation choices must be estimated from the training
data and then applied to the test data. Re-estimating preprocessing
independently on the test data would weaken the interpretation of
external prediction.

## Fitting template

``` r

fit_epi <- fit_risdr(
  X = X_train,
  y = y_train,
  sdr_method = "phd",
  cov_method = "oas",
  nslices = 6,
  d_max = 10,
  selector = "cicomp",
  standardize = TRUE,
  stabilize = TRUE
)

epi_prediction <- predict(fit_epi, X_test)
evaluate_prediction(y_test, epi_prediction, d = fit_epi$d)
```

The thesis primary predictive comparison reports pHd as its best method,
with approximately RMSE 2.905, MAE 2.321, `R^2` 0.935, adjusted `R^2`
0.933, and correlation 0.967. These values belong to that designated
primary comparison.

## Broader method-covariance audit

The package fixture below records a separate comparison across four SDR
methods and five covariance estimators. It should not be conflated with
the primary thesis comparison because the model grid and selected
dimensions differ.

``` r

comparison_path <- system.file(
  "extdata",
  "epi",
  "epi_sdr_covariance_comparison_tidy.csv",
  package = "risdr"
)
comparison <- utils::read.csv(comparison_path)

comparison[
  order(comparison$RMSE),
  c(
    "sdr_method", "cov_method", "selected_d", "condition_number",
    "RMSE", "MAE", "R2", "Adjusted_R2", "Correlation"
  )
]
#>    sdr_method cov_method selected_d condition_number    RMSE    MAE      R2
#> 3         SIR        OAS          9        3.216e+02  1.2550 1.0210  0.9879
#> 2         SIR      RIDGE          6        1.856e+02  1.2978 1.0687  0.9871
#> 4         SIR         LW          2        3.610e+02  1.4076 1.1317  0.9848
#> 12         DR      RIDGE          7        1.856e+02  1.5611 1.2398  0.9813
#> 13         DR        OAS          7        3.216e+02  1.5910 1.2453  0.9806
#> 14         DR         LW          7        3.610e+02  1.6039 1.2549  0.9803
#> 1         SIR     SAMPLE          2        2.051e+07  2.2786 1.8097  0.9602
#> 11         DR     SAMPLE          4        2.051e+07  2.8422 2.2534  0.9381
#> 5         SIR        MEC          2        1.088e+07  3.4344 2.7424  0.9096
#> 15         DR        MEC          6        1.088e+07  3.8484 3.0175  0.8865
#> 17        PHD      RIDGE          5        1.856e+02  7.0507 5.6800  0.6189
#> 18        PHD        OAS          5        3.216e+02  7.2993 5.8649  0.5915
#> 19        PHD         LW          5        3.610e+02  7.3510 5.9025  0.5857
#> 16        PHD     SAMPLE          7        2.051e+07  7.6230 6.0538  0.5545
#> 20        PHD        MEC          7        1.088e+07  8.7952 7.4023  0.4069
#> 6        SAVE     SAMPLE          1        2.051e+07 11.6029 9.0719 -0.0322
#> 7        SAVE      RIDGE          1        1.856e+02 11.6178 9.0767 -0.0348
#> 8        SAVE        OAS          1        3.216e+02 11.6226 9.0816 -0.0357
#> 9        SAVE         LW          1        3.610e+02 11.6234 9.0824 -0.0358
#> 10       SAVE        MEC          1        1.088e+07 11.6272 9.0873 -0.0365
#>    Adjusted_R2 Correlation
#> 3       0.9873      0.9942
#> 2       0.9866      0.9940
#> 4       0.9846      0.9925
#> 12      0.9806      0.9916
#> 13      0.9798      0.9910
#> 14      0.9795      0.9908
#> 1       0.9597      0.9831
#> 11      0.9367      0.9757
#> 5       0.9085      0.9562
#> 15      0.8825      0.9503
#> 17      0.6079      0.7958
#> 18      0.5798      0.7786
#> 19      0.5738      0.7749
#> 16      0.5363      0.7717
#> 20      0.3828      0.6526
#> 6      -0.0380      0.2908
#> 7      -0.0406      0.1325
#> 8      -0.0415      0.1237
#> 9      -0.0416      0.1229
#> 10     -0.0423      0.2291
```

This audit demonstrates why predictive performance, structural
dimension, and covariance conditioning must be reported together. A
method may predict well under one estimator while retaining a different
number of directions under another.

## Repeated cross-validation

``` r

cv_path <- system.file(
  "extdata",
  "epi",
  "epi_repeated_cv_summary_tidy.csv",
  package = "risdr"
)
cv_summary <- utils::read.csv(cv_path)

cv_summary[
  order(cv_summary$mean_RMSE),
  c(
    "sdr_method", "cov_method", "n_success", "mean_selected_d",
    "mean_RMSE", "sd_RMSE", "mean_Adjusted_R2", "mean_Correlation"
  )
]
#>    sdr_method cov_method n_success mean_selected_d mean_RMSE sd_RMSE
#> 1         SIR      RIDGE        10            19.2    1.5735  0.0727
#> 2         SIR        OAS        10            19.1    1.6142  0.1025
#> 3         SIR         LW        10            18.6    1.6524  0.0961
#> 4          DR      RIDGE        10            19.0    1.6869  0.1154
#> 5          DR        OAS        10            19.4    1.7744  0.1304
#> 6          DR         LW        10            19.5    1.8044  0.1361
#> 7         SIR     SAMPLE        10            18.0    2.4455  0.2316
#> 8         SIR        MEC        10            19.3    2.7551  0.3328
#> 9          DR     SAMPLE        10            19.8    2.7941  0.2798
#> 10         DR        MEC        10            19.5    3.0866  0.4362
#> 11        PHD      RIDGE        10            19.6    5.6242  0.4082
#> 12        PHD        OAS        10            19.7    5.9625  0.4088
#> 13        PHD         LW        10            19.8    6.0872  0.4219
#> 14        PHD        MEC        10            18.6    8.2690  0.4388
#> 15        PHD     SAMPLE        10            19.1    8.4594  0.3962
#> 16       SAVE      RIDGE        10            15.3   11.0859  0.0995
#> 17       SAVE        OAS        10            13.8   11.1091  0.1016
#> 18       SAVE         LW        10            15.2   11.1178  0.1005
#> 19       SAVE        MEC        10             9.8   11.1584  0.1361
#> 20       SAVE     SAMPLE        10             9.4   11.1609  0.1112
#>    mean_Adjusted_R2 mean_Correlation
#> 1            0.9504           0.9895
#> 2            0.9491           0.9892
#> 3            0.9466           0.9884
#> 4            0.9429           0.9876
#> 5            0.9350           0.9863
#> 6            0.9321           0.9858
#> 7            0.8842           0.9752
#> 8            0.8416           0.9669
#> 9            0.8313           0.9655
#> 10           0.8031           0.9589
#> 11           0.3679           0.8607
#> 12           0.2837           0.8417
#> 13           0.2510           0.8350
#> 14          -0.2878           0.6920
#> 15          -0.3801           0.6660
#> 16          -0.9208           0.1680
#> 17          -0.8044           0.1566
#> 18          -0.9206           0.1490
#> 19          -0.5258           0.1417
#> 20          -0.5177           0.1355
```

The repeated assessment identifies SIR with ridge and SIR with OAS as
highly competitive combinations. This complements, rather than replaces,
the fixed old-to-new comparison.

## Interpretation discipline

The EPI case study supports three distinct conclusions:

1.  Prediction, subspace recovery, and structural dimension recovery are
    different objectives.
2.  Covariance regularisation can materially improve numerical
    conditioning.
3.  A single overall winner should not be declared without naming the
    objective, validation design, and covariance estimator.

## References
