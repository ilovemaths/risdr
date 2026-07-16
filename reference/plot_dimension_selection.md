# Plot dimension selection criteria

Plot dimension selection criteria

## Usage

``` r
plot_dimension_selection(
  fit,
  criteria = c("AIC", "BIC", "CAIC", "ICOMP", "CICOMP"),
  ...
)
```

## Arguments

- fit:

  Object of class "risdr".

- criteria:

  Character vector of criteria to plot.

- ...:

  Additional graphical arguments passed to
  [`graphics::matplot()`](https://rdrr.io/r/graphics/matplot.html).

## Value

Invisibly returns dimension table.
