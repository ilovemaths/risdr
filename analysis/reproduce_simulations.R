# Corrected reproduction of thesis Simulations A, B1, and B2.
#
# The historical scripts generated random-sparse training and test bases
# independently in Simulations A and B1. This workflow reuses each training
# basis when generating its corresponding test sample.

required_packages <- c("risdr", "dplyr", "readr", "yaml")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0L) {
  stop(
    "Install the required packages before running the simulation workflow: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

scalar_integer <- function(x, name, minimum = 1L) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) ||
      x != as.integer(x) || x < minimum) {
    stop(
      sprintf("Configuration value `%s` must be an integer at least %d.", name, minimum),
      call. = FALSE
    )
  }

  as.integer(x)
}

scalar_numeric <- function(x, name, lower, upper = Inf, upper_open = FALSE) {
  valid_upper <- if (upper_open) x < upper else x <= upper

  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) ||
      x < lower || !valid_upper) {
    upper_symbol <- if (upper_open) ")" else "]"
    stop(
      sprintf(
        "Configuration value `%s` must be in [%s, %s%s.",
        name,
        format(lower),
        format(upper),
        upper_symbol
      ),
      call. = FALSE
    )
  }

  as.numeric(x)
}

read_simulation_config <- function(path) {
  if (!file.exists(path)) {
    stop("Configuration file not found: ", path, call. = FALSE)
  }

  config <- yaml::read_yaml(path)
  simulation <- config$simulation

  if (is.null(simulation)) {
    stop("The configuration must contain a `simulation` section.", call. = FALSE)
  }

  simulation$replications <- scalar_integer(
    simulation$replications,
    "simulation.replications"
  )
  simulation$true_dimension <- scalar_integer(
    simulation$true_dimension,
    "simulation.true_dimension"
  )
  simulation$slices <- scalar_integer(
    simulation$slices,
    "simulation.slices",
    minimum = 2L
  )
  simulation$maximum_dimension <- scalar_integer(
    simulation$maximum_dimension,
    "simulation.maximum_dimension"
  )
  simulation$error_sd <- scalar_numeric(
    simulation$error_sd,
    "simulation.error_sd",
    lower = .Machine$double.eps
  )
  simulation$signal_strength <- scalar_numeric(
    simulation$signal_strength,
    "simulation.signal_strength",
    lower = .Machine$double.eps
  )

  sample_sizes <- as.numeric(unlist(simulation$sample_sizes))
  predictor_counts <- as.numeric(unlist(simulation$predictor_counts))
  correlations <- as.numeric(unlist(simulation$correlations))

  if (length(sample_sizes) < 1L || any(!is.finite(sample_sizes)) ||
      any(sample_sizes != as.integer(sample_sizes)) || any(sample_sizes < 20L)) {
    stop("`simulation.sample_sizes` must contain integers at least 20.", call. = FALSE)
  }

  if (length(predictor_counts) < 1L || any(!is.finite(predictor_counts)) ||
      any(predictor_counts != as.integer(predictor_counts)) ||
      any(predictor_counts < simulation$true_dimension)) {
    stop(
      "`simulation.predictor_counts` must contain integers no smaller than the true dimension.",
      call. = FALSE
    )
  }

  if (length(correlations) < 1L || any(!is.finite(correlations)) ||
      any(correlations < 0) || any(correlations >= 1)) {
    stop("`simulation.correlations` must contain values in [0, 1).", call. = FALSE)
  }

  simulation$sample_sizes <- as.integer(sample_sizes)
  simulation$predictor_counts <- as.integer(predictor_counts)
  simulation$correlations <- correlations
  simulation$covariance_methods <- as.character(unlist(simulation$covariance_methods))
  simulation$sdr_methods <- as.character(unlist(simulation$sdr_methods))

  allowed_covariance <- c("sample", "ridge", "oas", "lw", "mec")
  allowed_sdr <- c("sir", "save", "dr", "phd")

  if (length(simulation$covariance_methods) < 1L ||
      any(!simulation$covariance_methods %in% allowed_covariance)) {
    stop(
      "`simulation.covariance_methods` contains an unsupported method.",
      call. = FALSE
    )
  }

  if (length(simulation$sdr_methods) < 1L ||
      any(!simulation$sdr_methods %in% allowed_sdr)) {
    stop("`simulation.sdr_methods` contains an unsupported method.", call. = FALSE)
  }

  studies <- toupper(as.character(unlist(config$execution$studies %||% c("A", "B1", "B2"))))

  if (length(studies) < 1L || any(!studies %in% c("A", "B1", "B2"))) {
    stop("`execution.studies` must contain one or more of A, B1, and B2.", call. = FALSE)
  }

  config$simulation <- simulation
  config$execution$studies <- unique(studies)
  config$execution$verbose <- isTRUE(config$execution$verbose %||% TRUE)
  config$execution$stop_on_failure <- isTRUE(config$execution$stop_on_failure %||% FALSE)
  config
}

