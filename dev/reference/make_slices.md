# Create response slices

Constructs response slices for inverse regression-based sufficient
dimension reduction methods.

## Usage

``` r
make_slices(y, nslices = 6, type = c("quantile", "equal_width"))
```

## Arguments

- y:

  Numeric continuous response vector.

- nslices:

  Number of slices.

- type:

  Slicing strategy. Currently supports "quantile" and "equal_width".

## Value

Integer vector of slice memberships.
