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

1. `cudaverse` 0.4.1: keep the CRAN candidate frozen except for reviewer fixes.
2. `cudacellr` 0.4.0: revalidate against the accepted core, then wait for its
   portfolio review slot. It does not bypass other prepared portfolio packages.

Remove `cudacellr`'s development-only `Remotes` entry only after `cudaverse` is
available from CRAN. Successful CI is not CRAN acceptance.

## Next evidence milestone

Run the complete native parity, error recovery, interruption, and 1,000-cycle
memory contract on the remote GPU host. Retain exact source revisions and
machine-readable results; a skipped GPU job is not a pass. Publish benchmarks
that separate startup, transfers, and device computation and report numerical
accuracy alongside timing.

Graph construction, Louvain/Leiden, UMAP, and t-SNE currently use CPU adapters;
diffusion maps combine CUDA and CPU stages. Future GPU implementations and
broader sparse dtype support are separate development milestones, not claims
about the current release. Keep these within the existing package structure.
