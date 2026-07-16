# Plot SDR loadings

Displays the largest absolute loadings for a selected SDR direction.

## Usage

``` r
plot_loadings(fit, direction = 1, top = 15, ...)
```

## Arguments

- fit:

  Object of class "risdr".

- direction:

  Direction index.

- top:

  Number of variables to display.

- ...:

  Additional graphical arguments passed to
  [`graphics::barplot()`](https://rdrr.io/r/graphics/barplot.html).

## Value

Invisibly returns loading table.
