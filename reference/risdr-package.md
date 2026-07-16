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

Version 0.3.0 verifies the complete modelling workflow for continuous
responses. Binary, multiclass, and censored survival extensions remain
outside the supported modelling interface.

## See also

Useful links:

- <https://github.com/ilovemaths/risdr>

- <https://ilovemaths.github.io/risdr/>

- Report bugs at <https://github.com/ilovemaths/risdr/issues>

## Author

**Maintainer**: Kabir Olorede <kabirolorede@gmail.com>
