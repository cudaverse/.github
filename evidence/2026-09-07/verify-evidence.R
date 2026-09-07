args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1L]] else "."
stopifnot(requireNamespace("jsonlite", quietly = TRUE),
          requireNamespace("digest", quietly = TRUE))
read_report <- function(name) jsonlite::read_json(file.path(root, name))
manifest <- read_report("SHA256SUMS.json")
expected_files <- vapply(manifest$files, `[[`, character(1), "file")
actual_files <- list.files(root, all.files = FALSE, recursive = FALSE)
stopifnot(setequal(expected_files, setdiff(actual_files, "SHA256SUMS.json")),
          !anyDuplicated(expected_files))
for (entry in manifest$files) {
  stopifnot(identical(basename(entry$file), entry$file))
  path <- file.path(root, entry$file)
  stopifnot(file.exists(path), identical(digest::digest(file = path, algo = "sha256"),
                                       entry$sha256))
}
core_commit <- "2faaa385fcbc9365371476733236578baafaebae"
cell_commit <- "61f7b71838f1dbc6f9fc1303b1d65f05f867850f"
native <- read_report("h100-native-validation.json")
stopifnot(isTRUE(native$passed), identical(native$commit, core_commit),
          identical(native$torch_installed, FALSE),
          identical(native$diagnostics$selected_backend, "native"),
          isTRUE(native$runner_state$restored), native$tests$tests == 46,
          native$tests$expectations == 8592,
          all(unlist(native$tests[c("failures", "errors", "skips", "warnings")]) == 0))
supplement <- read_report("h100-contract-supplement.json")
stopifnot(isTRUE(supplement$passed), identical(supplement$source$commit, core_commit),
          isTRUE(supplement$source$clean), length(supplement$cases) == 48,
          all(vapply(supplement$cases, function(x) isTRUE(x$passed), logical(1))),
          supplement$lifecycle$iterations_completed == 1000,
          supplement$lifecycle$allocator_delta_bytes == 0,
          isTRUE(supplement$lifecycle$exact_allocator_cleanup))
session <- read_report("h100-native-session.json")
stopifnot(isTRUE(session$passed), identical(session$source$commit, core_commit),
          isTRUE(session$contract$distinct_processes), length(session$sessions) == 2,
          all(vapply(session$sessions, function(x) isTRUE(x$process_absent_after_exit) &&
                       x$baseline_bytes == x$final_bytes, logical(1))))
cell <- read_report("h100-single-cell-parity.json")
stopifnot(isTRUE(cell$passed), identical(cell$torch_installed, FALSE),
          identical(cell$sources$cudaverse$commit, core_commit),
          identical(cell$sources$cudacellr$commit, cell_commit), length(cell$seeds) == 3,
          all(vapply(cell$seeds, function(x) isTRUE(x$neighbors_identical) &&
                       x$max_error_to_limit_ratio <= 1, logical(1))))
cat("EVIDENCE_BUNDLE=PASS (correctness only; not a timing or CRAN-acceptance gate)\n")
