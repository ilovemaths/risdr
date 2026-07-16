test_that("all SDR kernels return conformable components", {
  dat <- make_test_data()
  Sigma <- cov_oas(dat$X)

  for (method in c("sir", "save", "dr", "phd")) {
    fit <- compute_sdr(
      dat$X,
      dat$y,
      method = method,
      Sigma = Sigma,
      nslices = 5
    )

    expect_identical(fit$method, method)
    expect_equal(dim(fit$directions), c(ncol(dat$X), ncol(dat$X)))
    expect_equal(dim(fit$scores), dim(dat$X))
    expect_length(fit$eigenvalues, ncol(dat$X))
  }
})

test_that("model fitting works across SDR and covariance choices", {
  dat <- make_test_data()

  for (method in c("sir", "save", "dr", "phd")) {
    fit <- fit_risdr(
      dat$X,
      dat$y,
      sdr_method = method,
      cov_method = "oas",
      d = 2,
      d_max = 3,
      nslices = 5
    )
    expect_s3_class(fit, "risdr")
    expect_equal(fit$d, 2L)
  }

  for (method in c("sample", "ridge", "oas", "lw", "mec")) {
    fit <- fit_risdr(
      dat$X,
      dat$y,
      sdr_method = "sir",
      cov_method = method,
      d = 1,
      d_max = 3,
      nslices = 5,
      cov_args = if (method == "ridge") list(lambda = 0.2) else list()
    )
    expect_s3_class(fit, "risdr")
  }
})

test_that("component arguments are routed without leakage", {
  dat <- make_test_data()

  fit <- fit_risdr(
    dat$X,
    dat$y,
    sdr_method = "sir",
    cov_method = "ridge",
    stabilization = "eigenfloor",
    d = 1,
    d_max = 3,
    cov_args = list(lambda = 0.2),
    stabilization_args = list(eps = 1e-7),
    sdr_args = list(slice_type = "equal_width")
  )

  expect_equal(fit$cov_args$lambda, 0.2)
  expect_equal(fit$stabilization_args$eps, 1e-7)
  expect_identical(fit$sdr_args$slice_type, "equal_width")

  expect_error(
    fit_risdr(
      dat$X,
      dat$y,
      cov_method = "oas",
      cov_args = list(lambda = 0.2),
      d_max = 3
    ),
    "Unsupported"
  )
})

test_that("print and summary methods return their objects invisibly", {
  dat <- make_test_data()
  fit <- fit_risdr(dat$X, dat$y, d = 1, d_max = 3, nslices = 5)
  summary_fit <- summary(fit)

  expect_s3_class(summary_fit, "summary.risdr")
  expect_output(returned_fit <- print(fit), "Selected d")
  expect_identical(returned_fit, fit)
  expect_output(returned_summary <- print(summary_fit), "Dimension selection")
  expect_identical(returned_summary, summary_fit)
})

test_that("loading extraction validates variable names", {
  directions <- diag(4)
  loadings <- extract_loadings(directions, paste0("v", 1:4))

  expect_equal(nrow(loadings), 4L)
  expect_named(loadings, c("Variable", paste0("Direction_", 1:4)))
  expect_error(extract_loadings(directions, c("a", "b")), "Length")
})
