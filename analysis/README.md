# Corrected simulation reproduction

The supplied thesis implementation generated random-sparse training and test
bases independently in Simulations A and B1. The historical prediction
metrics from those two studies therefore compare responses generated from
different central subspaces. The package preserves the supplied outputs as
legacy provenance fixtures, but does not present them as validated v0.3.0
results.

The corrected workflow replaces the independently generated test basis with
the corresponding training basis before constructing the test response. It
preserves the original scenario order, test predictors, error draw, and seed
rule, so the targeted rerun changes the subspace mismatch rather than the
remaining random components. It writes new files with a `_corrected_v0_3_0`
suffix and never overwrites the legacy fixtures.

From the package root, install the package and run:

```r
install.packages(".", repos = NULL, type = "source")
source("analysis/reproduce_simulations.R")
run_corrected_simulations("config.yml")
```

The equivalent non-interactive command is:

```sh
Rscript analysis/reproduce_simulations.R config.yml
```

The default configuration reproduces the original scenario grid with 200
replications. For a smoke run, copy `config.yml`, set `replications: 1`, and
pass the copied configuration path to the script. The output directory is
configured under `paths.simulation_output`.

This command covers the simulations only. The supplied processed EPI `.old`
and `.new` inputs are bundled under `inst/extdata/epi` and documented in the
EPI vignette.
