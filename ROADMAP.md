# cudaverse roadmap

This file is the current-state roadmap for the cudaverse organization. The
workspace-level `wishlist.md` contains only a portfolio summary; package
implementation details belong in the repository that owns them.

## Implemented baseline

- [x] `cudatensr`: dense tensors, device transfer, arithmetic, reductions,
      matrix multiplication, reshape, transpose, broadcasting, and CPU fallback
- [x] `cudasparsr`: sparse conversion, COO/CSR metadata, multiplication,
      reductions, and CPU fallback
- [x] `cudalearnr`: SVD, PCA, distances, exact batched kNN, and k-means
- [x] `cudacellr`: sparse normalization, HVG selection, PCA, neighbours, and a
      composable feature-by-cell workflow
- [x] `cudagraphR`: sparse kNN graphs and CPU Louvain/Leiden clustering
- [x] `cudaembedr`: CPU UMAP/t-SNE adapters and diffusion-map-style embeddings
      with optional CUDA distance computation
- [x] Cross-platform R release and R-devel checks, pkgdown sites, explicit
      backend provenance, and a CPU-first end-to-end workflow

The source dependency graph is:

```text
cudatensr -> cudasparsr -> cudacellr
           \-> cudalearnr -> cudacellr
                          -> cudaembedr
                          -. optional kNN integration .-> cudagraphR
cudacellr -. optional workflow adapter .-> cudaembedr
```

## Current quality gates

- [x] Record and continuously validate an exact cross-repository source tuple
      in `COMPATIBILITY.md`
- [ ] Run all CUDA-capable public paths on dedicated NVIDIA CI hardware
- [ ] Require CPU/CUDA parity assertions and actual-device provenance in the
      NVIDIA job; a CUDA-unavailable skip must not count as coverage
- [ ] Add runnable long-form package articles for installation, backend
      semantics, memory limits, and the end-to-end workflow

No CUDA performance or continuous hardware-coverage claim is complete until
the NVIDIA gate passes.

## R and Bioconductor integration

- [ ] Add an optional `SingleCellExperiment` adapter with assay selection
- [ ] Preserve row names, column names, `rowData`, `colData`, metadata, existing
      assays, and unrelated reduced dimensions across that adapter
- [ ] Add Seurat integration after the Bioconductor object contract is stable
- [x] Compose neighbours with graph clustering without losing cell identifiers

The current public inputs are base matrices/arrays, `Matrix` sparse matrices,
and cudaverse result objects. `SingleCellExperiment` and Seurat are target
integrations, not implemented capabilities.

## Backend depth

- [ ] Add a native sparse CSR/cuSPARSE path when the supported R backend exposes
      a stable contract
- [ ] Keep exact kNN selection and k-means centroid updates device-resident
      where practical
- [ ] Benchmark representative dense, sparse, and single-cell workloads on
      named hardware without generalizing beyond the measured configurations

## Release sequence

Publish from the dependency foundation upward:

1. `cudatensr`
2. `cudasparsr` and `cudalearnr`
3. `cudacellr`
4. `cudaembedr` and `cudagraphR`

Before each CRAN submission, remove development-only `Remotes` entries only
after every required cudaverse dependency is available from CRAN. Optional
backends remain in `Suggests` and must fail with actionable installation
messages when explicitly requested but unavailable.

## Later ecosystem work

Multi-omics, spatial-omics, and visualization packages remain exploratory until
the core packages have hardware evidence, stable object contracts, and a
published dependency chain.
