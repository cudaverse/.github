# cudaverse

GPU-aware scientific computing for R and Bioconductor workflows.

`cudaverse` is building an R-native foundation for dense tensors, sparse
matrices, numerical learning algorithms, and eventually single-cell and spatial
omics workflows. The ecosystem is designed around R objects and package
conventions instead of requiring users to move their analysis into Python.

## Core packages

| Package | Purpose | Status |
|---|---|---|
| [cudatensr](https://github.com/cudaverse/cudatensr) | Dense tensors, device transfer, matrix multiplication, reductions, broadcasting | Experimental MVP |
| [cudasparsr](https://github.com/cudaverse/cudasparsr) | COO/CSR sparse matrices, `dgCMatrix` conversion, sparse multiplication and reductions | Experimental MVP |
| [cudalearnr](https://github.com/cudaverse/cudalearnr) | PCA, SVD, distances, kNN, and k-means | Experimental MVP |

## Design principles

- R-native APIs and one-based dimensions at the public boundary.
- Explicit device and backend reporting.
- Correct, portable CPU fallbacks for development and CI.
- Optional CUDA execution through supported backends.
- First-class support for `matrix`, `array`, `Matrix::dgCMatrix`, and future
  Bioconductor object adapters.
- Honest benchmark and validation claims: GPU paths are not declared validated
  until they pass dedicated NVIDIA CI.

## Roadmap

The next layer will add:

- `cudacellr` for normalization, feature selection, PCA, and neighbor workflows.
- `cudagraphR` for kNN graphs and community detection.
- `cudaembedr` for UMAP and related embeddings.
- adapters for SingleCellExperiment and Seurat objects.
- dedicated CUDA correctness and performance runners.

## Contributing

The project is early and API feedback is valuable. Please read the organization
[contribution guide](https://github.com/cudaverse/.github/blob/main/CONTRIBUTING.md)
before opening a pull request.

## Project maturity

All packages are experimental. CPU code paths are covered by cross-platform
`R CMD check`; CUDA code paths require a CUDA-enabled R torch installation and
are being prepared for dedicated hardware CI.
