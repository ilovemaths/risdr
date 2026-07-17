# Package index

## Package overview

- [`risdr`](https://ilovemaths.github.io/risdr/dev/reference/risdr-package.md)
  [`risdr-package`](https://ilovemaths.github.io/risdr/dev/reference/risdr-package.md)
  : risdr: Regularised and Information-Theoretic Sufficient Dimension
  Reduction

## Model fitting and methods

- [`fit_risdr()`](https://ilovemaths.github.io/risdr/dev/reference/fit_risdr.md)
  : Fit regularised and information-theoretic SDR model
- [`compute_dr()`](https://ilovemaths.github.io/risdr/dev/reference/compute_dr.md)
  : Compute Directional Regression
- [`compute_information_criteria()`](https://ilovemaths.github.io/risdr/dev/reference/compute_information_criteria.md)
  : Compute model selection criteria
- [`compute_phd()`](https://ilovemaths.github.io/risdr/dev/reference/compute_phd.md)
  : Compute Principal Hessian Directions
- [`compute_save()`](https://ilovemaths.github.io/risdr/dev/reference/compute_save.md)
  : Compute Sliced Average Variance Estimation
- [`compute_scores()`](https://ilovemaths.github.io/risdr/dev/reference/compute_scores.md)
  : Compute SDR scores for new data
- [`compute_sdr()`](https://ilovemaths.github.io/risdr/dev/reference/compute_sdr.md)
  : General SDR kernel dispatcher
- [`compute_sir()`](https://ilovemaths.github.io/risdr/dev/reference/compute_sir.md)
  : Compute Sliced Inverse Regression
- [`extract_loadings()`](https://ilovemaths.github.io/risdr/dev/reference/extract_loadings.md)
  : Extract SDR loadings
- [`predict(`*`<risdr>`*`)`](https://ilovemaths.github.io/risdr/dev/reference/predict.risdr.md)
  : Predict method for risdr objects
- [`predict_downstream_lm()`](https://ilovemaths.github.io/risdr/dev/reference/predict_downstream_lm.md)
  : Predict from downstream SDR regression model
- [`prediction_correlation()`](https://ilovemaths.github.io/risdr/dev/reference/prediction_correlation.md)
  : Prediction correlation
- [`summary(`*`<risdr>`*`)`](https://ilovemaths.github.io/risdr/dev/reference/summary.risdr.md)
  : Summarise risdr object
- [`print(`*`<risdr>`*`)`](https://ilovemaths.github.io/risdr/dev/reference/print.risdr.md)
  : Print risdr object
- [`print(`*`<risdr_realdata>`*`)`](https://ilovemaths.github.io/risdr/dev/reference/print.risdr_realdata.md)
  : Print real-data RISDR workflow
- [`print(`*`<summary.risdr>`*`)`](https://ilovemaths.github.io/risdr/dev/reference/print.summary.risdr.md)
  : Print summary of risdr object

## Covariance estimation and stabilisation

- [`cov_complexity_C1()`](https://ilovemaths.github.io/risdr/dev/reference/cov_complexity_C1.md)
  : Covariance complexity C1
- [`cov_complexity_C1F()`](https://ilovemaths.github.io/risdr/dev/reference/cov_complexity_C1F.md)
  : Scale-invariant covariance complexity C1F
- [`cov_condition_number()`](https://ilovemaths.github.io/risdr/dev/reference/cov_condition_number.md)
  : Covariance condition number
- [`cov_diagnostics()`](https://ilovemaths.github.io/risdr/dev/reference/cov_diagnostics.md)
  : Covariance eigenvalue summary
- [`cov_effective_rank()`](https://ilovemaths.github.io/risdr/dev/reference/cov_effective_rank.md)
  : Effective covariance rank
- [`cov_lw()`](https://ilovemaths.github.io/risdr/dev/reference/cov_lw.md)
  : Ledoit-Wolf type covariance estimator
- [`cov_mec()`](https://ilovemaths.github.io/risdr/dev/reference/cov_mec.md)
  : Maximum Entropy Covariance estimator
- [`cov_oas()`](https://ilovemaths.github.io/risdr/dev/reference/cov_oas.md)
  : Oracle Approximating Shrinkage covariance estimator
- [`cov_ridge()`](https://ilovemaths.github.io/risdr/dev/reference/cov_ridge.md)
  : Ridge-type covariance estimator
- [`cov_sample()`](https://ilovemaths.github.io/risdr/dev/reference/cov_sample.md)
  : Sample covariance matrix
- [`estimate_cov()`](https://ilovemaths.github.io/risdr/dev/reference/estimate_cov.md)
  : General covariance estimator dispatcher
- [`stabilize_cov()`](https://ilovemaths.github.io/risdr/dev/reference/stabilize_cov.md)
  : General covariance stabilisation dispatcher
- [`stabilize_eigenfloor()`](https://ilovemaths.github.io/risdr/dev/reference/stabilize_eigenfloor.md)
  : Eigenvalue floor stabilisation
- [`stabilize_nearest_pd()`](https://ilovemaths.github.io/risdr/dev/reference/stabilize_nearest_pd.md)
  : Nearest positive definite stabilisation
- [`stabilize_ridge()`](https://ilovemaths.github.io/risdr/dev/reference/stabilize_ridge.md)
  : Ridge stabilisation of covariance matrix

## Structural dimension selection

- [`select_dimension()`](https://ilovemaths.github.io/risdr/dev/reference/select_dimension.md)
  : Select structural dimension
- [`choose_dimension()`](https://ilovemaths.github.io/risdr/dev/reference/choose_dimension.md)
  : Choose dimension from criteria table
- [`criterion_weights()`](https://ilovemaths.github.io/risdr/dev/reference/criterion_weights.md)
  : Information criterion weights
- [`select_dimension_cv()`](https://ilovemaths.github.io/risdr/dev/reference/select_dimension_cv.md)
  : Cross-validation dimension selection for SDR
- [`select_dimension_cv_icomp()`](https://ilovemaths.github.io/risdr/dev/reference/select_dimension_cv_icomp.md)
  : Complexity-aware cross-validation for structural dimension selection
- [`select_dimension_ladle()`](https://ilovemaths.github.io/risdr/dev/reference/select_dimension_ladle.md)
  : Ladle-type structural dimension diagnostic
- [`make_cv_folds()`](https://ilovemaths.github.io/risdr/dev/reference/make_cv_folds.md)
  : Create cross-validation folds
- [`plot_cv_dimension()`](https://ilovemaths.github.io/risdr/dev/reference/plot_cv_dimension.md)
  : Plot cross-validation dimension selection result
- [`plot_dimension_selection()`](https://ilovemaths.github.io/risdr/dev/reference/plot_dimension_selection.md)
  : Plot dimension selection criteria
- [`plot_ladle()`](https://ilovemaths.github.io/risdr/dev/reference/plot_ladle.md)
  : Plot ladle dimension diagnostic
- [`plot_loadings()`](https://ilovemaths.github.io/risdr/dev/reference/plot_loadings.md)
  : Plot SDR loadings
- [`plot_prediction()`](https://ilovemaths.github.io/risdr/dev/reference/plot_prediction.md)
  : Prediction plot
- [`plot_residuals()`](https://ilovemaths.github.io/risdr/dev/reference/plot_residuals.md)
  : Residual plot
- [`plot_scree()`](https://ilovemaths.github.io/risdr/dev/reference/plot_scree.md)
  : Scree plot of SDR eigenvalues
- [`plot_sufficient()`](https://ilovemaths.github.io/risdr/dev/reference/plot_sufficient.md)
  : Sufficient summary plot
- [`plot_sufficient2d()`](https://ilovemaths.github.io/risdr/dev/reference/plot_sufficient2d.md)
  : Two-direction sufficient summary plot

## Prediction and assessment

- [`fit_downstream_lm()`](https://ilovemaths.github.io/risdr/dev/reference/fit_downstream_lm.md)
  : Fit downstream regression model on SDR scores
- [`predict_downstream_lm()`](https://ilovemaths.github.io/risdr/dev/reference/predict_downstream_lm.md)
  : Predict from downstream SDR regression model
- [`evaluate_prediction()`](https://ilovemaths.github.io/risdr/dev/reference/evaluate_prediction.md)
  : Evaluate predictions
- [`evaluate_prediction_cv()`](https://ilovemaths.github.io/risdr/dev/reference/evaluate_prediction_cv.md)
  : Repeated cross-validation for predictive assessment
- [`rmse()`](https://ilovemaths.github.io/risdr/dev/reference/rmse.md) :
  Root mean squared error
- [`mae()`](https://ilovemaths.github.io/risdr/dev/reference/mae.md) :
  Mean absolute error
- [`mape()`](https://ilovemaths.github.io/risdr/dev/reference/mape.md) :
  Mean absolute percentage error
- [`r_squared()`](https://ilovemaths.github.io/risdr/dev/reference/r_squared.md)
  : Coefficient of determination
- [`adjusted_r_squared()`](https://ilovemaths.github.io/risdr/dev/reference/adjusted_r_squared.md)
  : Adjusted coefficient of determination
- [`prediction_correlation()`](https://ilovemaths.github.io/risdr/dev/reference/prediction_correlation.md)
  : Prediction correlation

## Slicing and simulation

- [`make_slices()`](https://ilovemaths.github.io/risdr/dev/reference/make_slices.md)
  : Create response slices
- [`slice_covariances()`](https://ilovemaths.github.io/risdr/dev/reference/slice_covariances.md)
  : Compute slice covariance matrices
- [`slice_means()`](https://ilovemaths.github.io/risdr/dev/reference/slice_means.md)
  : Compute slice means
- [`slice_proportions()`](https://ilovemaths.github.io/risdr/dev/reference/slice_proportions.md)
  : Compute slice proportions
- [`slice_summary()`](https://ilovemaths.github.io/risdr/dev/reference/slice_summary.md)
  : Summarise response slices
- [`simulate_risdr_data()`](https://ilovemaths.github.io/risdr/dev/reference/simulate_risdr_data.md)
  : Simulate SDR data
- [`run_one_simulation()`](https://ilovemaths.github.io/risdr/dev/reference/run_one_simulation.md)
  : Run one SDR simulation replication
- [`run_risdr_simulation()`](https://ilovemaths.github.io/risdr/dev/reference/run_risdr_simulation.md)
  : Run SDR simulation study
- [`summarise_simulation()`](https://ilovemaths.github.io/risdr/dev/reference/summarise_simulation.md)
  : Summarise simulation results
- [`ar1_covariance()`](https://ilovemaths.github.io/risdr/dev/reference/ar1_covariance.md)
  : AR(1) covariance matrix
- [`projection_matrix()`](https://ilovemaths.github.io/risdr/dev/reference/projection_matrix.md)
  : Projection matrix
- [`subspace_distance()`](https://ilovemaths.github.io/risdr/dev/reference/subspace_distance.md)
  : Subspace distance

## Real-data helpers

- [`filter_low_variance()`](https://ilovemaths.github.io/risdr/dev/reference/filter_low_variance.md)
  : Filter low-variance predictors
- [`prepare_survival_response()`](https://ilovemaths.github.io/risdr/dev/reference/prepare_survival_response.md)
  : Prepare survival response
- [`fit_risdr_realdata()`](https://ilovemaths.github.io/risdr/dev/reference/fit_risdr_realdata.md)
  : Fit RISDR to real high-dimensional data
