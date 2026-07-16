# Supplied research-result fixtures

The summary CSV files were selected from the supplied
`Thesis_Results_Adebiyi.zip` archive. The four EPI input matrices were supplied
separately for v0.3.0. They support vignette examples, reproducible empirical
analysis, and provenance checks.

The `epi` directory contains `X_old.csv`, `X_new.csv`, `y_old.csv`, and
`y_new.csv`, plus selected empirical comparison and repeated cross-validation
summaries. Each predictor matrix has 180 rows and the same 70 columns. The
`simulation` directory contains selected Simulation A, B1, and B2 summaries
and rankings.

Input-file SHA-256 digests are:

- `X_old.csv`: `b18bf20cacb1f51245451edfc2384f4431d9ee2969f20ad1aa4696d7a6558b90`;
- `X_new.csv`: `d03dcf03f0be248ed39405abf829e6fb6c1ce4b57770b44bda72732a79217be5`;
- `y_old.csv`: `0200104325dd20ee7893b766c5df5a4a9138159db3f60978d717337548424f2b`;
- `y_new.csv`: `d1c093a3095e9679e9bfc05cf5a5ea9168cec62f018793e0b4f33c957c5b4144`.

Simulation A and B1 external-prediction columns have legacy status because the
historical script independently generated the random-sparse basis in the
training and test samples. Simulation B2 does not use an external test sample,
but remains a supplied historical record pending the unified corrected rerun.

Use `analysis/reproduce_simulations.R` from the repository archive to generate
new corrected outputs. The script writes distinct filenames and does not
overwrite these fixtures.
