# cudaverse roadmap

## Package structure

- [x] Provide dense tensors, sparse matrices, numerical algorithms, graph
      workflows, and embeddings in the user-facing `cudaverse` package.
- [x] Keep `cudacellr` as the only domain extension.
- [x] Include the native CUDA backend in `cudaverse` without another package.
- [x] Keep one canonical `cuda_provenance()` protocol and an acyclic dependency
      graph: `cudaverse -> cudacellr`.

## Implemented baseline

- [x] Dense tensor construction, transfer, arithmetic, matrix multiplication,
      reductions, reshape, transpose, and broadcasting.
- [x] COO/CSR sparse metadata, Matrix conversion, sparse multiplication, and
      row/column reductions.
- [x] SVD, PCA, distances, exact batched kNN, k-means, and aligned prediction.
- [x] Weighted kNN graphs plus Louvain and Leiden community detection.
- [x] UMAP, t-SNE, and diffusion-map-style embeddings.
- [x] Single-cell normalization, HVG selection, PCA, neighbours, and native
      SingleCellExperiment and SeuratObject v5 mapping.
- [x] Portable CPU fallbacks and explicit backend/device provenance.

## Quality gates

- [x] Cross-platform R CMD check and pkgdown workflows for both active packages.
- [x] CPU integration contract for identifiers and provenance.
- [x] Trusted NVIDIA runner contract for package tests and CPU/CUDA parity.
- [x] `cudaverse-benchmark/1` benchmark evidence schema and validator.
- [ ] Execute the complete hardware contract on a safely isolated NVIDIA runner.
- [ ] Publish representative dense, sparse, graph, embedding, and single-cell
      evidence without generalizing beyond measured hardware.

## Backend depth

- [x] Native sparse storage, multiplication, reductions, and sparse PCA.
- [x] Device-side exact kNN selection and k-means centroid updates.
- [ ] Let embedding adapters accept canonical precomputed neighbour or graph
      objects where their backend supports it.

## Release sequence

Submit only one package at a time and wait for acceptance plus completed checks:

1. `cudaverse` 0.4.1: [published on CRAN](https://cran.r-project.org/package=cudaverse)
   on 2026-09-10; listed CRAN platform checks were OK at the 2026-09-26
   checkpoint. The existing GitHub tag and its attachment predate the accepted
   resubmission; the [release notes](https://github.com/cudaverse/cudaverse/releases/tag/v0.4.1)
   identify that distinction without moving the published tag.
2. `cudacellr` 0.4.0: the accepted-core dependency update in
   [PR #3](https://github.com/cudaverse/cudacellr/pull/3) is merged, and all four
   main-branch R checks passed. Complete release preparation and wait for its
   portfolio review slot. It does not bypass other prepared portfolio packages.

`cudacellr` now requires `cudaverse >= 0.4.1` and has no development-only
`Remotes` entry. Successful CI is not CRAN acceptance of the extension.

## Next evidence milestone

The [2026-09-07 correctness checkpoint](evidence/2026-09-07/README.md) retains
native parity, error recovery, interruption and 1,000-cycle memory evidence for
its recorded revisions. Later testing identified a duplicate-observation PCA
edge case, whose correction is in [PR #55](https://github.com/cudaverse/cudaverse/pull/55).
That development candidate remains held while the strict float32 matrix-product
accuracy gate and retained benchmarks are unresolved.

Complete those gates on the chosen candidate, retain exact revisions and
machine-readable results, and publish benchmarks that separate startup,
transfers and device computation. Report numerical accuracy alongside timing;
a skipped GPU job or shared-device diagnostic does not establish performance.

Graph construction, Louvain/Leiden, UMAP, and t-SNE currently use CPU adapters;
diffusion maps combine CUDA and CPU stages. Future GPU implementations and
broader sparse dtype support are separate development milestones, not claims
about the current release. Keep these within the existing package structure.
