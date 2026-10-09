# Slice response for inverse regression

Constructs slice labels for continuous, categorical, or censored
survival responses. For censored survival data, double slicing is used
by first splitting on censoring status and then slicing observed time
within each status group.

## Arguments

- y:

  Response vector. For survival data, observed time.

- nslices:

  Number of slices for continuous data or per censoring-status group for
  survival data.

- response_type:

  One of `"continuous"`, `"categorical"`, or `"survival"`.

- delta:

  Optional 0/1 event indicator for survival data.

## Value

A list containing integer slice labels and metadata.
