# cudaverse compatibility

This table describes the dependency constraints in the current development
sources. An unqualified GitHub installation requests the latest default-branch
head from each repository; it does not reconstruct or solve for a historical
set of compatible commits. Pin an explicitly verified source tuple when exact
reproducibility matters. Released CRAN compatibility will be documented
separately once the packages enter CRAN.

| Package | Development version | cudaverse dependencies |
|---|---:|---|
| `cudatensr` | 0.2.0 | None |
| `cudasparsr` | 0.2.0 | `cudatensr (>= 0.2.0)` |
| `cudalearnr` | 0.2.0 | `cudatensr (>= 0.2.0)` |
| `cudacellr` | 0.3.0 | `cudatensr (>= 0.2.0)`, `cudasparsr (>= 0.2.0)`, `cudalearnr (>= 0.2.0)` |
| `cudagraphR` | 0.2.0 | `cudatensr (>= 0.2.0)`; optional `cudalearnr (>= 0.2.0)` |
| `cudaembedr` | 0.3.0 | `cudatensr (>= 0.2.0)`, `cudalearnr (>= 0.2.0)`; optional `cudacellr (>= 0.3.0)` |

These are source-package versions, not published release tags.

## Verified source tuple

This source tuple passed clean-library installation, all six package test
suites, the `cudacellr` package check, and the cross-package identifier
workflow. The integration gate also verifies that every package exports the
same canonical `cuda_provenance()` generic and that native
`SingleCellExperiment` dispatch survives package attachment order. Use the
full commit hashes when an exactly reproducible development stack is required.

| Package | Verified commit |
|---|---|
| `cudatensr` | `71366584ca99ec3fdd008945090cec60658f2311` |
| `cudasparsr` | `5e45a089f90d794d6b0f56ee2e4a5f9650bd8b16` |
| `cudalearnr` | `d94aecfb7c0b099ada02b754abcdb7c96f1c887b` |
| `cudacellr` | `12a5f6b400beef3812ee15cdaecc7ddd82dc6d72` |
| `cudagraphR` | `fef7b0fa69676d653dccf45394c741d89f9ea14f` |
| `cudaembedr` | `945ea3796175d4036a701f357a1dd68e9878ba28` |

**Verified on:** `2026-07-26`

## Installation order

Users normally install only the top-level package they need with `pak`, which
resolves its current `Remotes`. This is convenient development installation,
not a lockfile. To reproduce the verified tuple exactly, pin every source:

```r
pak::pak(c(
  "cudaverse/cudatensr@71366584ca99ec3fdd008945090cec60658f2311",
  "cudaverse/cudasparsr@5e45a089f90d794d6b0f56ee2e4a5f9650bd8b16",
  "cudaverse/cudalearnr@d94aecfb7c0b099ada02b754abcdb7c96f1c887b",
  "cudaverse/cudacellr@12a5f6b400beef3812ee15cdaecc7ddd82dc6d72",
  "cudaverse/cudagraphR@fef7b0fa69676d653dccf45394c741d89f9ea14f",
  "cudaverse/cudaembedr@945ea3796175d4036a701f357a1dd68e9878ba28"
))
```

Omit the `@<commit>` suffixes only when deliberately installing the latest
default-branch heads instead of the verified tuple.

Optional backends are not installed automatically:

- `torch` enables CUDA paths when it has a usable CUDA runtime;
- `igraph` enables Louvain and Leiden community detection;
- `uwot` enables UMAP;
- `Rtsne` enables t-SNE;
- `RSpectra` accelerates supported CPU eigendecompositions.
- `SingleCellExperiment` enables native Bioconductor object workflows in
  `cudacellr` and direct reduced-dimension inputs in `cudaembedr`.
- `SeuratObject >= 5.0.0` enables native Seurat v5 workflows in `cudacellr`;
  the full Seurat package is not required.

## Platform evidence

- CPU paths are checked on current R release for Windows, macOS, and Linux.
- All six packages additionally check R-devel on Linux.
- A hard-failing full-stack CPU/CUDA parity workflow is defined for a labelled
  self-hosted NVIDIA runner. It also runs all six package-owned `testthat`
  suites and fails if any test is skipped.
- Package pull requests from non-draft same-repository branches authored by a
  human owner, member, or collaborator are derived from the event and tested at
  their exact head SHA. Central contract pull requests use a trusted
  default-branch caller and the same event-derived rule.
- Public forks, bots, and non-collaborator pull requests are intentionally
  skipped by these workflow paths. That skip is a trust-boundary result, not a
  CUDA pass or hardware evidence. Before hardware is registered, the named
  runner group must prove selected-workflow restriction or the contract must
  move to a private orchestration repository; pull-request execution also
  requires an isolated ephemeral runner as described in `GPU_SETUP.md`.
- The public GitHub-hosted CI does not currently provide an NVIDIA runner.
  CUDA performance and hardware coverage are therefore not claimed as
  continuously verified yet.

No older-R compatibility window is promised until an explicit oldrel CI matrix
is added. Use the current R release for the supported development path.

See the
[GPU setup and troubleshooting guide](GPU_SETUP.md)
for runtime installation and device semantics.
