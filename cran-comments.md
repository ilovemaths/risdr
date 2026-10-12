## Resubmission of risdr 0.4.0

The 10 October 2026 CRAN Debian precheck reported:
'slice_response.Rd': arguments were documented without usage.

Removed the stray NULL separating the roxygen block from slice_response().
Regenerated its help with usage matching all four arguments and defaults.
Corrected the generator to consume the final documentation-block separator.
All function bodies, formals, model-fitting code and frozen sources are unchanged.

## Local check of the revised source archive

Check date: 2026-10-11
R: R version 4.6.1 (2026-06-24 ucrt)
System: Windows 10 x64 x86-64
R CMD check --as-cran: 0 errors, 0 warnings and 0 notes.
CRAN incoming checks, examples, tests, vignette rebuilds and manuals passed.
Archive: risdr_0.4.0.tar.gz
SHA-256: 692d2f4038d7ce585b74f5387ec83be85eb057bafcb48a4facd786fec1b3b15f

## Win-builder recheck of the revised archive

This section will be completed after checking the revised archive with R-devel.

## Reverse dependencies

The 10 October 2026 CRAN precheck reported no strong reverse dependencies.
The maintainer's CRAN source-index query on that date found no reverse
Depends, Imports, LinkingTo, Suggests or Enhances entries.

## Update

Adds sparse continuous, categorical and survival workflows to CRAN 0.3.1.
The existing interfaces, maintainer, email address and GPL (>= 3) licence are unchanged.
