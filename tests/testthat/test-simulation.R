test_that("simulation is reproducible and dimensionally correct", {
  sim_1 <- simulate_risdr_data(n = 60, p = 10, d = 2, rho = 0.5, seed = 31)
  sim_2 <- simulate_risdr_data(n = 60, p = 10, d = 2, rho = 0.5, seed = 31)

  expect_equal(sim_1$X, sim_2$X)
  expect_equal(sim_1$y, sim_2$y)
  expect_equal(dim(sim_1$beta), c(10L, 2L))
  expect_equal(unname(crossprod(sim_1$beta)), diag(2), tolerance = 1e-8)

  expect_equal(ar1_covariance(4, 0), diag(4))

  random_train <- simulate_risdr_data(
    n = 60,
    p = 10,
    d = 2,
    beta_type = "random_sparse",
    seed = 32
  )
  random_test <- simulate_risdr_data(
    n = 60,
    p = 10,
    d = 2,
    beta = random_train$beta,
    seed = 33
  )
  expect_equal(random_test$beta, random_train$beta, tolerance = 1e-10)
})

test_that("projection and subspace distance are basis invariant", {
  B <- rbind(c(1, 0), c(0, 1), c(0, 0))
  transformed <- B %*% matrix(c(2, 1, 0, 1), nrow = 2)

  expect_equal(projection_matrix(B), projection_matrix(transformed), tolerance = 1e-8)
  expect_equal(subspace_distance(B, transformed), 0, tolerance = 1e-8)
  expect_error(projection_matrix(cbind(B[, 1], B[, 1])), "full column rank")
})

test_that("single and small simulation studies return expected columns", {
  one <- run_one_simulation(
    n = 60,
    p = 8,
    d = 2,
    rho = 0.4,
    beta_type = "random_sparse",
    sdr_method = "sir",
    cov_method = "oas",
    nslices = 4,
    d_max = 3,
    seed = 37
  )

  study <- run_risdr_simulation(
    R = 1,
    rho_values = 0.4,
    methods = c("sir", "dr"),
    cov_methods = "oas",
    n = 60,
    p = 8,
    d = 2,
    nslices = 4,
    d_max = 3,
    seed = 41
  )

  expect_equal(nrow(one), 1L)
  expect_equal(nrow(study), 2L)

  summary_table <- summarise_simulation(study)
  expect_equal(nrow(summary_table), 2L)
})
