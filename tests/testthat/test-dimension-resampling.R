test_that("information criteria and weights select valid dimensions", {
  dat <- make_test_data()
  sdr <- compute_sir(dat$X, dat$y, Sigma = cov_oas(dat$X), nslices = 5)
  table <- select_dimension(sdr$scores, dat$y, d_max = 4)

  expect_named(table, c("d", "AIC", "BIC", "CAIC", "ICOMP", "CICOMP"))
  expect_true(choose_dimension(table, "bic") %in% table$d)

  weights <- criterion_weights(table, "BIC")
  expect_equal(sum(weights$weight), 1)
  expect_equal(min(weights$delta), 0)

  downstream <- fit_downstream_lm(sdr$scores, dat$y, d = 2)
  criteria <- compute_information_criteria(downstream, complexity = "C1")
  expect_named(criteria, c("AIC", "BIC", "CAIC", "ICOMP", "CICOMP"))
})

test_that("ordinary and complexity-aware cross-validation complete", {
  dat <- make_test_data(n = 75)

  cv <- select_dimension_cv(
    dat$X,
    dat$y,
    sdr_method = "sir",
    cov_method = "oas",
    d_max = 3,
    v = 3,
    nslices = 5,
    seed = 17
  )

  cv_icomp <- select_dimension_cv_icomp(
    dat$X,
    dat$y,
    sdr_method = "sir",
    cov_method = "oas",
    d_max = 3,
    v = 3,
    nslices = 5,
    lambda = 1,
    seed = 17
  )

  expect_true(cv$selected_d %in% 1:3)
  expect_equal(nrow(cv$cv_table), 3L)
  expect_equal(nrow(cv_icomp$cv_table), 3L)
  expect_true(cv_icomp$selected_d_cvcicomp %in% 1:3)
})

test_that("repeated predictive cross-validation records all folds", {
  dat <- make_test_data(n = 75)
  result <- evaluate_prediction_cv(
    dat$X,
    dat$y,
    sdr_method = "sir",
    cov_method = "oas",
    d = 2,
    v = 3,
    repeats = 2,
    nslices = 5,
    seed = 19
  )

  expect_equal(nrow(result$fold_results), 6L)
  expect_equal(result$summary$n_success, 6L)
  expect_true(is.finite(result$summary$mean_RMSE))
})

test_that("ladle diagnostic returns a candidate dimension", {
  dat <- make_test_data(n = 70)
  result <- select_dimension_ladle(
    dat$X,
    dat$y,
    sdr_method = "sir",
    cov_method = "oas",
    d_max = 2,
    B = 4,
    nslices = 5,
    seed = 23
  )

  expect_true(result$selected_d %in% 1:2)
  expect_equal(nrow(result$ladle_table), 2L)
  expect_equal(dim(result$boot_instability), c(4L, 2L))
})
