#' Compute all reduced-model information criteria
#'
#' @param y Response vector.
#' @param Z Reduced predictors.
#' @param response_type Response type.
#' @param delta Optional event indicator.
#' @param n_active Optional active-support size.
#' @param support_penalty Include active-support size in effective df.
#' @param tol Numerical tolerance.
#' @return Named numeric vector containing AIC, BIC, CAIC, ICOMP, CICOMP,
#'   log-likelihood, effective df, and C1F.
#' @export
#' @name compute_ic_values
NULL

#' Compute one reduced-model information criterion
#'
#' @param y Response vector.
#' @param Z Reduced predictors.
#' @param criterion Criterion name.
#' @param response_type Response type.
#' @param delta Optional event indicator.
#' @param n_active Optional active-support size.
#' @param support_penalty Include active-support size in effective df.
#' @param tol Numerical tolerance.
#' @return Scalar criterion value.
#' @export
#' @name compute_ic
NULL

#' Fit regularised and information-theoretic sufficient dimension reduction
#'
#' Fits an SDR model using a regularised covariance estimator, a selected
#' inverse-regression kernel, adaptive sparse direction estimation, and
#' information-criterion profiling jointly over structural dimension and
#' sparsity tuning parameter.
#'
#' For `d = NULL`, every candidate dimension from 1 through `d_max` is
#' evaluated over the complete `lambda_grid`. The requested selector then
#' chooses the final `(d, lambda)` pair. For explicit `d`, the same audit grid
#' is retained but the final dimension is fixed and only lambda is selected
#' within that dimension.
#'
#' @param X Numeric predictor matrix or data frame.
#' @param y Response vector. For survival data, observed survival time.
#' @param delta Optional 0/1 event indicator for survival data.
#' @param response_type One of `"continuous"`, `"categorical"`, or
#'   `"survival"`.
#' @param sdr_method One of `"dr"`, `"sir"`, `"save"`, or `"phd"`.
#' @param cov_method One of `"mec"`, `"oas"`, `"lw"`, `"sample"`,
#'   `"ridge"`, or `"user"`.
#' @param stabilize Logical. Stage-3 thesis fits require covariance
#'   stabilisation and therefore currently require `TRUE`.
#' @param stabilization Stabilisation method passed to [estimate_cov()].
#' @param nslices Number of response slices, or slices per censoring-status
#'   group for survival data.
#' @param d Optional fixed structural dimension. If `NULL`, selected by
#'   `selector` from candidates 1 through `d_max`.
#' @param d_max Maximum candidate structural dimension.
#' @param selector One of `"cicomp"`, `"icomp"`, `"bic"`, `"caic"`,
#'   or `"aic"`.
#' @param standardize Logical. Standardise predictor columns before fitting.
#' @param complexity Retained for compatibility. The Stage-3 thesis engine
#'   uses the scale-invariant C1F complexity in ICOMP/CICOMP.
#' @param lambda_grid Non-negative sparsity tuning grid.
#' @param adapt_weights Logical. Use covariance-derived adaptive weights.
#' @param weight_mode One of `"c1f"`, `"inverse_c1f"`, or `"uniform"`.
#' @param penalty_weights Optional user-supplied variable-level weights.
#' @param support_penalty Logical. If `TRUE`, active-support size contributes
#'   to the effective parameter count in the information criteria.
#' @param cov_fun Optional user-defined covariance estimator.
#' @param shrinkage Ridge shrinkage parameter used by [estimate_cov()].
#' @param tol Numerical tolerance.
#' @param ... Additional arguments passed only to a user covariance estimator.
#' @return An object of class `risdr` containing the complete `(d, lambda)`
#'   selection grid, profiled dimension table, selected sparse directions,
#'   reduced predictors, covariance diagnostics, and compatibility fields.
#' @export
#' @details This entry point uses the frozen sparse thesis engine. The
#' existing [fit_risdr()] and [fit_risdr_realdata()] interfaces retain their
#' continuous-response behaviour from version 0.3.1. Survival fits use Efron
#' Cox partial likelihood. Apparent fit statistics and loading ranks are
#' exploratory and do not establish external predictive validity.
#' @examples
#' set.seed(2026)
#' X <- matrix(rnorm(80 * 6), 80)
#' colnames(X) <- paste0("G", 1:6)
#' time <- rexp(80, rate = exp(0.5 * X[, 1]))
#' delta <- rep(c(0L, 1L), 40)
#' fit <- fit_risdr_sparse(
#'   X, time, delta = delta, response_type = "survival",
#'   sdr_method = "sir", cov_method = "oas", nslices = 4,
#'   d_max = 2, lambda_grid = c(0, 0.05)
#' )
#' fit$d
#' predict(fit, X[1:2, , drop = FALSE], type = "risk")
#' @name fit_risdr_sparse
NULL