simulation_seed <- function(base, scenario_id, replication) {
  scalar_integer(base, "simulation seed", minimum = 0L) +
    1000L * as.integer(scenario_id) + as.integer(replication)
}

report_progress <- function(verbose, study, scenario_id, scenario_total,
                            replication, scenario) {
  if (!verbose) {
    return(invisible(NULL))
  }

  method_label <- if ("cov_method" %in% names(scenario)) {
    paste("DR", toupper(scenario$cov_method), sep = " / ")
  } else {
    paste(toupper(scenario$sdr_method), "OAS", sep = " / ")
  }

  message(
    sprintf(
      "Simulation %s | scenario %d/%d | replication %d | n=%d, p=%d, rho=%.2f | %s",
      study,
      scenario_id,
      scenario_total,
      replication,
      scenario$n,
      scenario$p,
      scenario$rho,
      method_label
    )
  )

  invisible(NULL)
}

fit_elapsed <- function(expression) {
  start <- proc.time()[["elapsed"]]
  value <- tryCatch(expression, error = identity)
  elapsed <- proc.time()[["elapsed"]] - start
  list(value = value, elapsed = as.numeric(elapsed))
}

simulation_data <- function(simulation, scenario, seed, beta = NULL) {
  risdr::simulate_risdr_data(
    n = scenario$n,
    p = scenario$p,
    d = simulation$true_dimension,
    rho = scenario$rho,
    sigma = simulation$error_sd,
    signal_strength = simulation$signal_strength,
    model = simulation$signal_model,
    beta_type = simulation$basis_type,
    beta = beta,
    seed = seed
  )
}

replace_simulation_basis <- function(data, beta, model, signal_strength) {
  eta <- data$X %*% beta

  signal <- switch(
    model,
    linear = eta[, 1L],
    symmetric = eta[, 1L]^2,
    linear_quadratic = eta[, 1L] + eta[, 2L]^2,
    interaction = eta[, 1L] + eta[, 2L] + eta[, 1L] * eta[, 2L],
    stop("Unsupported signal model: ", model, call. = FALSE)
  )
  signal <- signal_strength * as.numeric(signal)

  colnames(beta) <- paste0("beta", seq_len(ncol(beta)))
  rownames(beta) <- colnames(data$X)
  colnames(eta) <- paste0("eta", seq_len(ncol(eta)))

  data$beta <- beta
  data$B <- beta
  data$eta <- eta
  data$U <- eta
  data$signal <- signal
  data$y <- signal + data$epsilon
  data$beta_type <- "training_basis"
  data
}

fit_scenario <- function(train, simulation, sdr_method, cov_method, select_dimension) {
  risdr::fit_risdr(
    X = train$X,
    y = train$y,
    sdr_method = sdr_method,
    cov_method = cov_method,
    nslices = simulation$slices,
    d = if (select_dimension) NULL else simulation$true_dimension,
    d_max = simulation$maximum_dimension,
    selector = simulation$selector,
    standardize = TRUE,
    stabilize = TRUE
  )
}

failure_row <- function(experiment, scenario_id, replication, scenario,
                        true_dimension, sdr_method, cov_method, error, elapsed,
                        prediction_study) {
  row <- data.frame(
    experiment = experiment,
    scenario_id = scenario_id,
    replication = replication,
    n = scenario$n,
    p = scenario$p,
    rho = scenario$rho,
    true_d = true_dimension,
    sdr_method = toupper(sdr_method),
    cov_method = toupper(cov_method),
    status = "failed",
    error_message = conditionMessage(error),
    selected_d = NA_integer_,
    selected_correctly = NA_integer_,
    condition_number = NA_real_,
    effective_rank = NA_real_,
    runtime_seconds = elapsed,
    stringsAsFactors = FALSE
  )

  if (prediction_study) {
    row$subspace_distance <- NA_real_
    row$RMSE <- NA_real_
    row$MAE <- NA_real_
    row$R2 <- NA_real_
    row$Adjusted_R2 <- NA_real_
    row$Correlation <- NA_real_
  }

  row
}

