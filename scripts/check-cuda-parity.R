required <- c(
  "cudaverse",
  "cudacellr",
  "Matrix",
  "igraph",
  "SingleCellExperiment",
  "S4Vectors",
  "SummarizedExperiment",
  "torch"
)
missing <- required[
  !vapply(required, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing)) {
  stop(
    "CUDA parity requires installed packages: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

diagnostics <- cudaverse::cuda_diagnostics()
print(diagnostics)
if (!isTRUE(diagnostics$cuda_available) ||
    is.na(diagnostics$cuda_device_count) ||
    diagnostics$cuda_device_count < 1L) {
  stop(
    "CUDA hardware coverage is required, but no usable NVIDIA device exists.",
    call. = FALSE
  )
}

equal_numeric <- function(actual, expected, tolerance = 1e-7,
                          label = deparse(substitute(actual))) {
  actual_dim <- dim(actual)
  expected_dim <- dim(expected)
  if (!identical(actual_dim, expected_dim)) {
    format_shape <- function(x) {
      if (is.null(x)) "<none>" else paste(x, collapse = " x ")
    }
    stop(
      sprintf(
        "%s shape parity failed: actual [%s], expected [%s].",
        label,
        format_shape(actual_dim),
        format_shape(expected_dim)
      ),
      call. = FALSE
    )
  }
  if (!identical(dimnames(actual), dimnames(expected))) {
    stop(label, " dimnames parity failed.", call. = FALSE)
  }
  comparison <- all.equal(
    unname(as.numeric(actual)),
    unname(as.numeric(expected)),
    tolerance = tolerance,
    check.attributes = FALSE
  )
  if (!isTRUE(comparison)) {
    stop(label, " parity failed: ", paste(comparison, collapse = "; "),
         call. = FALSE)
  }
  invisible(TRUE)
}

expect_stage <- function(x, stage, device, aggregate = NULL) {
  provenance <- cudaverse::cuda_provenance(x)
  selected <- provenance[provenance$stage == stage, , drop = FALSE]
  if (nrow(selected) != 1L || !identical(selected$device, device)) {
    stop(
      sprintf(
        "Expected stage `%s` on %s; observed: %s.",
        stage,
        device,
        paste(
          paste0(provenance$stage, "=", provenance$device),
          collapse = ", "
        )
      ),
      call. = FALSE
    )
  }
  if (!is.null(aggregate) &&
      !identical(attr(provenance, "compute_device"), aggregate)) {
    stop(
      sprintf(
        "Expected aggregate device %s; observed %s.",
        aggregate,
        attr(provenance, "compute_device")
      ),
      call. = FALSE
    )
  }
  invisible(provenance)
}

expect_tensor_contract <- function(x, dtype, shape, device, backend, stage) {
  if (!inherits(x, "cudatensor")) {
    stop("Expected a `cudatensor` result.", call. = FALSE)
  }
  if (!identical(x$dtype, dtype)) {
    stop(
      sprintf("Expected dtype %s; observed %s.", dtype, x$dtype),
      call. = FALSE
    )
  }
  shape <- as.integer(shape)
  observed_shape <- cudaverse::tensor_shape(x)
  if (!identical(observed_shape, shape)) {
    stop(
      sprintf(
        "Expected tensor shape [%s]; observed [%s].",
        paste(shape, collapse = " x "),
        paste(observed_shape, collapse = " x ")
      ),
      call. = FALSE
    )
  }
  observed_device <- unname(cudaverse::tensor_device(x))
  expected_device <- c(device, backend)
  if (!identical(observed_device, expected_device)) {
    stop(
      sprintf(
        "Expected tensor device/backend %s/%s; observed %s.",
        device,
        backend,
        paste(observed_device, collapse = "/")
      ),
      call. = FALSE
    )
  }
  provenance <- expect_stage(x, stage, device, device)
  if (!inherits(provenance, "cuda_provenance") ||
      !identical(attr(provenance, "schema"), "cudaverse-stage/1")) {
    stop("Expected cudaverse-stage/1 provenance.", call. = FALSE)
  }
  selected <- provenance[provenance$stage == stage, , drop = FALSE]
  if (!identical(selected$backend, backend) ||
      !identical(selected$output_device, device)) {
    stop(
      sprintf(
        "Expected stage `%s` backend/output %s/%s; observed %s/%s.",
        stage,
        backend,
        device,
        selected$backend,
        selected$output_device
      ),
      call. = FALSE
    )
  }
  invisible(provenance)
}

cat("Checking cudaverse dense tensor CUDA paths...\n")
set.seed(20260726)
dense <- matrix(
  rnorm(60),
  nrow = 12,
  ncol = 5,
  dimnames = list(paste0("row_", 1:12), paste0("feature_", 1:5))
)
cpu_tensor <- cudaverse::cuda_tensor(
  dense,
  device = "cpu",
  dtype = "float64"
)
gpu_tensor <- cudaverse::cuda_tensor(
  dense,
  device = "cuda",
  dtype = "float64"
)
stopifnot(
  identical(unname(cudaverse::tensor_device(gpu_tensor)),
            c("cuda", "torch"))
)
equal_numeric(cudaverse::to_cpu(gpu_tensor), dense, label = "tensor upload")

equal_numeric(
  cudaverse::to_cpu(gpu_tensor + 0.25),
  cudaverse::to_cpu(cpu_tensor + 0.25),
  label = "tensor arithmetic"
)
expect_stage(gpu_tensor + 0.25, "arithmetic", "cuda", "cuda")

right <- matrix(rnorm(20), 5, 4)
gpu_product <- cudaverse::tensor_matmul(
  gpu_tensor,
  cudaverse::cuda_tensor(right, "cuda", "float64")
)
cpu_product <- cudaverse::tensor_matmul(cpu_tensor, right)
equal_numeric(
  cudaverse::to_cpu(gpu_product),
  cudaverse::to_cpu(cpu_product),
  tolerance = 1e-6,
  label = "tensor matrix multiplication"
)
expect_stage(gpu_product, "matrix_multiply", "cuda", "cuda")

equal_numeric(
  cudaverse::to_cpu(cudaverse::tensor_sum(gpu_tensor, dim = 1)),
  cudaverse::to_cpu(cudaverse::tensor_sum(cpu_tensor, dim = 1)),
  tolerance = 1e-6,
  label = "tensor sum"
)
equal_numeric(
  cudaverse::to_cpu(cudaverse::tensor_mean(gpu_tensor, dim = 2)),
  cudaverse::to_cpu(cudaverse::tensor_mean(cpu_tensor, dim = 2)),
  tolerance = 1e-6,
  label = "tensor mean"
)
equal_numeric(
  cudaverse::to_cpu(cudaverse::tensor_reshape(gpu_tensor, c(3, 20))),
  cudaverse::to_cpu(cudaverse::tensor_reshape(cpu_tensor, c(3, 20))),
  label = "tensor reshape"
)
equal_numeric(
  cudaverse::to_cpu(t(gpu_tensor)),
  cudaverse::to_cpu(t(cpu_tensor)),
  label = "tensor transpose"
)
gpu_subset <- gpu_tensor[1:4, 2:4, drop = FALSE]
cpu_subset <- cpu_tensor[1:4, 2:4, drop = FALSE]
equal_numeric(
  cudaverse::to_cpu(gpu_subset),
  cudaverse::to_cpu(cpu_subset),
  label = "tensor subset"
)
expect_stage(gpu_subset, "subset", "cpu", "hybrid")
gpu_tensor[1, 1] <- 10
cpu_tensor[1, 1] <- 10
equal_numeric(
  cudaverse::to_cpu(gpu_tensor),
  cudaverse::to_cpu(cpu_tensor),
  label = "tensor replacement"
)
expect_stage(gpu_tensor, "replacement", "cpu", "hybrid")

float_values <- matrix(
  c(
    -1.25, 0.5, 2.1, 3.25,
    0.75, -2.5, 1.5, 0.3,
    4, 1.2, -0.5, 2.75
  ),
  nrow = 3,
  byrow = TRUE,
  dimnames = list(
    sample = paste0("float_sample_", 1:3),
    feature = paste0("float_feature_", 1:4)
  )
)
cpu_float <- cudaverse::cuda_tensor(
  float_values,
  device = "cpu",
  dtype = "float32"
)
expect_tensor_contract(
  cpu_float, "float32", c(3, 4), "cpu", "base",
  "tensor_materialization"
)
gpu_float <- cudaverse::to_device(cpu_float, "cuda")
equal_numeric(
  cudaverse::to_cpu(gpu_float),
  cudaverse::to_cpu(cpu_float),
  tolerance = 2e-6,
  label = "float32 CPU-to-CUDA transfer"
)
expect_tensor_contract(
  gpu_float, "float32", c(3, 4), "cuda", "torch",
  "device_transfer"
)
cpu_float_roundtrip <- cudaverse::to_device(gpu_float, "cpu")
equal_numeric(
  cudaverse::to_cpu(cpu_float_roundtrip),
  cudaverse::to_cpu(cpu_float),
  tolerance = 2e-6,
  label = "float32 CUDA-to-CPU transfer"
)
expect_tensor_contract(
  cpu_float_roundtrip, "float32", c(3, 4), "cpu", "base",
  "device_transfer"
)

float_offset_values <- setNames(
  c(0.125, -0.2, 0.45, 1.1),
  colnames(float_values)
)
cpu_float_offset <- cudaverse::cuda_tensor(
  float_offset_values,
  device = "cpu",
  dtype = "float32"
)
gpu_float_offset <- cudaverse::to_device(cpu_float_offset, "cuda")
cpu_float_broadcast <- cudaverse::tensor_broadcast_to(
  cpu_float_offset,
  c(3, 4)
)
gpu_float_broadcast <- cudaverse::tensor_broadcast_to(
  gpu_float_offset,
  c(3, 4)
)
equal_numeric(
  cudaverse::to_cpu(gpu_float_broadcast),
  cudaverse::to_cpu(cpu_float_broadcast),
  tolerance = 2e-6,
  label = "float32 broadcast"
)
expect_tensor_contract(
  cpu_float_broadcast, "float32", c(3, 4), "cpu", "base",
  "broadcast"
)
expect_tensor_contract(
  gpu_float_broadcast, "float32", c(3, 4), "cuda", "torch",
  "broadcast"
)

cpu_float_arithmetic <- cpu_float + cpu_float_broadcast
gpu_float_arithmetic <- gpu_float + gpu_float_broadcast
equal_numeric(
  cudaverse::to_cpu(gpu_float_arithmetic),
  cudaverse::to_cpu(cpu_float_arithmetic),
  tolerance = 3e-6,
  label = "float32 arithmetic"
)
expect_tensor_contract(
  cpu_float_arithmetic, "float32", c(3, 4), "cpu", "base",
  "arithmetic"
)
expect_tensor_contract(
  gpu_float_arithmetic, "float32", c(3, 4), "cuda", "torch",
  "arithmetic"
)

float_right_values <- matrix(
  c(
    0.5, -0.25,
    1.1, 0.75,
    -0.5, 1.25,
    0.3, -1
  ),
  nrow = 4,
  byrow = TRUE,
  dimnames = list(
    feature = colnames(float_values),
    output = c("float_score_1", "float_score_2")
  )
)
cpu_float_right <- cudaverse::cuda_tensor(
  float_right_values,
  device = "cpu",
  dtype = "float32"
)
gpu_float_right <- cudaverse::to_device(cpu_float_right, "cuda")
cpu_float_product <- cudaverse::tensor_matmul(
  cpu_float,
  cpu_float_right
)
gpu_float_product <- cudaverse::tensor_matmul(
  gpu_float,
  gpu_float_right
)
equal_numeric(
  cudaverse::to_cpu(gpu_float_product),
  cudaverse::to_cpu(cpu_float_product),
  tolerance = 1e-5,
  label = "float32 matrix multiplication"
)
expect_tensor_contract(
  cpu_float_product, "float32", c(3, 2), "cpu", "base",
  "matrix_multiply"
)
expect_tensor_contract(
  gpu_float_product, "float32", c(3, 2), "cuda", "torch",
  "matrix_multiply"
)

cpu_float_sum <- cudaverse::tensor_sum(cpu_float, dim = 1)
gpu_float_sum <- cudaverse::tensor_sum(gpu_float, dim = 1)
equal_numeric(
  cudaverse::to_cpu(gpu_float_sum),
  cudaverse::to_cpu(cpu_float_sum),
  tolerance = 1e-5,
  label = "float32 sum"
)
expect_tensor_contract(
  cpu_float_sum, "float32", 4, "cpu", "base", "sum"
)
expect_tensor_contract(
  gpu_float_sum, "float32", 4, "cuda", "torch", "sum"
)

cpu_float_mean <- cudaverse::tensor_mean(
  cpu_float,
  dim = 2,
  keepdim = TRUE
)
gpu_float_mean <- cudaverse::tensor_mean(
  gpu_float,
  dim = 2,
  keepdim = TRUE
)
equal_numeric(
  cudaverse::to_cpu(gpu_float_mean),
  cudaverse::to_cpu(cpu_float_mean),
  tolerance = 1e-5,
  label = "float32 mean"
)
expect_tensor_contract(
  cpu_float_mean, "float32", c(3, 1), "cpu", "base", "mean"
)
expect_tensor_contract(
  gpu_float_mean, "float32", c(3, 1), "cuda", "torch", "mean"
)

cat("Checking cudaverse sparse matrix CUDA paths...\n")
sparse_source <- dense
sparse_source[abs(sparse_source) < 0.7] <- 0
sparse_source <- Matrix::Matrix(sparse_source, sparse = TRUE)
cpu_sparse <- cudaverse::cuda_sparse(sparse_source, device = "cpu")
gpu_sparse <- cudaverse::cuda_sparse(sparse_source, device = "cuda")
equal_numeric(
  as.matrix(cudaverse::to_dgCMatrix(gpu_sparse)),
  as.matrix(sparse_source),
  label = "sparse conversion"
)

sparse_right <- matrix(rnorm(15), 5, 3)
cpu_sparse_product <- cudaverse::sparse_matmul_dense(
  cpu_sparse,
  sparse_right
)
gpu_sparse_product <- cudaverse::sparse_matmul_dense(
  gpu_sparse,
  sparse_right
)
equal_numeric(
  cudaverse::to_cpu(gpu_sparse_product),
  cudaverse::to_cpu(cpu_sparse_product),
  tolerance = 1e-6,
  label = "sparse dense multiplication"
)
expect_stage(gpu_sparse_product, "sparse_multiply", "cuda", "hybrid")
equal_numeric(
  cudaverse::sparse_matvec(gpu_sparse, seq_len(ncol(sparse_source))),
  cudaverse::sparse_matvec(cpu_sparse, seq_len(ncol(sparse_source))),
  tolerance = 1e-6,
  label = "sparse matrix vector multiplication"
)
equal_numeric(
  cudaverse::sparse_row_sums(gpu_sparse),
  Matrix::rowSums(sparse_source),
  label = "sparse row sums"
)
equal_numeric(
  cudaverse::sparse_col_sums(gpu_sparse),
  Matrix::colSums(sparse_source),
  label = "sparse column sums"
)

explicit_zero <- Matrix::sparseMatrix(
  i = c(1L, 2L),
  j = c(1L, 2L),
  x = c(0, 1),
  dims = c(2L, 2L)
)
zero_object <- cudaverse::cuda_sparse(
  explicit_zero,
  device = "cuda",
  drop_zeros = FALSE
)
zero_dropped <- cudaverse::cuda_sparse(
  zero_object,
  device = "cuda",
  drop_zeros = TRUE
)
stopifnot(!any(zero_dropped$values == 0))

cat("Checking cudaverse numerical algorithms...\n")
learning <- matrix(
  rnorm(120),
  nrow = 24,
  ncol = 5,
  dimnames = list(paste0("sample_", 1:24), paste0("variable_", 1:5))
)
cpu_svd <- cudaverse::cuda_svd(learning, device = "cpu")
gpu_svd <- cudaverse::cuda_svd(learning, device = "cuda")
equal_numeric(gpu_svd$d, cpu_svd$d, tolerance = 1e-6, label = "SVD")
expect_stage(gpu_svd, "decomposition", "cuda", "cuda")

cpu_pca <- cudaverse::cuda_pca(
  learning,
  n_components = 3,
  scale. = TRUE,
  device = "cpu"
)
gpu_pca <- cudaverse::cuda_pca(
  learning,
  n_components = 3,
  scale. = TRUE,
  device = "cuda"
)
equal_numeric(gpu_pca$sdev, cpu_pca$sdev, tolerance = 1e-6, label = "PCA")
equal_numeric(
  tcrossprod(gpu_pca$rotation),
  tcrossprod(cpu_pca$rotation),
  tolerance = 1e-6,
  label = "PCA loading subspace"
)
expect_stage(gpu_pca, "decomposition", "cuda", "cuda")

for (metric in c("euclidean", "cosine")) {
  cpu_distance <- cudaverse::cuda_distance(
    learning,
    metric = metric,
    device = "cpu"
  )
  gpu_distance <- cudaverse::cuda_distance(
    learning,
    metric = metric,
    device = "cuda"
  )
  equal_numeric(
    gpu_distance,
    cpu_distance,
    tolerance = 1e-6,
    label = paste(metric, "distance")
  )
  expect_stage(gpu_distance, "distance", "cuda", "cuda")
}

cpu_knn <- cudaverse::cuda_knn(
  learning,
  k = 5,
  batch_size = 7,
  device = "cpu"
)
gpu_knn <- cudaverse::cuda_knn(
  learning,
  k = 5,
  batch_size = 7,
  device = "cuda"
)
stopifnot(identical(gpu_knn$index, cpu_knn$index))
equal_numeric(
  gpu_knn$distance,
  cpu_knn$distance,
  tolerance = 1e-6,
  label = "exact kNN distance"
)
expect_stage(gpu_knn, "distance", "cuda", "hybrid")

initial_centers <- learning[c(1L, 13L), , drop = FALSE]
cpu_kmeans <- cudaverse::cuda_kmeans(
  learning,
  centers = initial_centers,
  device = "cpu"
)
gpu_kmeans <- cudaverse::cuda_kmeans(
  learning,
  centers = initial_centers,
  device = "cuda"
)
stopifnot(identical(gpu_kmeans$cluster, cpu_kmeans$cluster))
equal_numeric(
  gpu_kmeans$centers,
  cpu_kmeans$centers,
  tolerance = 1e-6,
  label = "k-means centers"
)
expect_stage(gpu_kmeans, "distance", "cuda", "hybrid")

cat("Checking cudacellr workflow parity...\n")
counts <- matrix(
  rpois(60 * 30, lambda = 3),
  nrow = 60,
  ncol = 30,
  dimnames = list(paste0("gene_", 1:60), paste0("cell_", 1:30))
)
cpu_cells <- cudacellr::cudacell_workflow(
  counts,
  n_hvg = 25,
  n_components = 5,
  k = 5,
  batch_size = 8,
  device = "cpu"
)
gpu_cells <- cudacellr::cudacell_workflow(
  counts,
  n_hvg = 25,
  n_components = 5,
  k = 5,
  batch_size = 8,
  device = "cuda"
)
equal_numeric(
  as.matrix(gpu_cells$normalized),
  as.matrix(cpu_cells$normalized),
  label = "single-cell normalization"
)
stopifnot(identical(
  gpu_cells$variable_features$index,
  cpu_cells$variable_features$index
))
equal_numeric(
  gpu_cells$pca$sdev,
  cpu_cells$pca$sdev,
  tolerance = 1e-6,
  label = "single-cell PCA"
)
stopifnot(identical(gpu_cells$neighbors$index, cpu_cells$neighbors$index))
equal_numeric(
  gpu_cells$neighbors$distance,
  cpu_cells$neighbors$distance,
  tolerance = 1e-6,
  label = "single-cell kNN"
)
expect_stage(gpu_cells, "pca_decomposition", "cuda", "hybrid")
expect_stage(gpu_cells, "knn_distance", "cuda", "hybrid")

cat("Checking SingleCellExperiment workflow parity...\n")
sce <- SingleCellExperiment::SingleCellExperiment(
  assays = list(
    counts = counts,
    untouched = counts * 2
  ),
  metadata = list(owner = "preserve-me")
)
cpu_sce <- cudacellr::cudacell_sce(
  sce,
  n_hvg = 25,
  n_components = 5,
  k = 5,
  batch_size = 8,
  device = "cpu"
)
gpu_sce <- cudacellr::cudacell_sce(
  sce,
  n_hvg = 25,
  n_components = 5,
  k = 5,
  batch_size = 8,
  device = "cuda"
)
equal_numeric(
  as.matrix(
    SummarizedExperiment::assay(
      gpu_sce,
      "cudacell_logcounts"
    )
  ),
  as.matrix(
    SummarizedExperiment::assay(
      cpu_sce,
      "cudacell_logcounts"
    )
  ),
  label = "SCE normalized assay"
)
equal_numeric(
  as.matrix(stats::dist(
    SingleCellExperiment::reducedDim(
      gpu_sce,
      "CUDACELL_PCA"
    )
  )),
  as.matrix(stats::dist(
    SingleCellExperiment::reducedDim(
      cpu_sce,
      "CUDACELL_PCA"
    )
  )),
  tolerance = 1e-6,
  label = "SCE PCA geometry"
)
gpu_hits <- as.data.frame(
  SingleCellExperiment::colPair(gpu_sce, "CUDACELL_KNN")
)
cpu_hits <- as.data.frame(
  SingleCellExperiment::colPair(cpu_sce, "CUDACELL_KNN")
)
stopifnot(
  identical(gpu_hits[c("from", "to", "rank")],
            cpu_hits[c("from", "to", "rank")]),
  identical(
    SummarizedExperiment::assay(gpu_sce, "counts"),
    SummarizedExperiment::assay(sce, "counts")
  ),
  identical(
    SummarizedExperiment::assay(gpu_sce, "untouched"),
    SummarizedExperiment::assay(sce, "untouched")
  ),
  identical(S4Vectors::metadata(gpu_sce)$owner, "preserve-me")
)
equal_numeric(
  gpu_hits$distance,
  cpu_hits$distance,
  tolerance = 1e-6,
  label = "SCE kNN distances"
)
sce_provenance <- cudacellr::cuda_provenance(gpu_sce)
stopifnot(
  identical(attr(sce_provenance, "compute_device"), "hybrid"),
  identical(
    sce_provenance$device[
      sce_provenance$stage == "pca_decomposition"
    ],
    "cuda"
  ),
  identical(
    sce_provenance$device[
      sce_provenance$stage == "knn_distance"
    ],
    "cuda"
  )
)

cat("Checking graph and embedding integration...\n")
graph <- cudaverse::cuda_knn_graph(gpu_knn, weighting = "gaussian")
expect_stage(graph, "graph_assembly", "cpu", "cpu")
stopifnot(
  identical(graph$source_device, "cuda"),
  inherits(graph$source_provenance, "cuda_provenance"),
  identical(
    attr(graph$source_provenance, "compute_device"),
    "hybrid"
  )
)
communities <- cudaverse::cuda_leiden(graph, n_iterations = 2)
expect_stage(communities, "community_detection", "cpu", "cpu")
stopifnot(length(communities$membership) == nrow(learning))

cpu_embedding <- cudaverse::cuda_diffusion_map(
  learning,
  n_components = 3,
  device = "cpu"
)
gpu_embedding <- cudaverse::cuda_diffusion_map(
  learning,
  n_components = 3,
  device = "cuda"
)
equal_numeric(
  gpu_embedding$eigenvalues,
  cpu_embedding$eigenvalues,
  tolerance = 1e-6,
  label = "diffusion eigenvalues"
)
equal_numeric(
  as.matrix(stats::dist(gpu_embedding$coordinates)),
  as.matrix(stats::dist(cpu_embedding$coordinates)),
  tolerance = 1e-5,
  label = "diffusion coordinate geometry"
)
expect_stage(gpu_embedding, "distance", "cuda", "hybrid")

cpu_sce_embedding <- cudaverse::cuda_diffusion_map(
  cpu_sce,
  n_components = 3,
  device = "cpu"
)
gpu_sce_embedding <- cudaverse::cuda_diffusion_map(
  gpu_sce,
  n_components = 3,
  device = "cuda"
)
equal_numeric(
  gpu_sce_embedding$eigenvalues,
  cpu_sce_embedding$eigenvalues,
  tolerance = 1e-6,
  label = "SCE diffusion eigenvalues"
)
equal_numeric(
  as.matrix(stats::dist(gpu_sce_embedding$coordinates)),
  as.matrix(stats::dist(cpu_sce_embedding$coordinates)),
  tolerance = 1e-5,
  label = "SCE diffusion coordinate geometry"
)
stopifnot(
  identical(
    rownames(gpu_sce_embedding$coordinates),
    colnames(sce)
  ),
  identical(
    gpu_sce_embedding$parameters$reduced_dim,
    "CUDACELL_PCA"
  ),
  inherits(gpu_sce_embedding$source_provenance, "cuda_provenance"),
  identical(gpu_sce_embedding$source_compute_device, "hybrid")
)
expect_stage(gpu_sce_embedding, "distance", "cuda", "hybrid")

cat("All required cudaverse CUDA paths passed hardware parity checks.\n")
