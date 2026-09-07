# End-to-end workflow

Prepare an NVIDIA GPU on Windows or Linux using the [CUDA setup guide](GPU_SETUP.md),
then install the general package once:

```r
pak::pak("cudaverse/cudaverse")
library(cudaverse)
cuda_select_device("cuda")
```

General-purpose functions compose without loading additional cudaverse
packages:

```r
set.seed(42)
x <- matrix(rnorm(600), nrow = 60)

pca <- cuda_pca(x, n_components = 8, device = "cuda")
neighbors <- cuda_knn(pca$x, k = 10, device = "cuda")
graph <- cuda_knn_graph(neighbors, weighting = "gaussian")
embedding <- cuda_diffusion_map(pca, n_components = 2, device = "cuda")

cuda_provenance(pca)
embedding_coordinates(embedding)
```

PCA returns an R model and retains a device-side score cache for subsequent
CUDA work. Graph construction runs on CPU; diffusion maps combine CUDA
distance computation with CPU kernel construction and eigendecomposition.

Sparse matrices use the same package and provenance contract:

```r
sparse <- cuda_sparse(Matrix::Matrix(x, sparse = TRUE), device = "cuda")
product <- sparse_matmul_dense(sparse, matrix(1, ncol(x), 2))
cuda_provenance(product)
```

Single-cell users install the extension:

```r
pak::pak("cudaverse/cudacellr")
library(cudacellr)

set.seed(42)
counts <- matrix(rpois(500 * 100, lambda = 3), 500, 100,
                 dimnames = list(paste0("gene", 1:500), paste0("cell", 1:100)))
fit <- cudacell_workflow(
  counts,
  n_hvg = 200,
  n_components = 30,
  k = 20,
  device = "cuda"
)

embedding <- cudaverse::cuda_diffusion_map(
  fit,
  n_components = 2,
  device = "cuda"
)
```

Single-cell normalization and feature selection use CPU `Matrix` operations;
PCA and exact neighbours can run on native CUDA. Inspect `cuda_provenance(fit)`
for the stage boundaries.

`cudacell_sce()` and `cudacell_seurat()` map results into native domain
objects. They preserve the same `cudaverse-stage/1` provenance contract.