#' Print risdr object
#'
#' @param x Object of class "risdr".
#' @param ... Additional arguments passed to internal methods.
#'
#' @return Invisibly returns x.
#' @export
#' @name print.risdr_sparse
NULL

#' Summarise risdr object
#'
#' @param object Object of class "risdr".
#'
#' @return A list summary.
#' @param ... Additional arguments passed to internal methods.
#' @export
#' @name summary.risdr_sparse
NULL

#' Print summary of risdr object
#'
#' @param x Object of class "summary.risdr_sparse".
#' @param ... Additional arguments passed to internal methods.
#'
#' @return Invisibly returns x.
#' @export
#' @name print.summary.risdr_sparse
NULL

#' C1F complexity and induced adaptive weights
#'
#' Computes cumulative scale-invariant covariance complexity from leading
#' eigenvalues and converts the complexity profile to relative weights.
#'
#' @param evals Numeric vector of eigenvalues.
#' @param positive_only Logical; retain only positive eigenvalues.
#' @param cumulative Logical; compute cumulative C1F values.
#' @param tol Numerical tolerance.
#' @return A list with C1F values, induced weights, and processed eigenvalues.
#' @export
#' @name C1F
NULL

#' Compute adaptive penalty weights from C1F variable contributions
#'
#' For `mode = "c1f"`, the regularised covariance matrix is decomposed into
#' original-coordinate C1F contributions. Variables with larger contribution
#' receive smaller soft-threshold weights, matching the direction of the
#' historical C1F weighting rule while avoiding the invalid mapping of
#' eigenvalue indices directly to predictor indices. `inverse_c1f` reverses
#' that weighting. `uniform` returns equal weights.
#'
#' @param Sigma Regularised covariance matrix.
#' @param mode One of `"c1f"`, `"inverse_c1f"`, or `"uniform"`.
#' @param tol Numerical tolerance.
#' @return Numeric vector of variable-level penalty weights with mean one.
#' @export
#' @name compute_penalty_weights
NULL

#' Weighted soft-threshold operator
#'
#' @param z Numeric vector.
#' @param lambda Non-negative tuning parameter.
#' @param weights Penalty weights.
#' @param tol Numerical tolerance.
#' @return Thresholded vector.
#' @export
#' @name weighted_soft_threshold
NULL

#' Weighted sparse directions from dense SDR directions
#'
#' @param V Dense direction matrix.
#' @param lambda Non-negative tuning parameter.
#' @param weights Variable-level penalty weights.
#' @param tol Numerical tolerance.
#' @return Sparse direction matrix.
#' @export
#' @name weighted_sparsify_directions
NULL

#' Fit sparse SDR directions over a lambda grid
#'
#' Accepts either an explicit dense direction matrix or a historical kernel
#' object containing `directions` or `vectors`.
#'
#' @param kernel_obj Optional historical kernel object.
#' @param directions Optional dense direction matrix.
#' @param d Structural dimension.
#' @param lambda_grid Numeric vector of tuning values.
#' @param penalty_weights Optional user-supplied penalty weights.
#' @param adapt_weights Logical; derive weights from `Sigma` when TRUE.
#' @param Sigma Optional covariance matrix.
#' @param weight_mode Adaptive weighting mode.
#' @param tol Numerical tolerance.
#' @return Sparse-grid object.
#' @export
#' @name fit_sparse_grid
NULL

#' Summarise sparsity pattern
#'
#' @param V Direction matrix.
#' @param tol Threshold for active support.
#' @return Sparsity summary.
#' @export
#' @name summarise_sparsity
NULL

#' Dual PCA score construction for p much larger than n
#'
#' Constructs low-rank sample-space scores without forming a p by p covariance
#' matrix. This is useful when the number of predictors is very large.
#'
#' @param X Numeric predictor matrix with observations in rows.
#' @param dual_rank Number of dual components to retain.
#' @param variance_explained Optional cumulative variance threshold.
#' @param center Logical; if TRUE, centre predictors.
#' @param scale_X Logical; if TRUE, scale predictors.
#' @param eps Numerical tolerance.
#'
#' @return A list containing scores, loadings, singular values, centre, scale,
#'   and retained rank.
#' @export
#' @name dual_pca_scores
NULL

