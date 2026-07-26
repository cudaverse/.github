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

For the optional native Bioconductor path:

```r
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
BiocManager::install("SingleCellExperiment")
```

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

gene_ids <- rownames(counts)
cell_ids <- colnames(counts)

stopifnot(
  length(gene_ids) == nrow(counts),
  length(cell_ids) == ncol(counts),
  all(nzchar(gene_ids)),
  all(nzchar(cell_ids)),
  anyDuplicated(gene_ids) == 0L,
  anyDuplicated(cell_ids) == 0L
)

dim(counts)
#> [1] 600 120
```

Real count matrices should contain finite, non-negative values and every cell
must have a positive library size. The workflow can operate without dimnames,
but this example requires unique, non-empty gene and cell identifiers so every
downstream identity assertion is explicit rather than positional guesswork.

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

selected_gene_ids <- fit$variable_features$feature[
  fit$variable_features$selected
]

stopifnot(
  identical(rownames(fit$normalized), gene_ids),
  identical(colnames(fit$normalized), cell_ids),
  setequal(fit$variable_features$feature, gene_ids),
  identical(fit$pca$features, selected_gene_ids),
  identical(rownames(fit$pca$rotation), selected_gene_ids),
  identical(rownames(fit$pca$x), cell_ids),
  identical(rownames(fit$neighbors$index), cell_ids),
  identical(rownames(fit$neighbors$distance), cell_ids)
)

neighbor_cell_ids <- matrix(
  cell_ids[fit$neighbors$index],
  nrow = nrow(fit$neighbors$index),
  dimnames = dimnames(fit$neighbors$index)
)
query_cell_ids <- matrix(
  cell_ids,
  nrow = length(cell_ids),
  ncol = ncol(neighbor_cell_ids)
)
stopifnot(!any(neighbor_cell_ids == query_cell_ids))

fit$pca$device
fit$neighbors$device
cudacellr::cuda_provenance(fit)
```

Normalization remains sparse. Only the selected variable-feature matrix is
materialized for PCA. Exact kNN compares all cells but holds at most
`batch_size * cells` distances at once; changing `batch_size` changes peak
memory, not the selected neighbours. kNN indices are one-based positions into
`cell_ids`; `neighbor_cell_ids` above converts them to stable identifiers.

## Keep the workflow in a SingleCellExperiment

`cudacell_sce()` provides the same computation without replacing the
Bioconductor object model. It returns a modified copy and writes each result to
its native location:

```r
library(SingleCellExperiment)

sce <- SingleCellExperiment(
  assays = list(
    counts = counts,
    untouched = counts * 2
  ),
  rowData = S4Vectors::DataFrame(
    symbol = paste0("symbol_", seq_len(nrow(counts)))
  ),
  colData = S4Vectors::DataFrame(
    batch = rep(c("one", "two"), length.out = ncol(counts))
  ),
  metadata = list(owner = "unchanged")
)

sce_result <- cudacell_sce(
  sce,
  assay = "counts",
  n_hvg = 200,
  n_components = 15,
  k = 12,
  batch_size = 32,
  device = "cpu"
)

assayNames(sce_result)
#> [1] "counts"              "untouched"
#> [3] "cudacell_logcounts"

reducedDimNames(sce_result)
#> [1] "CUDACELL_PCA"

colPairNames(sce_result)
#> [1] "CUDACELL_KNN"

stopifnot(
  identical(assay(sce_result, "counts"), assay(sce, "counts")),
  identical(assay(sce_result, "untouched"), assay(sce, "untouched")),
  identical(rowData(sce_result)$symbol, rowData(sce)$symbol),
  identical(colData(sce_result)$batch, colData(sce)$batch),
  identical(metadata(sce_result)$owner, "unchanged"),
  identical(
    rownames(reducedDim(sce_result, "CUDACELL_PCA")),
    cell_ids
  )
)

cudacellr::cuda_provenance(sce_result)
```

