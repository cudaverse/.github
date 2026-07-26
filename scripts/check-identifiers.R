set.seed(42)

check_provenance <- function(x, expected_stages, compute_device = "cpu") {
  provenance <- cudatensr::cuda_provenance(x)
  stopifnot(
    inherits(provenance, "cuda_provenance"),
    identical(
      names(provenance),
      c(
        "stage",
        "requested_device",
        "device",
        "backend",
        "selection_reason",
        "fallback",
        "output_device"
      )
    ),
    identical(provenance$stage, expected_stages),
    identical(attr(provenance, "schema"), "cudaverse-stage/1"),
    identical(attr(provenance, "compute_device"), compute_device),
    all(provenance$device %in% c("cpu", "cuda")),
    all(provenance$output_device %in% c("cpu", "cuda"))
  )
  invisible(provenance)
}

counts <- matrix(rpois(60 * 24, lambda = 2), nrow = 60, ncol = 24)
rownames(counts) <- paste0("gene_", seq_len(nrow(counts)))
colnames(counts) <- paste0("cell_", seq_len(ncol(counts)))

tensor <- cudatensr::cuda_tensor(counts, device = "cpu")
stopifnot(identical(dimnames(cudatensr::to_cpu(tensor)), dimnames(counts)))
check_provenance(tensor, "tensor_materialization")

sparse <- cudasparsr::cuda_sparse(counts, device = "cpu")
stopifnot(
  identical(
    dimnames(cudasparsr::to_dgCMatrix(sparse)),
    dimnames(counts)
  )
)
check_provenance(sparse, "sparse_materialization")

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
workflow_provenance <- check_provenance(
  workflow,
  c(
    "normalization",
    "hvg",
    "pca_preprocessing",
    "pca_decomposition",
    "knn_distance",
    "knn_neighbor_selection"
  )
)

graph <- cudagraphR::cuda_knn_graph(workflow$neighbors)
stopifnot(
  identical(graph$vertex_names, colnames(counts)),
  identical(
    dimnames(cudagraphR::as_adjacency_matrix(graph)),
    list(colnames(counts), colnames(counts))
  ),
  inherits(graph$source_provenance, "cuda_provenance"),
  identical(graph$source_provenance$stage, workflow_provenance$stage)
)
check_provenance(graph, "graph_assembly")

set.seed(1)
communities <- cudagraphR::cuda_louvain(graph)
stopifnot(
  identical(names(communities$membership), colnames(counts)),
  inherits(communities$source_provenance, "cuda_provenance")
)
check_provenance(communities, "community_detection")

embedding <- cudaembedr::cuda_diffusion_map(
  workflow,
  n_components = 2,
  device = "cpu"
)
stopifnot(
  identical(
    rownames(cudaembedr::embedding_coordinates(embedding)),
    colnames(counts)
  ),
  inherits(embedding$source_provenance, "cuda_provenance"),
  identical(embedding$source_provenance$stage, workflow_provenance$stage)
)
check_provenance(
  embedding,
  c("distance", "kernel", "eigendecomposition")
)

cat("Cudaverse identifier and provenance integration contract passed.\n")
