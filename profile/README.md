# cudaverse

Lightweight CUDA computing for R: accelerate matrix operations, PCA, exact
nearest neighbours, and k-means on an NVIDIA GPU without installing a
deep-learning framework. The native backend uses your system's NVIDIA
libraries and does not bundle a CUDA runtime or LibTorch.

| Package | Use it for |
| --- | --- |
| [cudaverse](https://github.com/cudaverse/cudaverse) | Dense and sparse numerical computing, PCA, nearest neighbours, clustering, and graph/embedding workflows |
| [cudacellr](https://github.com/cudaverse/cudacellr) | Single-cell normalization, variable features, PCA/neighbours, and optional SingleCellExperiment or SeuratObject workflows |

## Start with a GPU workflow

Prepare a Windows or Linux machine with an NVIDIA driver, cuBLAS 12, and
cuSOLVER 11 using the [CUDA setup guide](https://github.com/cudaverse/.github/blob/main/GPU_SETUP.md).
Current CUDA execution is unavailable on macOS.

```r
install.packages("cudaverse")
library(cudaverse)

cuda_select_device("cuda")
set.seed(1)
x <- matrix(rnorm(1000 * 50), nrow = 1000)
pca <- cuda_pca(x, n_components = 10, device = "cuda")
neighbors <- cuda_knn(pca$x, k = 15, device = "cuda")
head(neighbors$index)
```

Use [tutorials](https://cudaverse.github.io/cudaverse/articles/index.html) for
worked examples and `cuda_provenance()` to inspect which stages used CUDA.
Graph assembly, community detection, and some embedding adapters use host
computation; speedups depend on the operation and workload.

The core package is [available from CRAN](https://cran.r-project.org/package=cudaverse).
Single-cell users can install `pak` if needed, add
`pak::pak("cudaverse/cudacellr")`, and begin with
the [single-cell workflow guide](https://cudaverse.github.io/cudacellr/).
