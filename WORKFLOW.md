# End-to-end workflow

Install the general package once:

```r
pak::pak("cudaverse/cudaverse")
library(cudaverse)
```

General-purpose functions compose without loading additional cudaverse
packages:

```r
set.seed(42)
x <- matrix(rnorm(600), nrow = 60)

pca <- cuda_pca(x, n_components = 8, device = "auto")
neighbors <- cuda_knn(pca$x, k = 10, device = "auto")
graph <- cuda_knn_graph(neighbors, weighting = "gaussian")
embedding <- cuda_diffusion_map(pca, n_components = 2, device = "auto")

cuda_provenance(pca)
embedding_coordinates(embedding)
```

Sparse matrices use the same package and provenance contract:

```r
sparse <- cuda_sparse(Matrix::Matrix(x, sparse = TRUE), device = "auto")
product <- sparse_matmul_dense(sparse, matrix(1, ncol(x), 2))
cuda_provenance(product)
```

Single-cell users install the extension:

```r
pak::pak("cudaverse/cudacellr")
library(cudacellr)

fit <- cudacell_workflow(
  counts,
  n_hvg = 2000,
  n_components = 30,
  k = 20,
  device = "auto"
)

embedding <- cudaverse::cuda_diffusion_map(
  fit,
  n_components = 2,
  device = "auto"
)
```

`cudacell_sce()` and `cudacell_seurat()` map results into native domain
objects. They preserve the same `cudaverse-stage/1` provenance contract.
