# Predict from the sparse or dual SDR engine

Projects new observations using the training centring, scaling, and
selected directions. Survival predictions are Cox linear predictors or
relative risks; they are not predicted survival times.

## Usage

``` r
# S3 method for class 'risdr_sparse'
predict(
  object,
  newX,
  type = c("response", "scores", "link", "risk", "class", "probs"),
  ...
)

# S3 method for class 'risdr_dual'
predict(
  object,
  newX,
  type = c("response", "scores", "link", "risk", "class", "probs"),
  ...
)
```

## Arguments

- object:

  A sparse or dual RISDR fit.

- newX:

  Numeric predictor matrix or data frame, with named columns.

- type:

  Prediction type. `"response"` returns continuous predictions, binary
  probabilities, multiclass labels, or survival relative risks.
  `"scores"` returns the selected SDR coordinates. `"link"` and `"risk"`
  are available for survival outcomes. `"class"` and `"probs"` are
  available for categorical outcomes.

- ...:

  Additional arguments passed to the downstream prediction method.

## Value

Predictions or a score matrix, according to `type`.
