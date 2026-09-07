# From the exact core checkout, run with Rscript --vanilla. Required variables:
# CUDAVERSE_NATIVE_TESTS=true
# CUDAVERSE_SUPPLEMENT_REPORT=/absolute/new/path/native-contract-supplement.json
# This small correctness/lifecycle supplement is not a timing benchmark.

main <- function() {
  output <- Sys.getenv("CUDAVERSE_SUPPLEMENT_REPORT", unset = "")
  if (!identical(Sys.getenv("CUDAVERSE_NATIVE_TESTS"), "true") || !nzchar(output)) {
    stop("Set CUDAVERSE_NATIVE_TESTS=true and CUDAVERSE_SUPPLEMENT_REPORT.")
  }
  if (file.exists(output)) stop("Refusing to overwrite existing evidence: ", output)
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Install jsonlite first.")

  command <- function(executable, arguments = character()) {
    tryCatch({
      value <- suppressWarnings(system2(
        executable, arguments, stdout = TRUE, stderr = TRUE
      ))
      status <- attr(value, "status")
      list(status = if (is.null(status)) 0L else status, output = unname(value))
    }, error = function(error) list(status = 1L, output = conditionMessage(error)))
  }
  hashes <- function(path) {
    if (!length(path) || !nzchar(path) || !file.exists(path)) return(NULL)
    sha <- command("sha256sum", shQuote(path))
    sha256 <- if (identical(sha$status, 0L) && length(sha$output)) {
      value <- sub(" .*", "", sha$output[[1L]])
      if (grepl("^[0-9a-fA-F]{64}$", value)) tolower(value) else NULL
    } else NULL
    list(path = normalizePath(path, winslash = "/", mustWork = TRUE),
         md5 = unname(tools::md5sum(path)), sha256 = sha256,
         sha256_unavailable_reason = if (is.null(sha256)) "sha256sum_unavailable" else NULL)
  }
  git_commit <- command("git", c("rev-parse", "HEAD"))
  git_status <- command("git", c("status", "--porcelain", "--untracked-files=all"))
  args <- commandArgs(trailingOnly = FALSE)
  script_arg <- grep("^--file=", args, value = TRUE)
  script <- if (length(script_arg) == 1L) sub("^--file=", "", script_arg) else ""
  report <- list(
    schema = "cudaverse-native-contract-supplement/1",
    generated_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    scope = "small strict numeric contracts and 1000 resident PCA-to-kNN lifecycle cycles",
    timing_benchmark = FALSE,
    source = list(commit = git_commit$output, status = git_status$output,
                  clean = identical(git_status$status, 0L) && !length(git_status$output),
                  script = hashes(script),
                  archive = hashes(Sys.getenv("CUDAVERSE_SOURCE_ARCHIVE", unset = ""))),
    hardware = command("nvidia-smi", c(
      "--query-gpu=name,driver_version,memory.total,compute_cap",
      "--format=csv,noheader,nounits"
    )),
    parameters = list(
      seeds = c(1L, 42L, 2026L),
      float32 = list(rtol = 1e-5, atol = 1e-6),
      float64_ordinary = list(rtol = 1e-10, atol = 0),
      float64_matmul_reduce_pca = list(rtol = 1e-8, atol = 0),
      integer = list(rtol = 0, atol = 0),
      criterion = "every element: abs(actual - expected) <= atol + rtol * abs(expected)",
      lifecycle_iterations = 1000L, warmups = 5L,
      lifecycle_memory_limit_bytes = 1024^2
    ),
    cases = list(), passed = FALSE
  )
  add_case <- function(case) {
    report$cases[[length(report$cases) + 1L]] <<- case
    invisible(case)
  }
  numeric_case <- function(name, actual, expected, rtol, atol, details = list()) {
    same_shape <- identical(dim(actual), dim(expected)) && length(actual) == length(expected)
    actual <- as.numeric(actual)
    expected <- as.numeric(expected)
    finite <- all(is.finite(actual)) && all(is.finite(expected))
    comparable <- same_shape && finite && length(actual) > 0L
    error <- if (comparable) abs(actual - expected) else numeric()
    allowed <- if (comparable) atol + rtol * abs(expected) else numeric()
    violations <- if (comparable) sum(error > allowed) else NA_integer_
    ratios <- if (comparable) ifelse(allowed > 0, error / allowed,
                                     ifelse(error == 0, 0, Inf)) else numeric()
    add_case(c(list(
      name = name, passed = comparable && violations == 0L,
      elements = length(actual), same_shape = same_shape, all_finite = finite,
      rtol = rtol, atol = atol,
      max_absolute_error = if (length(error)) max(error) else NULL,
      max_error_to_allowance_ratio = if (length(ratios)) max(ratios) else NULL,
      violations = violations
    ), details))
  }
  logical_case <- function(name, passed, details = list()) {
    add_case(c(list(name = name, passed = isTRUE(passed)), details))
  }
  provenance <- function(object) {
    value <- cudaverse::cuda_provenance(object)
    list(schema = attr(value, "schema", exact = TRUE), stages = value)
  }
  old_options <- options("cudaverse.cuda_backends")
  on.exit(options(old_options), add = TRUE)
  failure <- tryCatch({
    expected_commit <- "2faaa385fcbc9365371476733236578baafaebae"
    if (!identical(git_commit$status, 0L) ||
        !identical(git_commit$output, expected_commit) || !report$source$clean) {
      stop("Run from the clean, frozen cudaverse 0.4.1 checkout at ", expected_commit)
    }
    report$software <- list(
      R = R.version.string, library_paths = .libPaths(),
      torch_installed = requireNamespace("torch", quietly = TRUE),
      cuda_library_paths = as.list(Sys.getenv(c(
        "CUDAVERSE_CUBLAS_PATH", "CUDAVERSE_CUSOLVER_PATH", "LD_LIBRARY_PATH"
      )))
    )
    if (report$software$torch_installed) stop("Torch-free environment is required.")
    if (!requireNamespace("cudaverse", quietly = TRUE)) stop("Install cudaverse first.")
    report$software$cudaverse <- as.character(utils::packageVersion("cudaverse"))
    if (!identical(report$software$cudaverse, "0.4.1")) stop("Expected cudaverse 0.4.1.")
    report$software$installed_description <- hashes(system.file("DESCRIPTION", package = "cudaverse"))
    options(cudaverse.cuda_backends = "native")
    diagnostics <- cudaverse::cuda_diagnostics()
    report$diagnostics <- unclass(diagnostics)
    if (!identical(diagnostics$selected_backend, "native") ||
        !isTRUE(diagnostics$backend_diagnostics$native$self_test$passed)) {
      stop("Native CUDA must be ready in this fresh session.")
    }
    factory <- getFromNamespace(".native_backend_factory", "cudaverse")()
    tracker <- getFromNamespace(".native_memory_tracker", "cudaverse")
    device_memory <- getFromNamespace(".native_memory_info", "cudaverse")
    report$software$installed_dll <- hashes(getLoadedDLLs()[["cudaverse"]][["path"]])
    report$software$loaded_libtorch_dlls <- Filter(
      function(path) grepl("(libtorch|torch_cpu|torch_cuda)", basename(path), ignore.case = TRUE),
      vapply(getLoadedDLLs(), function(dll) dll[["path"]], character(1))
    )
    if (length(report$software$loaded_libtorch_dlls)) stop("LibTorch DLL unexpectedly loaded.")

    run_numeric <- function(seed, dtype) {
      set.seed(seed)
      left <- matrix(stats::rnorm(13L * 7L), 13L, 7L)
      right <- matrix(stats::rnorm(7L * 9L), 7L, 9L)
      x <- cudaverse::cuda_tensor(left, dtype = dtype, device = "cuda")
      y <- cudaverse::cuda_tensor(right, dtype = dtype, device = "cuda")
      atol <- if (dtype == "float32") 1e-6 else 0
      ordinary_rtol <- if (dtype == "float32") 1e-5 else 1e-10
      operation_rtol <- if (dtype == "float32") 1e-5 else 1e-8
      prefix <- paste(dtype, seed, sep = "/")
      numeric_case(paste0(prefix, "/transfer"), cudaverse::to_cpu(x), left,
                   ordinary_rtol, atol, list(seed = seed, dtype = dtype, shape = dim(left)))
      plus <- x + x
      numeric_case(paste0(prefix, "/addition"), cudaverse::to_cpu(plus), left + left,
                   ordinary_rtol, atol, list(provenance = provenance(plus)))
      product <- cudaverse::tensor_matmul(x, y)
      numeric_case(paste0(prefix, "/matmul"), cudaverse::to_cpu(product), left %*% right,
                   operation_rtol, atol,
                   list(left_shape = dim(left), right_shape = dim(right),
                        provenance = provenance(product)))
      summed <- cudaverse::tensor_sum(x, dim = 1L)
      numeric_case(paste0(prefix, "/column_sum"), cudaverse::to_cpu(summed),
                   array(colSums(left), dim = 7L), operation_rtol, atol,
                   list(provenance = provenance(summed)))
      means <- cudaverse::tensor_mean(x, dim = 2L)
      numeric_case(paste0(prefix, "/row_mean"), cudaverse::to_cpu(means),
                   array(rowMeans(left), dim = 13L), operation_rtol, atol,
                   list(provenance = provenance(means)))
    }
    for (seed in report$parameters$seeds) {
      for (dtype in c("float32", "float64")) run_numeric(seed, dtype)
    }

    run_integer <- function() {
      values <- matrix(seq.int(-24L, 23L), 8L, 6L)
      x <- cudaverse::cuda_tensor(values, dtype = "integer", device = "cuda")
      host <- cudaverse::to_cpu(x)
      numeric_case("integer/exact_transfer", host, values, 0, 0,
                   list(dtype_preserved = identical(typeof(host), "integer")))
      logical_case("integer/transfer_dtype", identical(typeof(host), "integer"))
      summed <- cudaverse::tensor_sum(x, dim = 1L)
      numeric_case("integer/exact_sum", cudaverse::to_cpu(summed),
                   array(colSums(values), dim = 6L), 0, 0,
                   list(output_dtype = summed$dtype, provenance = provenance(summed)))
    }
    run_integer()

    run_pca <- function(seed) {
      set.seed(seed)
      values <- matrix(stats::rnorm(40L * 6L), 40L, 6L)
      x <- cudaverse::cuda_tensor(values, dtype = "float64", device = "cuda")
      fit <- cudaverse::cuda_pca(x, n_components = 3L, center = TRUE,
                                scale. = TRUE, device = "cuda")
      cpu <- stats::prcomp(values, rank. = 3L, center = TRUE, scale. = TRUE)
      prefix <- paste0("pca/", seed)
      numeric_case(paste0(prefix, "/reconstruction"),
                   fit$x %*% t(fit$rotation),
                   cpu$x[, 1:3, drop = FALSE] %*% t(cpu$rotation[, 1:3, drop = FALSE]),
                   1e-8, 0, list(seed = seed, input_shape = dim(values), components = 3L))
      numeric_case(paste0(prefix, "/subspace_projector"),
                   tcrossprod(fit$rotation), tcrossprod(cpu$rotation[, 1:3, drop = FALSE]),
                   1e-8, 0, list(provenance = provenance(fit)))
      state <- attr(fit$x, "cudaverse_native_state", exact = TRUE)
      logical_case(paste0(prefix, "/resident_scores"),
                   identical(state$backend, "native") && typeof(state$storage) == "externalptr")
    }
    for (seed in report$parameters$seeds) run_pca(seed)

    run_ties <- function() {
      values <- rbind(c(0, 0), c(0, 0), c(1, 0), c(-1, 0), c(0, 1), c(0, -1))
      n <- nrow(values)
      distances <- as.matrix(stats::dist(values))
      diag(distances) <- Inf
      k <- 4L
      indices <- t(vapply(seq_len(n), function(i) {
        order(distances[i, ], seq_len(n))[seq_len(k)]
      }, integer(k)))
      expected <- matrix(distances[cbind(rep(seq_len(n), each = k), as.vector(t(indices)))],
                         nrow = n, ncol = k, byrow = TRUE)
      for (batch in c(1L, 4L, 20L)) {
        fit <- cudaverse::cuda_knn(values, k = k, metric = "euclidean",
                                  batch_size = batch, device = "cuda")
        logical_case(paste0("stable_ties/batch_", batch, "/indices"),
                     identical(unname(fit$index), unname(indices)),
                     list(expected_indices = indices, actual_indices = fit$index,
                          ordering = "distance then original row number; self excluded",
                          provenance = provenance(fit)))
        numeric_case(paste0("stable_ties/batch_", batch, "/distances"),
                     unname(fit$distance), unname(expected), 1e-10, 0)
      }
    }
    run_ties()

    set.seed(20260907L)
    lifecycle_values <- matrix(stats::rnorm(32L * 6L), 32L, 6L)
    cycle <- function() {
      x <- cudaverse::cuda_tensor(lifecycle_values, dtype = "float64", device = "cuda")
      fit <- cudaverse::cuda_pca(x, n_components = 3L, device = "cuda")
      neighbors <- cudaverse::cuda_knn(fit$x, k = 5L, batch_size = 11L, device = "cuda")
      state <- attr(fit$x, "cudaverse_native_state", exact = TRUE)
      pca_stages <- cudaverse::cuda_provenance(fit)
      knn_stages <- cudaverse::cuda_provenance(neighbors)
      resident <- identical(state$backend, "native") && typeof(state$storage) == "externalptr" &&
        identical(state$shape, c(32L, 3L)) &&
        any(knn_stages$selection_reason == "device_resident_input")
      if (!resident || !all(pca_stages$backend == "native") ||
          !all(knn_stages$backend == "native") ||
          !identical(dim(neighbors$index), c(32L, 5L)) ||
          !all(is.finite(neighbors$distance))) {
        stop("Resident native PCA-to-kNN lifecycle contract failed.")
      }
      # Return plain stage metadata only, not tensors or objects retaining their storage.
      list(pca = pca_stages, knn = knn_stages)
    }
    for (warmup in seq_len(5L)) cycle()
    factory$synchronize()
    gc()
    factory$synchronize()
    before <- tracker(reset = TRUE)
    global_before <- device_memory()
    processes_before <- command("nvidia-smi", c("--query-compute-apps=pid,process_name,used_gpu_memory",
                                               "--format=csv,noheader,nounits"))
    checkpoints <- list()
    completed <- 0L
    sample_provenance <- NULL
    cycle_error <- tryCatch({
      for (iteration in seq_len(1000L)) {
        stages <- cycle()
        if (iteration == 1L) sample_provenance <- stages
        completed <- iteration
        if (iteration %% 100L == 0L) {
          gc()
          factory$synchronize()
          checkpoints[[length(checkpoints) + 1L]] <- list(
            iteration = iteration, allocator = tracker(), device_global = device_memory()
          )
        }
      }
      NULL
    }, error = function(error) conditionMessage(error))
    factory$synchronize()
    gc()
    factory$synchronize()
    after <- tracker()
    global_after <- device_memory()
    processes_after <- command("nvidia-smi", c("--query-compute-apps=pid,process_name,used_gpu_memory",
                                              "--format=csv,noheader,nounits"))
    delta <- after$current - before$current
    report$lifecycle <- list(
      seed = 20260907L, input_shape = dim(lifecycle_values), dtype = "float64",
      components = 3L, k = 5L, batch_size = 11L, warmups = 5L,
      iterations_required = 1000L, iterations_completed = completed,
      synchronized_and_gc = TRUE, allocator_before = before, allocator_after = after,
      allocator_delta_bytes = delta, exact_allocator_cleanup = identical(after$current, before$current),
      memory_limit_bytes = 1024^2, checkpoints = checkpoints,
      device_global_before = global_before, device_global_after = global_after,
      device_global_delta_bytes = global_after$used - global_before$used,
      device_global_measurement_scope = paste(
        "whole GPU, may include other projects; informational only,",
        "not an isolated process leak measurement"
      ),
      process_inventory_before = processes_before, process_inventory_after = processes_after,
      provenance_sample = sample_provenance, error = cycle_error,
      passed = is.null(cycle_error) && completed == 1000L &&
        abs(delta) <= 1024^2 && identical(after$current, before$current)
    )
    report$passed <- all(vapply(report$cases, function(case) isTRUE(case$passed), logical(1))) &&
      isTRUE(report$lifecycle$passed)
    NULL
  }, error = function(error) conditionMessage(error))
  report$error <- failure
  if (!is.null(failure)) report$passed <- FALSE
  report$session <- capture.output(sessionInfo())
  report$finished_at_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(report, output, pretty = TRUE, auto_unbox = TRUE,
                       digits = 16, null = "null", na = "null", force = TRUE)
  if (!isTRUE(report$passed)) stop("Supplement failed; inspect retained report: ", output)
  cat("NATIVE_CONTRACT_SUPPLEMENT=PASS\n")
}

main()
