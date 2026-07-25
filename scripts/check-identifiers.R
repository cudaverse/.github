set.seed(42)

counts <- matrix(rpois(60 * 24, lambda = 2), nrow = 60, ncol = 24)
rownames(counts) <- paste0("gene_", seq_len(nrow(counts)))
colnames(counts) <- paste0("cell_", seq_len(ncol(counts)))

tensor <- cudatensr::cuda_tensor(counts, device = "cpu")
stopifnot(identical(dimnames(cudatensr::to_cpu(tensor)), dimnames(counts)))

sparse <- cudasparsr::cuda_sparse(counts, device = "cpu")
stopifnot(
  identical(
    dimnames(cudasparsr::to_dgCMatrix(sparse)),
    dimnames(counts)
  )
)

workflow <- cudacellr::cudacell_workflow(
  counts,
  n_hvg = 20,
  n_components = 5,
  k = 4,
  batch_size = 5,
  device = "cpu"
)
stopifnot(
  identical(rownames(workflow$normalized), rownames(counts)),
  identical(colnames(workflow$normalized), colnames(counts)),
  identical(rownames(workflow$pca$x), colnames(counts)),
  identical(rownames(workflow$pca$rotation), workflow$pca$features),
  identical(rownames(workflow$neighbors$index), colnames(counts)),
  identical(
    dimnames(workflow$neighbors$distance),
    dimnames(workflow$neighbors$index)
  )
)

graph <- cudagraphR::cuda_knn_graph(workflow$neighbors)
stopifnot(
  identical(graph$vertex_names, colnames(counts)),
  identical(
    dimnames(cudagraphR::as_adjacency_matrix(graph)),
    list(colnames(counts), colnames(counts))
  )
)

set.seed(1)
communities <- cudagraphR::cuda_louvain(graph)
stopifnot(identical(names(communities$membership), colnames(counts)))

embedding <- cudaembedr::cuda_diffusion_map(
  workflow,
  n_components = 2,
  device = "cpu"
)
stopifnot(
  identical(
    rownames(cudaembedr::embedding_coordinates(embedding)),
    colnames(counts)
  )
)

cat("Cudaverse identifier integration contract passed.\n")
