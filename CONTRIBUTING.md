# Contributing to cudaverse

Thank you for helping build GPU-aware scientific computing tools for R.

## Before opening an issue

- Search existing issues and package documentation.
- Include the package version, R version, operating system, backend, and device.
- For CUDA problems, include `cudatensr::cuda_available()` and the installed
  R torch/libtorch versions. Do not include tokens or private system data.
- Provide a small reproducible example whenever possible.

## Pull requests

1. Create a focused branch.
2. Add or update `testthat` coverage.
3. Run `R CMD check --as-cran` on a clean source package.
4. Document whether a change was tested on CPU, CUDA, or both.
5. Keep public R dimensions one-based even when backend indices are zero-based.
6. Update NEWS and README when changing the public API.

CUDA-specific changes should include a CPU reference result and a tolerance-
based correctness comparison.

## Scope

The organization prioritizes R-native tensor, sparse, algorithm, and omics
workflows. Integrations should preserve R/Bioconductor metadata and avoid
unnecessary conversion round-trips.