success_prediction_row <- function(experiment, scenario_id, replication,
                                   scenario, true_dimension, sdr_method,
                                   cov_method, fit, train, test, elapsed) {
  prediction <- stats::predict(fit, newX = test$X)
  performance <- risdr::evaluate_prediction(
    y_true = test$y,
    y_pred = prediction,
    d = true_dimension
  )
  distance <- risdr::subspace_distance(
    B_hat = fit$directions[, seq_len(true_dimension), drop = FALSE],
    B = train$beta
  )
  diagnostics <- risdr::cov_diagnostics(fit$Sigma)

  data.frame(
    experiment = experiment,
    scenario_id = scenario_id,
    replication = replication,
    n = scenario$n,
    p = scenario$p,
    rho = scenario$rho,
    true_d = true_dimension,
    sdr_method = toupper(sdr_method),
    cov_method = toupper(cov_method),
    status = "success",
    error_message = NA_character_,
    selected_d = fit$d,
    selected_correctly = as.integer(fit$d == true_dimension),
    condition_number = diagnostics$condition_number,
    effective_rank = diagnostics$effective_rank,
    runtime_seconds = elapsed,
    subspace_distance = distance,
    RMSE = performance$RMSE,
    MAE = performance$MAE,
    R2 = performance$R2,
    Adjusted_R2 = performance$Adjusted_R2,
    Correlation = performance$Correlation,
    stringsAsFactors = FALSE
  )
}

success_dimension_row <- function(experiment, scenario_id, replication,
                                  scenario, true_dimension, sdr_method,
                                  cov_method, fit, elapsed) {
  diagnostics <- risdr::cov_diagnostics(fit$Sigma)

  data.frame(
    experiment = experiment,
    scenario_id = scenario_id,
    replication = replication,
    n = scenario$n,
    p = scenario$p,
    rho = scenario$rho,
    true_d = true_dimension,
    sdr_method = toupper(sdr_method),
    cov_method = toupper(cov_method),
    status = "success",
    error_message = NA_character_,
    selected_d = fit$d,
    selected_correctly = as.integer(fit$d == true_dimension),
    condition_number = diagnostics$condition_number,
    effective_rank = diagnostics$effective_rank,
    runtime_seconds = elapsed,
    stringsAsFactors = FALSE
  )
}

write_checkpoint <- function(rows, output_dir, filename) {
  full <- dplyr::bind_rows(rows)
  readr::write_csv(full, file.path(output_dir, filename), na = "")
  invisible(full)
}

run_prediction_study <- function(study, experiment, grid, simulation,
                                 train_seed_base, test_seed_base, output_dir,
                                 verbose, stop_on_failure) {
  rows <- vector("list", nrow(grid) * simulation$replications)
  counter <- 1L
  full_filename <- paste0(experiment, "_full_corrected_v0_3_0.csv")

  for (scenario_id in seq_len(nrow(grid))) {
    scenario <- grid[scenario_id, , drop = FALSE]

    for (replication in seq_len(simulation$replications)) {
      report_progress(
        verbose,
        study,
        scenario_id,
        nrow(grid),
        replication,
        scenario
      )

      train <- simulation_data(
        simulation,
        scenario,
        simulation_seed(train_seed_base, scenario_id, replication)
      )
      test <- simulation_data(
        simulation,
        scenario,
        simulation_seed(test_seed_base, scenario_id, replication)
      )
      test <- replace_simulation_basis(
        data = test,
        beta = train$beta,
        model = simulation$signal_model,
        signal_strength = simulation$signal_strength
      )

      sdr_method <- if ("sdr_method" %in% names(scenario)) {
        scenario$sdr_method
      } else {
        "dr"
      }
      cov_method <- if ("cov_method" %in% names(scenario)) {
        scenario$cov_method
      } else {
        "oas"
      }

      fitted <- fit_elapsed(
        fit_scenario(
          train,
          simulation,
          sdr_method = sdr_method,
          cov_method = cov_method,
          select_dimension = FALSE
        )
      )

      if (inherits(fitted$value, "error")) {
        rows[[counter]] <- failure_row(
          experiment,
          scenario_id,
          replication,
          scenario,
          simulation$true_dimension,
          sdr_method,
          cov_method,
          fitted$value,
          fitted$elapsed,
          prediction_study = TRUE
        )

        if (stop_on_failure) {
          stop(fitted$value)
        }
      } else {
        evaluated <- tryCatch(
          success_prediction_row(
            experiment,
            scenario_id,
            replication,
            scenario,
            simulation$true_dimension,
            sdr_method,
            cov_method,
            fitted$value,
            train,
            test,
            fitted$elapsed
          ),
          error = identity
        )

        if (inherits(evaluated, "error")) {
          rows[[counter]] <- failure_row(
            experiment,
            scenario_id,
            replication,
            scenario,
            simulation$true_dimension,
            sdr_method,
            cov_method,
            evaluated,
            fitted$elapsed,
            prediction_study = TRUE
          )

          if (stop_on_failure) {
            stop(evaluated)
          }
        } else {
          rows[[counter]] <- evaluated
        }
      }

      counter <- counter + 1L
    }

    write_checkpoint(rows[seq_len(counter - 1L)], output_dir, full_filename)
  }

  dplyr::bind_rows(rows)
}

