stopifnot(!requireNamespace("torch", quietly = TRUE))
library(cudacellr)
library(cudaverse)
source_state <- function(path) {
  stopifnot(dir.exists(path))
  changes <- system2("git", c("-C", shQuote(path), "status", "--porcelain"),
                     stdout = TRUE)
  stopifnot(!length(changes))
  list(commit = system2("git", c("-C", shQuote(path), "rev-parse", "HEAD"),
                        stdout = TRUE), clean = TRUE)
}
source_roots <- c(cudaverse = "/home/exouser/cudaverse-validation/cudaverse",
                  cudacellr = "/home/exouser/cudaverse-validation/cudacellr")
sources <- lapply(source_roots, source_state)
installed_hashes <- lapply(names(source_roots), function(pkg) {
  files <- list.files(system.file(package = pkg), recursive = TRUE,
                      full.names = TRUE)
  system2("sha256sum", shQuote(files), stdout = TRUE)
})
names(installed_hashes) <- names(source_roots)
results <- lapply(c(1L, 42L, 2026L), function(seed) {
  set.seed(seed)
  counts <- matrix(rpois(200 * 100, 3), 200, 100,
                   dimnames = list(paste0("gene", 1:200), paste0("cell", 1:100)))
  run <- function(device) cudacell_workflow(
    counts, n_hvg = 100, n_components = 15, k = 15,
    batch_size = 23, device = device
  )
  cpu <- run("cpu")
  gpu <- run("cuda")
  stopifnot(identical(cpu$neighbors$index, gpu$neighbors$index))
  error <- abs(cpu$neighbors$distance - gpu$neighbors$distance)
  limit <- 1e-10 + 1e-8 * abs(cpu$neighbors$distance)
  stopifnot(all(is.finite(error)), all(error <= limit))
  stopifnot(identical(rownames(gpu$pca$x), colnames(counts)))
  stages <- cuda_provenance(gpu)
  stopifnot(any(stages$backend == "native"))
  list(seed = seed, neighbors_identical = TRUE,
       max_distance_error = max(error), rtol = 1e-8, atol = 1e-10,
       max_error_to_limit_ratio = max(error / limit),
       provenance = stages)
})
report <- list(passed = TRUE, scope = "single-cell CPU/native workflow parity",
               time_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
               sources = sources, installed_file_sha256 = installed_hashes,
               torch_installed = requireNamespace("torch", quietly = TRUE),
               cudaverse = as.character(packageVersion("cudaverse")),
               cudacellr = as.character(packageVersion("cudacellr")),
               seeds = results, session = capture.output(sessionInfo()))
jsonlite::write_json(report, Sys.getenv("CUDAVERSE_CELL_REPORT"),
                     pretty = TRUE, auto_unbox = TRUE, force = TRUE)
cat("H100_SINGLE_CELL_PARITY=PASS\n")
