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
#' [fit_risdr()] retains its continuous-response scope. Use
#' [fit_risdr_sparse()] for joint dimension and sparsity selection with
#' continuous, categorical, and right-censored survival responses, or
#' [fit_risdr_dual()] for sample-space PCA reduction when predictors outnumber
#' observations. [fit_risdr_sparse_realdata()] adds variance screening.
#' See the sparse-survival vignette for the frozen thesis conventions.
#'
#' @docType package
#' @name risdr-package
"_PACKAGE"
