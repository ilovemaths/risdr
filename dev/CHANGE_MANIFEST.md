# risdr v0.3.0 change manifest

| Area | Baseline condition | v0.3.0 action |
|----|----|----|
| Package metadata | `DESCRIPTION` reported 0.0.1 | Set the development release to 0.3.0 and completed dependency metadata |
| Documentation | Manual pages existed, but examples and articles were incomplete | Expanded roxygen sources and added five vignettes |
| Tests | One smoke test and a misplaced test runner | Added a root test runner and topic-specific tests |
| Cross-validation | Repeated and complexity-aware functions were unexported | Documented and exported both interfaces |
| Argument routing | `...` was passed to unrelated components | Added explicit component argument lists and validation |
| Prediction | Required at least five new observations | Permitted single-observation prediction and checked column identities |
| Numerical code | LW and pHd used avoidable observation loops | Replaced them with vectorised matrix calculations |
| Repository | No README, issue templates, CI, or release guidance | Added repository documentation and automated workflows |
| Website | No configuration or articles | Added `_pkgdown.yml` and a five-article structure |
| Reproducibility | Results were external to the package | Added selected supplied summary fixtures under `inst/extdata` with legacy status |
| Simulation design | Random-sparse training and test bases were regenerated independently | Added shared-basis simulation support and marked affected historical prediction outputs for rerun |
| Simulation reproduction | Monolithic historical code and no external configuration | Added `config.yml` and a corrected, checkpointed A/B1/B2 rerun script |
| MEC terminology | Handover and source used different expansions | Confirmed Maximum Entropy Covariance as authoritative |
| EPI inputs | Processed inputs were not included | Added aligned old/new predictors and responses with checksums |
| Real-data fixed dimension | Short argument `d` partially matched `delta` | Added an explicit `d` argument and forwarded it to [`fit_risdr()`](https://ilovemaths.github.io/risdr/dev/reference/fit_risdr.md) |

The completed thesis text remains frozen. Supplied numerical results are
retained as historical records, while the affected simulation prediction
metrics remain explicitly pending correction and are not asserted as
validated v0.3.0 findings.