run_dimension_study <- function(grid, simulation, train_seed_base, output_dir,
                                verbose, stop_on_failure) {
  experiment <- "simulation_B2_dimension_recovery_OAS"
  rows <- vector("list", nrow(grid) * simulation$replications)
  counter <- 1L
  full_filename <- paste0(experiment, "_full_corrected_v0_3_0.csv")

  for (scenario_id in seq_len(nrow(grid))) {
    scenario <- grid[scenario_id, , drop = FALSE]

    for (replication in seq_len(simulation$replications)) {
      report_progress(
        verbose,
        "B2",
        scenario_id,
        nrow(grid),
        replication,
        scenario
      )

      train <- simulation_data(
        simulation,
        scenario,
        simulation_seed(train_seed_base, scenario_id, replication)
      )
      fitted <- fit_elapsed(
        fit_scenario(
          train,
          simulation,
          sdr_method = scenario$sdr_method,
          cov_method = "oas",
          select_dimension = TRUE
        )
      )

      if (inherits(fitted$value, "error")) {
        rows[[counter]] <- failure_row(
          experiment,
          scenario_id,
          replication,
          scenario,
          simulation$true_dimension,
          scenario$sdr_method,
          "oas",
          fitted$value,
          fitted$elapsed,
          prediction_study = FALSE
        )

        if (stop_on_failure) {
          stop(fitted$value)
        }
      } else {
        rows[[counter]] <- success_dimension_row(
          experiment,
          scenario_id,
          replication,
          scenario,
          simulation$true_dimension,
          scenario$sdr_method,
          "oas",
          fitted$value,
          fitted$elapsed
        )
      }

      counter <- counter + 1L
    }

    write_checkpoint(rows[seq_len(counter - 1L)], output_dir, full_filename)
  }

  dplyr::bind_rows(rows)
}

summarise_simulation_a <- function(full) {
  full |>
    dplyr::filter(.data$status == "success") |>
    dplyr::group_by(.data$n, .data$p, .data$rho, .data$cov_method) |>
    dplyr::summarise(
      n_success = dplyr::n(),
      mean_selected_d = mean(.data$selected_d),
      median_selected_d = stats::median(.data$selected_d),
      dimension_recovery_rate = mean(.data$selected_correctly),
      mean_subspace_distance = mean(.data$subspace_distance),
      sd_subspace_distance = stats::sd(.data$subspace_distance),
      mean_RMSE = mean(.data$RMSE),
      sd_RMSE = stats::sd(.data$RMSE),
      mean_MAE = mean(.data$MAE),
      mean_R2 = mean(.data$R2),
      mean_Correlation = mean(.data$Correlation),
      mean_condition_number = mean(.data$condition_number),
      mean_effective_rank = mean(.data$effective_rank),
      mean_runtime_seconds = mean(.data$runtime_seconds),
      .groups = "drop"
    ) |>
    dplyr::arrange(.data$rho, .data$n, .data$p, .data$mean_subspace_distance)
}

summarise_simulation_b1 <- function(full) {
  full |>
    dplyr::filter(.data$status == "success") |>
    dplyr::group_by(.data$n, .data$p, .data$rho, .data$sdr_method) |>
    dplyr::summarise(
      n_success = dplyr::n(),
      mean_subspace_distance = mean(.data$subspace_distance),
      sd_subspace_distance = stats::sd(.data$subspace_distance),
      mean_RMSE = mean(.data$RMSE),
      sd_RMSE = stats::sd(.data$RMSE),
      mean_MAE = mean(.data$MAE),
      mean_R2 = mean(.data$R2),
      mean_Correlation = mean(.data$Correlation),
      mean_condition_number = mean(.data$condition_number),
      mean_effective_rank = mean(.data$effective_rank),
      mean_runtime_seconds = mean(.data$runtime_seconds),
      .groups = "drop"
    ) |>
    dplyr::arrange(.data$rho, .data$n, .data$p, .data$mean_subspace_distance)
}

