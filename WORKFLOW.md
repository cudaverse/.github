# End-to-end cudaverse workflow

This example connects the public contracts across the stack:

```text
feature-by-cell counts
        |
        v
normalization + variable features
        |
        v
cell-by-component PCA
        |
        +--> exact batched kNN --> sparse graph --> communities
        |
        +--> embedding
```

The orientation change is intentional. `cudacellr` accepts features in rows and
cells in columns. PCA scores, neighbour search, graph vertices, and embedding
coordinates then use observations (cells) in rows.

## Install

```r
# install.packages("pak")
pak::pak(c(
  "cudaverse/cudacellr",
  "cudaverse/cudagraphR",
  "cudaverse/cudaembedr",
  "igraph"
))
```

`igraph` is optional and is needed only for community detection. The
diffusion-map example below has a base eigensolver; installing `RSpectra` can
accelerate its CPU eigendecomposition.

## Create sparse counts

```r
library(Matrix)
library(cudacellr)
library(cudagraphR)
library(cudaembedr)

set.seed(42)
counts <- Matrix(
  matrix(rpois(600 * 120, lambda = 1.2), nrow = 600, ncol = 120),
  sparse = TRUE
)
rownames(counts) <- paste0("gene_", seq_len(nrow(counts)))
colnames(counts) <- paste0("cell_", seq_len(ncol(counts)))

dim(counts)
#> [1] 600 120
```

Real count matrices should contain finite, non-negative values and every cell
must have a positive library size.

## Normalize, select features, reduce dimensions, and find neighbours

Start with the guaranteed CPU path:

```r
fit <- cudacell_workflow(
  counts,
  n_hvg = 200,
  n_components = 15,
  k = 12,
  batch_size = 32,
  device = "cpu"
)

class(fit$normalized)
#> [1] "dgCMatrix"

dim(fit$pca$x)
#> [1] 120  15

dim(fit$neighbors$index)
#> [1] 120  12

fit$pca$device
fit$neighbors$device
```

Normalization remains sparse. Only the selected variable-feature matrix is
materialized for PCA. Exact kNN compares all cells but holds at most
`batch_size * cells` distances at once; changing `batch_size` changes peak
memory, not the selected neighbours.

## Build and cluster a graph

```r
graph <- cuda_knn_graph(
  fit$neighbors,
  weighting = "gaussian",
  symmetrize = "union"
)

graph
adjacency <- as_adjacency_matrix(graph)
dim(adjacency)

communities <- cuda_leiden(graph, resolution = 1)
table(communities$membership)
```

The neighbour result may originate on CUDA, but graph assembly and current
Louvain/Leiden implementations run on CPU. Inspect `graph$source_device`,
`graph$backend`, and `communities$backend` rather than inferring the backend
from a function name.

## Compute an embedding

```r
embedding <- cuda_diffusion_map(
  fit,
  n_components = 2,
  device = "cpu"
)

coordinates <- embedding_coordinates(embedding)
dim(coordinates)
#> [1] 120   2

embedding$compute_device
embedding$compute_stages
```

Diffusion-map distance computation can use CUDA, while kernel construction and
eigendecomposition remain CPU stages. Such a run reports `"hybrid"`. UMAP and
t-SNE are separate optional CPU adapters requiring `uwot` and `Rtsne`.

## Move the supported stages to CUDA

After completing the
[GPU setup and verification steps](GPU_SETUP.md), change only the device:

```r
if (cudatensr::cuda_available()) {
  gpu_fit <- cudacell_workflow(
    counts,
    n_hvg = 200,
    n_components = 15,
    k = 12,
    batch_size = 32,
    device = "cuda"
  )

  gpu_fit$pca$device
  gpu_fit$neighbors$device
}
```

Use `device = "cuda"` when CUDA is required. Use `"auto"` only when a CPU
fallback is acceptable. Always record actual device and stage provenance with
reproducible results.

## Continue from individual stages

Every stage is independently callable:

- `cuda_normalize_counts()` returns a sparse `dgCMatrix`;
- `cuda_hvg()` returns ranked feature statistics and a `selected` flag;
- `cuda_cell_pca()` returns a `cuda_pca` object and selected feature names;
- `cuda_cell_neighbors()` returns the stable `cuda_knn` contract;
- `cuda_knn_graph()` accepts that contract without recomputing distances;
- `embedding_coordinates()` returns an ordinary coordinate matrix.

This makes it possible to insert quality control, save intermediate objects, or
replace one stage without rerunning the entire workflow.
