# Frozen thesis engine and release provenance

This release extends the existing `ilovemaths/risdr` project and CRAN
package. It retains Kabir Olorede as the author and maintainer and GPL
(\>= 3) licensing. No separate CRAN package or new software identity is
created.

## Source

The local package supplied for Adetunji Dayo Atimiwoaye’s thesis was
`risdr` 0.3.2. The original R sources, DESCRIPTION, and permanent
regression tests are retained under `tools/frozen/risdr-0.3.2`. They
exclude R workspace files, patient-level data, analysis checkpoints,
generated thesis figures, and local Git history.
`tools/frozen/SOURCE_SHA256.csv` records source hashes.

The thesis is titled *Information-Complexity-Guided Regularised
Sufficient Dimension Reduction for High-Dimensional Lung Adenocarcinoma
Survival Data*. This record identifies its application context and does
not change package authorship or represent the unexamined thesis as a
published article.

## Integration

`tools/generate-thesis-engine.R` writes the static `R/thesis_engine.R`
file. It traverses the dependency closure of the additional public
functions, renames colliding helpers, and separates sparse fit classes
from the existing `risdr` class. It does not change their numerical
algorithms, thresholds, criteria, default arguments, or fitted-data
processing. The generator requires only base R and can be rerun from the
package root.

| Frozen 0.3.2 interface | Public 0.4.0 interface |
|:---|:---|
| [`fit_risdr()`](https://ilovemaths.github.io/risdr/reference/fit_risdr.md) | [`fit_risdr_sparse()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse.md) |
| [`fit_risdr_realdata()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_realdata.md) | [`fit_risdr_sparse_realdata()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_sparse_realdata.md) |
| [`fit_risdr_dual()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_dual.md) | [`fit_risdr_dual()`](https://ilovemaths.github.io/risdr/reference/fit_risdr_dual.md) |
| class `risdr` | class `risdr_sparse` |
| class `risdr_realdata` | class `risdr_sparse_realdata` |

The full symbol mapping is `tools/frozen/FUNCTION_MAPPING.csv`. The
retained 0.3.1 API, including
[`fit_risdr()`](https://ilovemaths.github.io/risdr/reference/fit_risdr.md),
continues to use the existing continuous engine. The package-level
dependency changes, documentation, prediction adapters, and additional
tests are release work, not alterations to the frozen thesis analysis.
The prediction adapters support new observations, column-name alignment,
and Cox risks, which the frozen prediction method did not support.

## Method conventions to preserve

- SIR, SAVE, and canonical pairwise-slice DR use censoring-status/time
  slicing.
- Cox selection uses Efron partial likelihood; `support_penalty = FALSE`
  means survival effective count `k = d`.
- Joint `(d, lambda)` selection retains the complete criterion grid.
- Coordinate-level C1F contributions produce adaptive weights with mean
  one.
- The all-zero direction safeguard is retained.
- Inner dual-score scaling is undone before mapping selected directions.
- Original-predictor rankings use selected mapped direction row norms.

No frozen thesis result has been rerun or overwritten during this
packaging step. Synthetic regression tests exercise the source
equivalence and adapters. The thesis’s numerical outputs retain their
original 0.3.2 provenance.

## Validation records

The new tests retain the permanent frozen regression cases and add
prediction and source-equivalence checks. The existing CRAN package
tests are retained. Release-specific checks and CRAN comments are
recorded separately, so historical Windows checks for frozen 0.3.2 are
not presented as checks of this new release.
