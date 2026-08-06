# cudaverse roadmap

## Package structure

- [x] Consolidate dense tensors, sparse matrices, numerical algorithms, graph
      workflows, and embeddings into the user-facing `cudaverse` package.
- [x] Keep `cudacellr` as the only domain extension.
- [x] Preserve existing public function names while removing the need to load
      five separate general-purpose packages.
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

- [ ] Add a native sparse CSR/cuSPARSE path when the supported R backend exposes
      a stable contract.
- [ ] Keep exact kNN selection and k-means centroid updates device-resident where
      practical.
- [ ] Let embedding adapters accept canonical precomputed neighbour or graph
      objects where their backend supports it.

## Release sequence

Submit only one package at a time and wait for acceptance plus completed checks:

1. `cudaverse` 0.1.0
2. `cudacellr` 0.4.0

Remove `cudacellr`'s development-only `Remotes` entry only after `cudaverse` is
available from CRAN. The former component packages will not be submitted.
