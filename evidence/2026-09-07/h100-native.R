# Run from the exact cudaverse source checkout in the isolated R environment.
stopifnot(!requireNamespace("torch", quietly = TRUE))
stopifnot(requireNamespace("jsonlite", quietly = TRUE))
report_dir <- Sys.getenv("CUDAVERSE_VALIDATION_REPORT_DIR")
stopifnot(nzchar(report_dir))
dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
commit <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
status <- system2("git", c("status", "--porcelain"), stdout = TRUE)
stopifnot(!length(status))
smoke <- capture.output(source("tools/run-phase4-smoke.R"))
writeLines(smoke, file.path(report_dir, "native-smoke.log"))
stopifnot(any(smoke == "PHASE4_GPU_SMOKE=PASS"))
backend_options_before <- options("cudaverse.cuda_backends")
diagnostics_before <- unclass(cudaverse::cuda_diagnostics())
stopifnot(identical(diagnostics_before$selected_backend, "native"))
results <- testthat::test_local(
  ".", filter = "^native-backend$", reporter = "summary",
  stop_on_failure = FALSE, stop_on_warning = FALSE
)
backend_option_after_tests <- getOption("cudaverse.cuda_backends")
options(backend_options_before)
diagnostics_after <- unclass(cudaverse::cuda_diagnostics())
native_ready <- identical(diagnostics_after$selected_backend, "native") &&
  isTRUE(diagnostics_after$backend_diagnostics$native$self_test$passed)
expectations <- unlist(lapply(results, function(x) x$results), recursive = FALSE)
count <- function(cl) sum(vapply(expectations, inherits, logical(1), cl))
counts <- list(tests = length(results), expectations = length(expectations),
               failures = count("expectation_failure"),
               errors = count("expectation_error"),
               skips = count("expectation_skip"),
               warnings = count("expectation_warning"))
passed <- native_ready && counts$tests > 0 && counts$failures == 0 && counts$errors == 0 &&
  counts$skips == 0 && counts$warnings == 0
report <- list(
  schema = "cudaverse-h100-native-validation/1",
  time_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  commit = commit, scope = "native-backend test file and phase4 smoke",
  torch_installed = requireNamespace("torch", quietly = TRUE),
  diagnostics = diagnostics_after,
  runner_state = list(backend_option_before = backend_options_before[[1L]],
                      backend_option_after_tests = backend_option_after_tests,
                      restored = identical(getOption("cudaverse.cuda_backends"),
                                           backend_options_before[[1L]])),
  hardware = system2("nvidia-smi", c("--query-gpu=name,driver_version,memory.total",
                                    "--format=csv,noheader"), stdout = TRUE),
  session = capture.output(sessionInfo()),
  packages = as.data.frame(installed.packages()[, c("Package", "Version")]),
  tests = counts, passed = passed
)
saveRDS(report, file.path(report_dir, "native-validation.rds"))
jsonlite::write_json(report, file.path(report_dir, "native-validation.json"),
                     auto_unbox = TRUE, pretty = TRUE, null = "null")
if (!passed) stop("Native test gate failed; inspect native-validation.json")
cat("H100_NATIVE_GATE=PASS\n")
