# Set up CUDA for cudaverse

Use an NVIDIA GPU on Windows or Linux to accelerate matrix operations, PCA,
exact nearest neighbours, and k-means. The native backend is included in
`cudaverse`; it uses your installed NVIDIA libraries without requiring torch
or downloading LibTorch.

## Prepare your machine

- **Windows:** NVIDIA driver, cuBLAS 12 (`cublas64_12.dll`), and cuSOLVER 11
  (`cusolver64_11.dll`) from a compatible CUDA 12.x distribution.
- **Linux:** NVIDIA driver and compatible CUDA 12.x libraries providing
  `libcuda.so`, `libcublas.so.12`, and `libcusolver.so.11`.
- **macOS:** the R package installs, but run CUDA work on a Windows or Linux
  GPU machine.

Run `nvidia-smi` to verify GPU detection. Its displayed CUDA version describes
driver compatibility; it does not prove cuBLAS and cuSOLVER are installed.
Follow the maintained [platform setup guide](https://cudaverse.github.io/cudaverse/articles/gpu-setup.html)
for NVIDIA installation links and library-path troubleshooting.

## Install and verify

```r
install.packages("cudaverse")
library(cudaverse)

health <- cuda_diagnostics()
health$summary
health$next_steps
cuda_select_device("cuda")

x <- cuda_tensor(matrix(c(1, 2, 3, 4), 2), device = "cuda")
to_cpu(tensor_matmul(x, x))
```

Explicit CUDA requests fail with diagnostics if CUDA cannot be used. For
libraries in nonstandard locations, set `CUDAVERSE_CUBLAS_PATH` and
`CUDAVERSE_CUSOLVER_PATH` to their absolute paths before loading the package,
then restart R and repeat the check.

## Run an analysis

```r
set.seed(1)
data <- matrix(rnorm(1000 * 50), 1000, 50)
pca <- cuda_pca(data, n_components = 10, device = "cuda")
neighbors <- cuda_knn(pca$x, k = 15, device = "cuda")
head(neighbors$index)
cuda_provenance(neighbors)
```

Supported native stages reuse device storage. Graph assembly, community
detection, and some embedding algorithms use host computation; consult the
[reference](https://cudaverse.github.io/cudaverse/reference/index.html) and
provenance for your workflow.

Single-cell users add `cudacellr`. Sparse normalization and feature selection
currently use `Matrix`, while PCA and nearest neighbours can use CUDA.
Optional adapters support `SingleCellExperiment` and `SeuratObject`.

## Report a problem

Include a small reproducible input, `sessionInfo()`, `cuda_diagnostics()`,
the requested device, and provenance of any completed result. A comparison
with `device = "cpu"` can help locate numerical differences.

GPU CI configuration belongs to maintainer infrastructure. A skipped hardware
job is not a successful GPU test; evidence must identify the tested source
commit and actual device.
