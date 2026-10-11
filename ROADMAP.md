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
- [ ] Complete the planned hardware workloads with recorded GPU sharing and
      validated results.
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
   main-branch R checks passed. The October 7 upload is awaiting email
   confirmation; no CRAN acceptance is established. Further submission actions
   require the maintainer's authorization and the portfolio review slot.

`cudacellr` now requires `cudaverse >= 0.4.1` and has no development-only
`Remotes` entry. Successful CI is not CRAN acceptance of the extension.

## Current evidence milestone (2026-10-10)

The [2026-09-07 correctness checkpoint](evidence/2026-09-07/README.md) retains
native parity, error recovery, interruption and 1,000-cycle memory evidence for
its recorded revisions. Later testing identified a duplicate-observation PCA
edge case, whose correction is in [PR #55](https://github.com/cudaverse/cudaverse/pull/55).
That draft PR contains development version 0.4.1.9000 at `2c2b569`; published
CRAN 0.4.1 and the supported main branches remain unchanged.

The maintainer approved the precision policy on September 26: standard FP32
by default, explicit per-call TF32, and FP64 when greater accuracy is needed.
The development benchmark uses a stated componentwise FP32 model and retains
the original strict comparison and failed-entry counts. The policy decision
is resolved; it does not establish application-level accuracy or speedups.

The maintainer has authorized the full workload sequence on the shared A100.
It retains the planned sizes, five warmups, ten samples, numerical checks,
source/install fingerprints, owned-allocation checks and GPU inventories.
At `2c2b569`, full precision, the independent installed package suite and
candidate readiness passed, but the full core run failed on six native kNN
distances in the 50,000-row sparse fixture. Stacked
[PR #57](https://github.com/cudaverse/cudaverse/pull/57) corrects cancellation
at `5754739`. Its analytic regression and full-size fixture diagnostic pass
unchanged tolerances; new exact-source full validation is running. Shared timings
are descriptive observations and cannot establish
uncontended performance. See the [current evidence summary](evidence/2026-10-10/README.md)
for completed diagnostics and the preserved whole-device memory assertion
failure. Review those full results before integrating PR #55.

Graph construction, Louvain/Leiden, UMAP, and t-SNE currently use CPU adapters;
diffusion maps combine CUDA and CPU stages. Future GPU implementations and
broader sparse dtype support are separate development milestones, not claims
about the current release. Keep these within the existing package structure.