#' Fit dual high-dimensional RISDR
#'
#' Constructs a low-rank PCA score representation, fits the unified RISDR
#' core in that score space, maps the dense and selected sparse SDR directions
#' back to the original predictor coordinates, and ranks variables using the
#' Euclidean loading norm across only the selected sparse directions.
#'
#' The inner RISDR standardisation scale is explicitly undone before mapping
#' directions through the PCA loadings. The returned reduced predictors are
#' taken directly from the fitted core and are therefore exactly aligned with
#' the model used for information-criterion selection.
#'
#' @param X Numeric high-dimensional predictor matrix.
#' @param y Response vector. For survival data, observed time.
#' @param delta Optional 0/1 event indicator.
#' @param response_type One of `"continuous"`, `"categorical"`, or
#'   `"survival"`.
#' @param dual_rank Maximum retained PCA rank.
#' @param variance_explained Optional cumulative variance threshold.
#' @param d Optional fixed structural dimension. If `NULL`, selected by
#'   `selector`.
#' @param d_max Maximum candidate structural dimension.
#' @param nslices Number of slices, or slices per censoring-status group.
#' @param sdr_method SDR method.
#' @param cov_method Covariance method.
#' @param selector Information criterion used to select `(d, lambda)`.
#' @param lambda_grid Sparsity tuning grid.
#' @param adapt_weights Logical. Use adaptive penalty weights.
#' @param weight_mode Adaptive weighting mode.
#' @param support_penalty Logical. Include active support in criterion df.
#' @param standardize_dual Logical. Standardise retained PCA scores inside
#'   [fit_risdr_sparse()].
#' @param gene_select_top Optional number of top-ranked variables.
#' @param gene_select_quantile Quantile used when `gene_select_top` is NULL.
#' @param center Logical. Centre predictors before dual PCA.
#' @param scale_X Logical. Scale predictors before dual PCA.
#' @param verbose Logical. Emit progress messages.
#' @param ... Additional arguments passed to [fit_risdr_sparse()].
#' @return An object of class `risdr_dual`.
#' @export
#' @details This entry point uses the frozen sparse thesis engine. The
#' existing [fit_risdr()] and [fit_risdr_realdata()] interfaces retain their
#' continuous-response behaviour from version 0.3.1. Survival fits use Efron
#' Cox partial likelihood. Apparent fit statistics and loading ranks are
#' exploratory and do not establish external predictive validity.
#' @examples
#' set.seed(2026)
#' X <- matrix(rnorm(80 * 6), 80)
#' colnames(X) <- paste0("G", 1:6)
#' time <- rexp(80, rate = exp(0.5 * X[, 1]))
#' delta <- rep(c(0L, 1L), 40)
#' fit <- fit_risdr_dual(
#'   X, time, delta = delta, response_type = "survival",
#'   sdr_method = "sir", cov_method = "oas", nslices = 4,
#'   dual_rank = 4, verbose = FALSE, d_max = 2, lambda_grid = c(0, 0.05)
#' )
#' fit$d
#' predict(fit, X[1:2, , drop = FALSE], type = "risk")
#' @name fit_risdr_dual
NULL

#' Print method for dual RISDR objects
#'
#' @param x Object of class `risdr_dual`.
#' @param ... Additional arguments passed to internal methods.
#'
#' @export
#' @name print.risdr_dual
NULL

#' Summary method for dual RISDR objects
#'
#' @param object Object of class `risdr_dual`.
#' @param top_n Number of selected variables to print.
#' @param ... Additional arguments passed to internal methods.
#'
#' @export
#' @name summary.risdr_dual
NULL

#' Fit RISDR to real high-dimensional data
#'
#' @param X Predictor matrix.
#' @param y Response vector.
#' @param delta Optional survival censoring indicator.
#' @param response_type Response type.
#' @param variance_quantile Variance filtering threshold.
#' @param ... Additional arguments passed to fit_risdr_sparse().
#'
#' @return Fitted RISDR workflow object.
#' Fit RISDR to a real-data predictor matrix
#'
#' Applies outcome cleaning, low-variance screening, the unified RISDR core,
#' and descriptive loading-based variable ranking. The wrapper returns the
#' reduced predictors computed by the core itself so that centring and
#' standardisation are not silently bypassed.
#'
#'   `"multiclass"`, `"categorical"`, or `"survival"`.
#'   low-variance screen.
#' @return An object of class `risdr_realdata`.
#' @export
#' @details This entry point uses the frozen sparse thesis engine. The
#' existing [fit_risdr()] and [fit_risdr_realdata()] interfaces retain their
#' continuous-response behaviour from version 0.3.1. Survival fits use Efron
#' Cox partial likelihood. Apparent fit statistics and loading ranks are
#' exploratory and do not establish external predictive validity.
#' @name fit_risdr_sparse_realdata
NULL

#' Print real-data RISDR workflow
#'
#' @param x Object of class risdr_realdata.
#' @param ... Additional arguments.
#' @export
#' @name print.risdr_sparse_realdata
NULL

#' Slice response for inverse regression
#'
#' Constructs slice labels for continuous, categorical, or censored survival
#' responses. For censored survival data, double slicing is used by first
#' splitting on censoring status and then slicing observed time within each
#' status group.
#'
#' @param y Response vector. For survival data, observed time.
#' @param nslices Number of slices for continuous data or per censoring-status
#'   group for survival data.
#' @param response_type One of `"continuous"`, `"categorical"`, or
#'   `"survival"`.
#' @param delta Optional 0/1 event indicator for survival data.
#' @return A list containing integer slice labels and metadata.
#' @export
#' @name slice_response
NULL
