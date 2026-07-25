# cudaverse compatibility

This table describes the dependency constraints in the current development
sources. An unqualified GitHub installation requests the latest default-branch
head from each repository; it does not reconstruct or solve for a historical
set of compatible commits. Pin an explicitly verified source tuple when exact
reproducibility matters. Released CRAN compatibility will be documented
separately once the packages enter CRAN.

| Package | Development version | cudaverse dependencies |
|---|---:|---|
| `cudatensr` | 0.1.2 | — |
| `cudasparsr` | 0.1.2 | `cudatensr (>= 0.1.2)` |
| `cudalearnr` | 0.1.2 | `cudatensr (>= 0.1.2)` |
| `cudacellr` | 0.1.2 | `cudasparsr (>= 0.1.2)`, `cudalearnr (>= 0.1.2)` |
| `cudagraphR` | 0.1.2 | optional `cudalearnr (>= 0.1.2)` |
| `cudaembedr` | 0.1.2 | `cudalearnr (>= 0.1.2)`; optional `cudatensr (>= 0.1.2)` and `cudacellr (>= 0.1.2)` |

These are source-package versions, not published release tags.

## Verified source tuple

This source tuple passed clean-library installation, all six package checks,
and the cross-package identifier workflow. Use the full commit hashes when an
exactly reproducible development stack is required.

| Package | Verified commit |
|---|---|
| `cudatensr` | `c774d7c277fa8e88084560708bce96bd4cd7eb21` |
| `cudasparsr` | `b204a7993b6a45c62a30df1868a9bd7429ee0389` |
| `cudalearnr` | `3b1ad4efac75885a1f8f343cd4cfc41814c52e3d` |
| `cudacellr` | `5ca486ccd36c02e66f89e3e1e1e431445d315a3c` |
| `cudagraphR` | `ae7ea60c0a44d608928e671bf854f451ce9aaa5f` |
| `cudaembedr` | `d444c50c4662d3b0188ce39f5e183d62145968e8` |

**Verified on:** `2026-07-25`

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

## Platform evidence

- CPU paths are checked on current R release for Windows, macOS, and Linux.
- All six packages additionally check R-devel on Linux.
- CUDA code is guarded by CPU-reference parity tests that run when a CUDA
  backend is present.
- The public GitHub-hosted CI does not currently provide an NVIDIA runner.
  CUDA performance and hardware coverage are therefore not claimed as
  continuously verified yet.

No older-R compatibility window is promised until an explicit oldrel CI matrix
is added. Use the current R release for the supported development path.

See the
[GPU setup and troubleshooting guide](GPU_SETUP.md)
for runtime installation and device semantics.
