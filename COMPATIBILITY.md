# cudaverse compatibility

This table describes the dependency constraints in the current development
sources. An unqualified GitHub installation requests the latest default-branch
head from each repository; it does not reconstruct or solve for a historical
set of compatible commits. Pin an explicitly verified source tuple when exact
reproducibility matters. Released CRAN compatibility will be documented
separately once the packages enter CRAN.

| Package | Development version | cudaverse dependencies |
|---|---:|---|
| `cudatensr` | 0.2.0 | — |
| `cudasparsr` | 0.2.0 | `cudatensr (>= 0.2.0)` |
| `cudalearnr` | 0.2.0 | `cudatensr (>= 0.2.0)` |
| `cudacellr` | 0.3.0 | `cudatensr (>= 0.2.0)`, `cudasparsr (>= 0.2.0)`, `cudalearnr (>= 0.2.0)` |
| `cudagraphR` | 0.2.0 | `cudatensr (>= 0.2.0)`; optional `cudalearnr (>= 0.2.0)` |
| `cudaembedr` | 0.3.0 | `cudatensr (>= 0.2.0)`, `cudalearnr (>= 0.2.0)`; optional `cudacellr (>= 0.3.0)` |

These are source-package versions, not published release tags.

## Verified source tuple

This source tuple passed clean-library installation, all six package checks,
and the cross-package identifier workflow. Use the full commit hashes when an
exactly reproducible development stack is required.

| Package | Verified commit |
|---|---|
| `cudatensr` | `1a9352aa8bdf7e0b72e32cc064de8004dccca3b6` |
| `cudasparsr` | `fd27094aac7526383c7aabc56433dcfa88e2bdf1` |
| `cudalearnr` | `069db8adb8fde4bc2931f9e7936e8d656221cb6e` |
| `cudacellr` | `1dd95a1ebd3ff2b538307c13ad866cf92630f86c` |
| `cudagraphR` | `89710452fe8beb505f7ae5e0a1e21479e237d8d7` |
| `cudaembedr` | `3cc7fd555ed5a2093bb200aae120ba667af94668` |

**Verified on:** `2026-07-26`

## Installation order

Users normally install only the top-level package they need with `pak`, which
resolves its current `Remotes`. This is convenient development installation,
not a lockfile. For an explicit clean-library installation of current branch
heads, use:

```r
pak::pak(c(
  "cudaverse/cudatensr",
  "cudaverse/cudasparsr",
  "cudaverse/cudalearnr",
  "cudaverse/cudacellr",
  "cudaverse/cudagraphR",
  "cudaverse/cudaembedr"
))
```

Optional backends are not installed automatically:

- `torch` enables CUDA paths when it has a usable CUDA runtime;
- `igraph` enables Louvain and Leiden community detection;
- `uwot` enables UMAP;
- `Rtsne` enables t-SNE;
- `RSpectra` accelerates supported CPU eigendecompositions.
- `SingleCellExperiment` enables native Bioconductor object workflows in
  `cudacellr` and direct reduced-dimension inputs in `cudaembedr`.

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
