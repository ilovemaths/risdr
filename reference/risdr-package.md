# risdr: Regularised and Information-Theoretic Sufficient Dimension Reduction

The package implements SIR, SAVE, DR, and pHd for continuous responses,
together with covariance regularisation, information-theoretic
structural dimension selection, prediction, resampling, simulation, and
diagnostic utilities.

## Main interface

Use
[`fit_risdr()`](https://ilovemaths.github.io/risdr/reference/fit_risdr.md)
to estimate an SDR model and
[`predict.risdr()`](https://ilovemaths.github.io/risdr/reference/predict.risdr.md)
to obtain predictions for new observations. Use
[`select_dimension_cv()`](https://ilovemaths.github.io/risdr/reference/select_dimension_cv.md),
[`select_dimension_cv_icomp()`](https://ilovemaths.github.io/risdr/reference/select_dimension_cv_icomp.md),
or
[`select_dimension_ladle()`](https://ilovemaths.github.io/risdr/reference/select_dimension_ladle.md)
for complementary structural-dimension diagnostics.

## Scope

[`fit_risdr()`](https://ilovemaths.github.io/risdr/reference/fit_risdr.md)
retains its continuous-response scope. Use
[`fit_risdr_sparse()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse.md)
for joint dimension and sparsity selection with continuous, categorical,
and right-censored survival responses, or
[`fit_risdr_dual()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_dual.md)
for sample-space PCA reduction when predictors outnumber observations.
[`fit_risdr_sparse_realdata()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse_realdata.md)
adds variance screening. See the sparse-survival vignette for the frozen
thesis conventions.

## See also

Useful links:

- <https://github.com/ilovemaths/risdr>

- <https://ilovemaths.github.io/risdr/>

- Report bugs at <https://github.com/ilovemaths/risdr/issues>

## Author

**Maintainer**: Kabir Olorede <kabirolorede@gmail.com>
