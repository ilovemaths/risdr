test_that("prediction supports single rows and reordered named columns", {
  dat <- make_test_data()
  fit <- fit_risdr(dat$X, dat$y, d = 1, d_max = 3, nslices = 5)

  one <- predict(fit, dat$X[1L, , drop = FALSE])
  reordered <- predict(
    fit,
    dat$X[1:6, rev(colnames(dat$X)), drop = FALSE]
  )
  alternative_d <- predict(fit, dat$X[1:6, , drop = FALSE], d = 2)

  expect_length(one, 1L)
  expect_length(reordered, 6L)
  expect_length(alternative_d, 6L)

  incorrectly_named <- dat$X[1:6, , drop = FALSE]
  colnames(incorrectly_named)[1L] <- "wrong"
  expect_error(predict(fit, incorrectly_named), "must match")
})

test_that("downstream fitting and projection are internally consistent", {
  dat <- make_test_data()
  directions <- qr.Q(qr(matrix(rnorm(8 * 3), 8, 3)))
  scores <- compute_scores(dat$X, directions)
  fit <- fit_downstream_lm(scores, dat$y, d = 2)
  predicted <- predict_downstream_lm(fit, scores[1:5, , drop = FALSE], d = 2)

  expect_s3_class(fit, "lm")
  expect_length(predicted, 5L)
})

test_that("prediction metrics reproduce their definitions", {
  observed <- c(1, 2, 3, 4, 5)
  predicted <- c(1.2, 1.8, 3.1, 3.7, 5.2)

  expect_equal(rmse(observed, predicted), sqrt(mean((observed - predicted)^2)))
  expect_equal(mae(observed, predicted), mean(abs(observed - predicted)))
  expect_equal(
    mape(observed, predicted),
    mean(abs((observed - predicted) / observed)) * 100
  )
  expect_equal(prediction_correlation(observed, predicted), cor(observed, predicted))

  metrics <- evaluate_prediction(observed, predicted, d = 1)
  expect_equal(nrow(metrics), 1L)
  expect_true(is.finite(metrics$Adjusted_R2))

  expect_warning(mape(c(0, 1), c(0.1, 0.9)), "undefined")
  expect_true(is.na(suppressWarnings(mape(c(0, 1), c(0.1, 0.9)))))
})
