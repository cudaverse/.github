# cudaverse roadmap

This file is the current-state roadmap for the cudaverse organization. The
workspace-level `wishlist.md` contains only a portfolio summary; package
implementation details belong in the repository that owns them.

## Implemented baseline

- [x] `cudatensr`: dense tensors, device transfer, arithmetic, reductions,
      matrix multiplication, reshape, transpose, broadcasting, and CPU fallback
- [x] `cudasparsr`: sparse conversion, COO/CSR metadata, multiplication,
      reductions, and CPU fallback
- [x] `cudalearnr`: SVD, PCA, numerically stable distances, exact batched kNN,
      k-means, and feature-aligned post-fit PCA and k-means prediction
- [x] `cudacellr`: sparse normalization, HVG selection, PCA, neighbours, a
      composable feature-by-cell workflow, and native optional
      `SingleCellExperiment` and SeuratObject v5 result mapping
- [x] `cudagraphR`: sparse kNN graphs and CPU Louvain/Leiden clustering
- [x] `cudaembedr`: CPU UMAP/t-SNE adapters and diffusion-map-style embeddings
      with optional CUDA distance computation
- [x] Cross-platform R release and R-devel checks, pkgdown sites, explicit
      backend provenance, and a CPU-first end-to-end workflow
- [x] A shared `cudaverse-stage/1` provenance schema with structured CUDA
      diagnostics, strict device selection, source-provenance propagation, and
      one canonical cross-package `cuda_provenance()` S3 generic

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
- [x] Define a hard-failing, full-stack CPU/CUDA parity contract and reusable
      workflow for an NVIDIA self-hosted runner
- [x] Derive exact same-repository pull request SHAs inside the reusable
      contract and reject forks, bots, drafts, and non-collaborator authors
      before requesting its named runner group
- [x] Run all six package-owned `testthat` suites in the hardware contract and
      treat every skip as a failure
- [ ] Establish the external runner boundary before registering hardware:
      prove selected-workflow restriction for `cudaverse-nvidia`, or dispatch
      reviewed SHAs from a private orchestration repository; require isolated
      ephemeral runners for every pull-request execution
- [ ] Run all CUDA-capable public paths on dedicated NVIDIA CI hardware
- [ ] Enable the hardware contract on every default-branch push and
      same-repository pull request with the repository variable
      `CUDAVERSE_NVIDIA_CI=enabled` after an online
      `cudaverse-nvidia` runner is safely available
- [x] Add runnable long-form package articles for installation, backend
      semantics, memory limits, and the end-to-end workflow

The contract itself refuses to skip when CUDA is unavailable. No CUDA
performance or continuous hardware-coverage claim is complete until an NVIDIA
runner executes it successfully on every required change. A public-fork pull
request is deliberately skipped by these workflow paths; that skipped state is
not a pass and does not provide hardware evidence. Workflow guards do not
replace the external runner-group or private-orchestrator access boundary.

## R and Bioconductor integration

- [x] Add an optional `SingleCellExperiment` adapter with explicit assay
      selection, collision checks, and opt-in delayed-assay realization
- [x] Preserve row names, column names, `rowData`, `colData`, metadata, existing
      assays, and unrelated reduced dimensions across that adapter
- [x] Store normalized assays, PCA, feature statistics, and kNN relationships
      in native assay, `reducedDim`, `rowData`, and `colPair` locations
- [x] Accept those SCE reduced dimensions directly in all `cudaembedr`
      entry points without guessing non-PCA sources
- [x] Add native SeuratObject v5 integration with exact assay/layer selection,
      opt-in realization, pre-compute collision checks, targeted overwrite,
      and native `Assay5`, `DimReduc`, `Neighbor`, metadata, and tool outputs
- [x] Compose neighbours with graph clustering without losing cell identifiers

The current public inputs are base matrices/arrays, `Matrix` sparse matrices,
cudaverse result objects, optional `SingleCellExperiment` reduced
dimensions/workflows, and optional SeuratObject v5 objects. The Seurat adapter
requires `SeuratObject`, not the full Seurat package.

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