Natural-log normalized expression is namespaced as
`cudacell_logcounts`; PCA is `CUDACELL_PCA`; HVG statistics are added to
namespaced `rowData` columns; and directed neighbours are a
`CUDACELL_KNN` `SelfHits` object in `colPair`. Existing assays, row/column
metadata, reduced dimensions, alternative experiments, pairings, labels, size
factors, and user metadata remain intact.

Every output name is collision-checked before compute. Delayed assays also
remain lazy unless the caller explicitly opts into in-memory sparse
realization with `realize = TRUE`.

All embedding entry points can consume the recorded PCA directly:

```r
sce_embedding <- cuda_diffusion_map(
  sce_result,
  n_components = 2,
  device = "cpu"
)

stopifnot(
  identical(
    rownames(embedding_coordinates(sce_embedding)),
    cell_ids
  ),
  identical(
    sce_embedding$parameters$reduced_dim,
    "CUDACELL_PCA"
  ),
  inherits(sce_embedding$source_provenance, "cuda_provenance")
)
```

For a generic SCE without cudacellr metadata, `cudaembedr` uses a uniquely
named standard `PCA` reduced dimension. Any non-PCA reduced dimension must be
selected explicitly; its source device is reported as `"unknown"` when no
provenance record exists.

## Keep the workflow in a SeuratObject v5 object

`cudacell_seurat()` offers the same native-object path without requiring the
full Seurat package. Install `SeuratObject >= 5.0.0`, then select one exact
assay layer:

```r
seurat <- SeuratObject::CreateSeuratObject(counts)

seurat_result <- cudacell_seurat(
  seurat,
  assay = "RNA",
  layer = "counts",
  n_hvg = 200,
  n_components = 15,
  k = 12,
  batch_size = 32,
  device = "cpu"
)

SeuratObject::Layers(seurat_result[["CUDACELL"]])
#> [1] "data"

head(SeuratObject::Embeddings(
  seurat_result[["cudacell_pca"]]
))
head(SeuratObject::Indices(
  seurat_result[["cudacell_knn"]]
))

cudacellr::cuda_provenance(seurat_result)
SeuratObject::Tool(
  seurat_result,
  slot = "cudacell_seurat"
)$outputs
```

The output uses a native data-only `Assay5`, `DimReduc`, and `Neighbor`, plus
namespaced feature and cell metadata. Existing assays and layers, identities,
reductions, graphs, neighbours, metadata, images, tools, and miscellaneous
state remain intact. All names and Seurat keys are checked before computation;
`overwrite = TRUE` replaces only the explicitly named cudacellr outputs.
Non-memory-backed layers require the explicit, memory-conscious
`realize = TRUE` opt-in.

The
[SeuratObject v5 article](https://cudaverse.github.io/cudacellr/articles/seurat-object.html)
contains the complete preservation and collision-safety walkthrough.

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
cudagraphR::cuda_provenance(graph)
graph$source_provenance

stopifnot(
  identical(graph$vertex_names, cell_ids),
  identical(rownames(adjacency), cell_ids),
  identical(colnames(adjacency), cell_ids),
  identical(names(communities$membership), cell_ids)
)
```

The neighbour result may originate on CUDA, but graph assembly and current
Louvain/Leiden implementations run on CPU. Inspect `graph$source_device`,
`graph$backend`, and `communities$backend` rather than inferring the backend
from a function name. Graph vertices and named community memberships retain the
same cell order established by the count matrix.

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

stopifnot(identical(rownames(coordinates), cell_ids))

embedding$compute_device
embedding$compute_stages
cudaembedr::cuda_provenance(embedding)
embedding$source_provenance
```

Diffusion-map distance computation can use CUDA, while kernel construction and
eigendecomposition remain CPU stages. Such a run reports `"hybrid"`. UMAP and
t-SNE are separate optional CPU adapters requiring `uwot` and `Rtsne`.
Embedding rows retain the same cell identifiers as PCA, kNN, graph vertices,
and community memberships.

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
fallback is acceptable. `cuda_provenance()` records the original request,
actual stage device, backend, selection reason, fallback flag, and output
device. A strict CUDA request never silently returns a CPU result.

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
