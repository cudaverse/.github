# cudaverse

GPU-aware scientific computing for R.

`cudaverse` is an R-native stack for dense tensors, sparse matrices, reusable
numerical algorithms, and single-cell workflows. The same public APIs have
portable CPU implementations and optional CUDA execution, and every result
reports the backend that actually ran.

## Package map

| Layer | Package | What it provides |
|---|---|---|
| Dense foundation | [cudatensr](https://github.com/cudaverse/cudatensr) | Tensors, device transfer, arithmetic, matrix multiplication, reductions, and broadcasting |
| Sparse foundation | [cudasparsr](https://github.com/cudaverse/cudasparsr) | COO/CSR metadata, `Matrix` conversion, sparse multiplication, and reductions |
| Algorithms | [cudalearnr](https://github.com/cudaverse/cudalearnr) | SVD, PCA, distances, k-nearest neighbours, and k-means |
| Single-cell workflow | [cudacellr](https://github.com/cudaverse/cudacellr) | Sparse normalization, variable-feature selection, PCA, neighbours, and native `SingleCellExperiment` mapping |
| Graph analysis | [cudagraphR](https://github.com/cudaverse/cudagraphR) | Weighted kNN graphs plus Louvain and Leiden community detection |
| Embeddings | [cudaembedr](https://github.com/cudaverse/cudaembedr) | UMAP, t-SNE, and diffusion-map-style embeddings with compute provenance |

The packages are composable: for example, `cudacellr` builds on
`cudasparsr` and `cudalearnr`, while `cudagraphR` consumes the stable
`cuda_knn` result returned by `cudalearnr`.

See the current
[cross-package compatibility matrix](https://github.com/cudaverse/.github/blob/main/COMPATIBILITY.md)
before pinning package versions in a reproducible environment.

## Start here

Install the algorithm layer and run the same workflow on the best available
device:

```r
# install.packages("pak")
pak::pak("cudaverse/cudalearnr")

library(cudalearnr)

x <- scale(iris[, 1:4])
pca <- cuda_pca(x, n_components = 2, device = "auto")
neighbors <- cuda_knn(pca$x, k = 10, device = "auto")

pca
neighbors
cudalearnr::cuda_provenance(pca)
cudalearnr::cuda_provenance(neighbors)
```

Use `device = "cpu"` for a guaranteed portable path or `device = "cuda"` to
require a working CUDA-enabled R `torch` installation. `"auto"` never claims
CUDA unless the backend is available. `cuda_diagnostics()` explains runtime
availability, while the shared `cuda_provenance()` table distinguishes the
requested device, actual device, backend, fallback reason, and output device
for every computation stage.

For a complete analysis crossing the single-cell, neighbour, graph, and
embedding layers, follow the
[end-to-end workflow](https://github.com/cudaverse/.github/blob/main/WORKFLOW.md).

## Design principles

- R-native APIs with one-based indices at the public boundary.
- Explicit device, backend, and multi-stage compute provenance.
- Correct CPU fallbacks for development, testing, and non-GPU machines.
- Optional CUDA acceleration without a Python runtime.
- Compatibility with base matrices and the R `Matrix` ecosystem.
- No GPU performance or correctness claim without hardware-backed evidence.

## Current maturity

The APIs are under active development and are not yet CRAN releases. CPU paths
run in cross-platform `R CMD check`; CUDA paths require a CUDA-enabled R
`torch` installation. Exact neighbour search now uses bounded distance blocks.
Current priorities are dedicated NVIDIA CI, exercising the new
`SingleCellExperiment` contract on real data, CRAN submission readiness, and
broader validation. Progress and acceptance
gates are tracked in the
[current roadmap](https://github.com/cudaverse/.github/blob/main/ROADMAP.md).
The hard-failing NVIDIA parity workflow is implemented, but continuous
hardware coverage is not claimed until a labeled runner is online and the gate
has passed.

## Contributing

API feedback and reproducible CPU/CUDA differences are especially useful.
Please read the organization
[contribution guide](https://github.com/cudaverse/.github/blob/main/CONTRIBUTING.md)
before opening a pull request.