summarise_simulation_b2 <- function(full) {
  full |>
    dplyr::filter(.data$status == "success") |>
    dplyr::group_by(.data$n, .data$p, .data$rho, .data$sdr_method) |>
    dplyr::summarise(
      n_success = dplyr::n(),
      mean_selected_d = mean(.data$selected_d),
      median_selected_d = stats::median(.data$selected_d),
      dimension_recovery_rate = mean(.data$selected_correctly),
      sd_selected_d = stats::sd(.data$selected_d),
      mean_condition_number = mean(.data$condition_number),
      mean_effective_rank = mean(.data$effective_rank),
      mean_runtime_seconds = mean(.data$runtime_seconds),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      .data$rho,
      .data$n,
      .data$p,
      dplyr::desc(.data$dimension_recovery_rate)
    )
}

round_prediction_summary <- function(summary) {
  summary |>
    dplyr::mutate(
      dplyr::across(
        dplyr::any_of(c("mean_selected_d", "median_selected_d", "mean_effective_rank")),
        ~ round(.x, 2)
      ),
      dplyr::across(
        dplyr::any_of("dimension_recovery_rate"),
        ~ round(.x, 3)
      ),
      dplyr::across(
        dplyr::any_of(c(
          "mean_subspace_distance", "sd_subspace_distance", "mean_RMSE",
          "sd_RMSE", "mean_MAE", "mean_R2", "mean_Correlation",
          "mean_runtime_seconds"
        )),
        ~ round(.x, 4)
      ),
      dplyr::across(
        dplyr::any_of("mean_condition_number"),
        ~ signif(.x, 4)
      )
    )
}

round_dimension_summary <- function(summary) {
  summary |>
    dplyr::mutate(
      mean_selected_d = round(.data$mean_selected_d, 2),
      median_selected_d = round(.data$median_selected_d, 2),
      dimension_recovery_rate = round(.data$dimension_recovery_rate, 3),
      sd_selected_d = round(.data$sd_selected_d, 3),
      mean_condition_number = signif(.data$mean_condition_number, 4),
      mean_effective_rank = round(.data$mean_effective_rank, 2),
      mean_runtime_seconds = round(.data$mean_runtime_seconds, 4)
    )
}

write_study_tables <- function(study, full, output_dir) {
  if (study == "A") {
    summary <- round_prediction_summary(summarise_simulation_a(full))
    best <- summary |>
      dplyr::group_by(.data$n, .data$p, .data$rho) |>
      dplyr::slice_min(.data$mean_subspace_distance, n = 1L, with_ties = FALSE) |>
      dplyr::ungroup()
    ranking <- summary |>
      dplyr::group_by(.data$cov_method) |>
      dplyr::summarise(
        avg_subspace_distance = mean(.data$mean_subspace_distance),
        avg_dimension_recovery_rate = mean(.data$dimension_recovery_rate),
        avg_RMSE = mean(.data$mean_RMSE),
        avg_R2 = mean(.data$mean_R2),
        avg_condition_number = mean(.data$mean_condition_number),
        avg_runtime_seconds = mean(.data$mean_runtime_seconds),
        .groups = "drop"
      ) |>
      dplyr::arrange(.data$avg_subspace_distance)
    prefix <- "simulation_A_covariance_DR"
  } else if (study == "B1") {
    summary <- round_prediction_summary(summarise_simulation_b1(full))
    best <- summary |>
      dplyr::group_by(.data$n, .data$p, .data$rho) |>
      dplyr::slice_min(.data$mean_subspace_distance, n = 1L, with_ties = FALSE) |>
      dplyr::ungroup()
    ranking <- summary |>
      dplyr::group_by(.data$sdr_method) |>
      dplyr::summarise(
        avg_subspace_distance = mean(.data$mean_subspace_distance),
        avg_RMSE = mean(.data$mean_RMSE),
        avg_R2 = mean(.data$mean_R2),
        avg_condition_number = mean(.data$mean_condition_number),
        avg_runtime_seconds = mean(.data$mean_runtime_seconds),
        .groups = "drop"
      ) |>
      dplyr::arrange(.data$avg_subspace_distance)
    prefix <- "simulation_B1_SDR_estimation_OAS"
  } else {
    summary <- round_dimension_summary(summarise_simulation_b2(full))
    best <- summary |>
      dplyr::group_by(.data$n, .data$p, .data$rho) |>
      dplyr::slice_max(.data$dimension_recovery_rate, n = 1L, with_ties = FALSE) |>
      dplyr::ungroup()
    ranking <- summary |>
      dplyr::group_by(.data$sdr_method) |>
      dplyr::summarise(
        avg_dimension_recovery_rate = mean(.data$dimension_recovery_rate),
        avg_selected_d = mean(.data$mean_selected_d),
        avg_sd_selected_d = mean(.data$sd_selected_d),
        avg_condition_number = mean(.data$mean_condition_number),
        avg_runtime_seconds = mean(.data$mean_runtime_seconds),
        .groups = "drop"
      ) |>
      dplyr::arrange(dplyr::desc(.data$avg_dimension_recovery_rate))
    prefix <- "simulation_B2_dimension_recovery_OAS"
  }

  suffix <- "corrected_v0_3_0.csv"
  readr::write_csv(summary, file.path(output_dir, paste0(prefix, "_summary_", suffix)), na = "")
  readr::write_csv(best, file.path(output_dir, paste0(prefix, "_best_by_scenario_", suffix)), na = "")
  readr::write_csv(ranking, file.path(output_dir, paste0(prefix, "_overall_ranking_", suffix)), na = "")

  invisible(list(summary = summary, best = best, ranking = ranking))
}

