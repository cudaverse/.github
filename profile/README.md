# cudaverse

GPU-aware numerical computing for R with one general-purpose package and one
domain extension.

| Package | Purpose |
|---|---|
| [`cudaverse`](https://github.com/cudaverse/cudaverse) | Dense tensors, sparse matrices, SVD, PCA, distances, nearest neighbours, k-means, graphs, community detection, UMAP, t-SNE, and diffusion maps |
| [`cudacellr`](https://github.com/cudaverse/cudacellr) | Single-cell normalization, variable-feature selection, and native SingleCellExperiment and SeuratObject v5 workflows |

CUDA is optional. Both packages provide portable CPU behavior and record the
backend and device used by each compute stage.

```r
pak::pak("cudaverse/cudaverse")
library(cudaverse)

x <- matrix(rnorm(400), nrow = 40)
pca <- cuda_pca(x, n_components = 5)
neighbors <- cuda_knn(pca$x, k = 5)
graph <- cuda_knn_graph(neighbors)
embedding <- cuda_umap(pca$x)
```

Single-cell users add only the extension:

```r
pak::pak("cudaverse/cudacellr")
library(cudacellr)
result <- cudacell_workflow(counts)
```

The former component repositories are archived as development history. New
general-purpose work belongs in `cudaverse`; single-cell-specific work belongs
in `cudacellr`.
