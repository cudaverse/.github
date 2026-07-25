# cudaverse compatibility

This table is the tested source-package contract for the current development
stack. GitHub installation resolves the latest compatible commit from each
repository; released CRAN compatibility will be documented separately once the
packages enter CRAN.

| Package | Current version | cudaverse dependencies |
|---|---:|---|
| `cudatensr` | 0.1.1 | — |
| `cudasparsr` | 0.1.1 | `cudatensr (>= 0.1.1)` |
| `cudalearnr` | 0.1.1 | `cudatensr (>= 0.1.1)` |
| `cudacellr` | 0.1.1 | `cudasparsr (>= 0.1.1)`, `cudalearnr (>= 0.1.1)` |
| `cudagraphR` | 0.1.1 | optional `cudalearnr (>= 0.1.1)` |
| `cudaembedr` | 0.1.1 | `cudalearnr (>= 0.1.1)`; optional `cudatensr (>= 0.1.1)` and `cudacellr (>= 0.1.1)` |

## Installation order

Users normally install only the top-level package they need with `pak`, which
resolves `Remotes`. For an explicit clean-library installation, use:

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
- `cudatensr` additionally checks R-devel on Linux.
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