run_corrected_simulations <- function(config_path = "config.yml") {
  config <- read_simulation_config(config_path)
  simulation <- config$simulation
  seeds <- simulation$seeds

  output_dir <- config$paths$simulation_output %||% "analysis/results-corrected"
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  results <- list()

  if ("A" %in% config$execution$studies) {
    grid_a <- expand.grid(
      n = simulation$sample_sizes,
      p = simulation$predictor_counts,
      rho = simulation$correlations,
      cov_method = simulation$covariance_methods,
      stringsAsFactors = FALSE
    )
    results$A <- run_prediction_study(
      study = "A",
      experiment = "simulation_A_covariance_DR",
      grid = grid_a,
      simulation = simulation,
      train_seed_base = seeds$simulation_a_train,
      test_seed_base = seeds$simulation_a_test,
      output_dir = output_dir,
      verbose = config$execution$verbose,
      stop_on_failure = config$execution$stop_on_failure
    )
    write_study_tables("A", results$A, output_dir)
  }

  if (any(c("B1", "B2") %in% config$execution$studies)) {
    grid_b <- expand.grid(
      n = simulation$sample_sizes,
      p = simulation$predictor_counts,
      rho = simulation$correlations,
      sdr_method = simulation$sdr_methods,
      stringsAsFactors = FALSE
    )
  }

  if ("B1" %in% config$execution$studies) {
    results$B1 <- run_prediction_study(
      study = "B1",
      experiment = "simulation_B1_SDR_estimation_OAS",
      grid = grid_b,
      simulation = simulation,
      train_seed_base = seeds$simulation_b1_train,
      test_seed_base = seeds$simulation_b1_test,
      output_dir = output_dir,
      verbose = config$execution$verbose,
      stop_on_failure = config$execution$stop_on_failure
    )
    write_study_tables("B1", results$B1, output_dir)
  }

  if ("B2" %in% config$execution$studies) {
    results$B2 <- run_dimension_study(
      grid = grid_b,
      simulation = simulation,
      train_seed_base = seeds$simulation_b2_train,
      output_dir = output_dir,
      verbose = config$execution$verbose,
      stop_on_failure = config$execution$stop_on_failure
    )
    write_study_tables("B2", results$B2, output_dir)
  }

  metadata <- c(
    paste("Completed:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
    paste("Package version:", as.character(utils::packageVersion("risdr"))),
    paste("Configuration:", normalizePath(config_path, mustWork = TRUE)),
    paste("Studies:", paste(config$execution$studies, collapse = ", ")),
    paste("Replications:", simulation$replications),
    "Training and test samples share the same true basis in prediction studies.",
    "",
    capture.output(utils::sessionInfo())
  )
  writeLines(metadata, file.path(output_dir, "simulation_metadata_corrected_v0_3_0.txt"))

  invisible(results)
}

if (sys.nframe() == 0L) {
  arguments <- commandArgs(trailingOnly = TRUE)
  config_path <- if (length(arguments) >= 1L) arguments[[1L]] else "config.yml"
  run_corrected_simulations(config_path)
}
