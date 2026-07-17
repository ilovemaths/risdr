# Two-direction sufficient summary plot

Plots the first two selected SDR scores, optionally coloured by
response.

## Usage

``` r
plot_sufficient2d(
  fit,
  directions = c(1, 2),
  colour_by_y = TRUE,
  groups = 4,
  ...
)
```

## Arguments

- fit:

  Object of class "risdr".

- directions:

  Integer vector of length 2.

- colour_by_y:

  Logical. If TRUE, colours points by response quantile group.

- groups:

  Number of response colour groups.

- ...:

  Additional graphical arguments passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

Invisibly returns plotted data.
