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
| `cudatensr` | `adb2423949792cd6becf15f1bfd7ce15324eda5c` |
| `cudasparsr` | `f8fd20d6c212ac6ce5f03a3f10a358b471db96fb` |
| `cudalearnr` | `adfa2c7367e7ff296a0c5df6e97cd67ded032603` |
| `cudacellr` | `f10c258e534a4245fd0547c28c1d48217bc6248e` |
| `cudagraphR` | `3bde230eb27befda8f0848aa3320dbc0d5e92f79` |
| `cudaembedr` | `7f5a554bcb7bafb45d3500a36f611de4e82ee167` |

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
