#' risdr: Regularised and Information-Theoretic Sufficient Dimension Reduction
#'
#' The package implements SIR, SAVE, DR, and pHd for continuous responses,
#' together with covariance regularisation, information-theoretic structural
#' dimension selection, prediction, resampling, simulation, and diagnostic
#' utilities.
#'
#' @section Main interface:
#' Use [fit_risdr()] to estimate an SDR model and [predict.risdr()] to obtain
#' predictions for new observations. Use [select_dimension_cv()],
#' [select_dimension_cv_icomp()], or [select_dimension_ladle()] for
#' complementary structural-dimension diagnostics.
#'
#' @section Scope:
#' Version 0.3.0 verifies the complete modelling workflow for continuous
#' responses. Binary, multiclass, and censored survival extensions remain
#' outside the supported modelling interface.
#'
#' @docType package
#' @name risdr-package
"_PACKAGE"
