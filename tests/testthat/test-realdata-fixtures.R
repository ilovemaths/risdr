test_that("variance filtering and survival preparation validate inputs", {
  dat <- make_test_data()
  X <- cbind(dat$X, constant = 1)
  filtered <- filter_low_variance(X, variance_quantile = 0.1)

  expect_false("constant" %in% colnames(filtered))

  survival <- prepare_survival_response(
    time = c(1, 2, NA, 4),
    delta = c(1, 0, 1, 1)
  )
  expect_equal(survival$time, c(1, 2, 4))
  expect_equal(survival$delta, c(1, 0, 1))

  expect_error(
    prepare_survival_response(1:3, c(1, 2, 0)),
    "only 0 and 1"
  )
})

test_that("real-data workflow returns selected scores for continuous y", {
  dat <- make_test_data()
  workflow <- fit_risdr_realdata(
    dat$X,
    dat$y,
    response_type = "continuous",
    variance_quantile = 0.1,
    sdr_method = "sir",
    cov_method = "oas",
    d = 1,
    d_max = 2,
    nslices = 5
  )

  expect_s3_class(workflow, "risdr_realdata")
  expect_equal(ncol(workflow$reduced_predictors), 1L)
  expect_output(returned <- print(workflow), "Reduced dimension")
  expect_identical(returned, workflow)

  expect_error(
    fit_risdr_realdata(dat$X, dat$y > median(dat$y), response_type = "binary"),
    "under development"
  )
})

test_that("supplied thesis fixtures are installed and readable", {
  epi_file <- system.file(
    "extdata",
    "epi",
    "epi_sdr_covariance_comparison_tidy.csv",
    package = "risdr"
  )
  simulation_file <- system.file(
    "extdata",
    "simulation",
    "simulation_B1_overall_ranking.csv",
    package = "risdr"
  )

  expect_true(nzchar(epi_file))
  expect_true(nzchar(simulation_file))

  epi <- utils::read.csv(epi_file)
  ranking <- utils::read.csv(simulation_file)

  expect_true(all(c("sdr_method", "cov_method", "RMSE", "R2") %in% names(epi)))
  expect_true(any(toupper(epi$sdr_method) == "PHD"))
  expect_true(nrow(ranking) >= 1L)
})

test_that("bundled EPI inputs are aligned and complete", {
  epi_path <- function(name) {
    system.file("extdata", "epi", name, package = "risdr")
  }

  X_old <- utils::read.csv(epi_path("X_old.csv"), check.names = FALSE)
  X_new <- utils::read.csv(epi_path("X_new.csv"), check.names = FALSE)
  y_old <- utils::read.csv(epi_path("y_old.csv"))[[1L]]
  y_new <- utils::read.csv(epi_path("y_new.csv"))[[1L]]

  expect_equal(dim(X_old), c(180L, 70L))
  expect_equal(dim(X_new), c(180L, 70L))
  expect_identical(names(X_old), names(X_new))
  expect_length(y_old, nrow(X_old))
  expect_length(y_new, nrow(X_new))
  expect_false(anyNA(X_old))
  expect_false(anyNA(X_new))
  expect_false(anyNA(y_old))
  expect_false(anyNA(y_new))
})
