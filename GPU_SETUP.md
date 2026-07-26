# GPU setup and troubleshooting

Every cudaverse package has a portable CPU path. Start there first, then enable
CUDA without changing your analysis code.

## 1. Verify the CPU workflow

Install the package you need and force the portable backend:

```r
# install.packages("pak")
pak::pak("cudaverse/cudalearnr")

library(cudalearnr)

x <- scale(iris[, 1:4])
fit <- cuda_pca(x, n_components = 2, device = "cpu")
fit$device
#> [1] "cpu"
```

If this fails, the problem is in the R package or input rather than the GPU
runtime. Include this CPU result when reporting a CUDA difference.

## 2. Install R torch

The optional CUDA backend is provided by the R
[`torch`](https://torch.mlverse.org/docs/) package:

```r
install.packages("torch")
```

On first use, torch may need to download LibTorch and LibLantern. In a
non-interactive environment, set `TORCH_INSTALL=1` during installation or run:

```r
torch::install_torch()
```

GPU builds, supported CUDA versions, and platform requirements change over
time. Follow the current official
[torch installation guide](https://torch.mlverse.org/docs/articles/installation)
rather than copying an old CUDA version from a blog post. Pre-built GPU
binaries are usually the simplest Windows and Linux route. Restart R after
installing or replacing the torch runtime.

## 3. Prove CUDA is visible

Run these checks in a fresh R session:

```r
packageVersion("torch")
torch::cuda_is_available()
torch::cuda_device_count()
cudatensr::cuda_available()
cudatensr::cuda_diagnostics()
```

Both availability checks must return `TRUE` before `device = "cuda"` can work.
For more installation detail, run:

```r
torch::install_torch_sitrep()
```

Then require CUDA explicitly in a small smoke test:

```r
library(cudatensr)

x <- cuda_tensor(matrix(1:6, 2, 3), device = "cuda")
tensor_device(x)
#> device  backend
#> "cuda"  "torch"

to_cpu(tensor_sum(x))
```

Do not use a large biological dataset as the first GPU test.

## Device semantics

| Request | Behaviour |
|---|---|
| `device = "cpu"` | Always use the portable CPU backend |
| `device = "auto"` | Use CUDA only when `cudatensr::cuda_available()` is true; otherwise use CPU |
| `device = "cuda"` | Require CUDA and fail clearly when it is unavailable |

`"auto"` is a convenience, not a GPU guarantee. Inspect the returned object:

- `tensor_device(x)` for `cudatensor`;
- `$device` for PCA, kNN, k-means, and related results;
- `source_device`, `compute_device`, and `compute_stages` for embeddings;
- `source_device` and `backend` for graph results.

Some workflows are intentionally hybrid. For example, diffusion-map distances
may run on CUDA while kernel construction and eigendecomposition run on CPU.
Such a result reports `"hybrid"` rather than claiming end-to-end GPU execution.

Every 0.2.0 result supports the same detailed inspector:

```r
selection <- cudatensr::cuda_select_device("auto")
selection

fit <- cudalearnr::cuda_knn(
  scale(iris[, 1:4]),
  k = 5,
  device = "auto"
)
cudalearnr::cuda_provenance(fit)
```

The stage table separates:

- `requested_device`: what the caller requested, including `"auto"`;
- `device`: where the stage actually computed;
- `backend`: the concrete implementation;
- `selection_reason` and `fallback`: why automatic selection chose CPU;
- `output_device`: where the stage result resides.

`device = "cuda"` signals a `cudaverse_cuda_unavailable` condition when the
runtime is unusable. It never returns a CPU result. `device = "auto"` may use
CPU, but the reason remains visible in provenance.

## Memory and data transfer

- Exact `cuda_knn()` is quadratic in time, but `batch_size` bounds its resident
  distance block. Lower `batch_size` if CPU or GPU memory is tight.
- `cuda_distance()` intentionally returns a complete dense pairwise matrix.
  Do not call it when only nearest neighbours are needed.
- `to_cpu()` explicitly materializes a tensor as a base R array.
- Tensor subsetting currently makes a CPU round trip. Core arithmetic,
  reductions, reshape, and transpose remain device-native.
- Remove unused GPU objects, run `gc()`, and, when appropriate, call
  `torch::cuda_empty_cache()` before retrying an out-of-memory operation.

## Common failures

### `CUDA is unavailable`

Restart R, rerun the availability checks, and inspect
`torch::install_torch_sitrep()`. Until the runtime is fixed, use
`device = "cpu"` rather than changing analysis logic.

### Runtime download times out

Torch runtime archives can be large. Increase the R download timeout before
installation:

```r
options(timeout = 600)
```

The official installation guide also documents pre-built repositories and
offline installation.

### CPU and CUDA results differ slightly

Floating-point execution order differs across backends. Compare with a
documented tolerance. Neighbour ties are resolved by input row number so batch
size does not change exact kNN output.

### A result says `cpu` or `hybrid`

This is provenance, not a hidden fallback bug. Check the package's backend
section to see which stages have CUDA implementations. Passing
`device = "cuda"` only controls stages that expose that parameter.

## Reporting a problem

Include:

```r
sessionInfo()
torch::install_torch_sitrep()
torch::cuda_is_available()
cudatensr::cuda_available()
```

Also provide a small reproducible input, the requested device, the actual
device/backend fields, and whether the same call succeeds with
`device = "cpu"`.

## Organization hardware gate

The organization owns a full-stack parity script at
`scripts/check-cuda-parity.R` and a reusable `cuda-parity` workflow. It covers
all public CUDA-capable paths in the six core packages and fails immediately
when torch cannot see a physical NVIDIA device.

A self-hosted runner must provide:

- labels `self-hosted`, `linux`, `x64`, and `cuda`;
- R and a CUDA-enabled R torch runtime;
- a working `nvidia-smi`;
- network access needed to install ordinary R dependencies.

Each package exposes a manual `cuda-parity` workflow. After the runner is
online and the manual contract passes, set the repository Actions variable
`CUDAVERSE_NVIDIA_CI=enabled` to require the same job on pushes and pull
requests. A skipped job while that variable is absent is infrastructure
readiness, not CUDA coverage.
