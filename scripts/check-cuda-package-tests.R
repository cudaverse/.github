package_names <- c(
  "cudatensr",
  "cudasparsr",
  "cudalearnr",
  "cudacellr",
  "cudagraphR",
  "cudaembedr"
)
required_packages <- c(
  package_names,
  "testthat",
  "torch"
)
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages)) {
  stop(
    "CUDA package tests require installed packages: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

if (!identical(
  tolower(Sys.getenv("CUDAVERSE_REQUIRE_CUDA", unset = "false")),
  "true"
)) {
  stop(
    "CUDA package tests require CUDAVERSE_REQUIRE_CUDA=true.",
    call. = FALSE
  )
}

diagnostics <- cudatensr::cuda_diagnostics()
if (!isTRUE(diagnostics$cuda_available) ||
    is.na(diagnostics$cuda_device_count) ||
    diagnostics$cuda_device_count < 1L) {
  stop(
    "CUDA package tests require a usable physical CUDA device.",
    call. = FALSE
  )
}

package_paths <- file.path("packages", package_names)
missing_paths <- package_paths[!dir.exists(package_paths)]
if (length(missing_paths)) {
  stop(
    "CUDA package source directories are missing: ",
    paste(missing_paths, collapse = ", "),
    call. = FALSE
  )
}

collect_expectations <- function(results) {
  unlist(
    lapply(results, function(result) result$results),
    recursive = FALSE,
    use.names = FALSE
  )
}

for (index in seq_along(package_names)) {
  package_name <- package_names[[index]]
  package_path <- package_paths[[index]]
  cat("Running package-owned tests for ", package_name, "...\n", sep = "")
  results <- testthat::test_local(
    package_path,
    reporter = "summary",
    stop_on_failure = TRUE
  )
  if (!length(results)) {
    stop(
      "No package-owned tests ran for ",
      package_name,
      ".",
      call. = FALSE
    )
  }
  expectations <- collect_expectations(results)
  skipped <- Filter(
    function(expectation) inherits(expectation, "expectation_skip"),
    expectations
  )
  if (length(skipped)) {
    reasons <- unique(vapply(
      skipped,
      conditionMessage,
      character(1)
    ))
    stop(
      "CUDA hardware coverage cannot treat skipped package tests as passing (",
      package_name,
      "): ",
      paste(reasons, collapse = "; "),
      call. = FALSE
    )
  }
}

cat("All package-owned testthat suites passed without skips.\n")
