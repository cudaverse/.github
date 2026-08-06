args <- commandArgs(trailingOnly = TRUE)
publishable <- "--publishable" %in% args
paths <- setdiff(args, "--publishable")

if (length(paths) != 1L) {
  stop(
    "Usage: Rscript scripts/validate-benchmark.R RESULT.json [--publishable]",
    call. = FALSE
  )
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The jsonlite package is required.", call. = FALSE)
}

path <- normalizePath(paths[[1L]], mustWork = TRUE)
record <- jsonlite::fromJSON(path, simplifyVector = FALSE)

fail <- function(location, message) {
  stop(location, ": ", message, call. = FALSE)
}
field <- function(object, name, location) {
  if (!is.list(object) || !(name %in% names(object))) {
    fail(location, paste0("missing required field `", name, "`"))
  }
  object[[name]]
}
scalar_string <- function(value, location) {
  if (!is.character(value) || length(value) != 1L || is.na(value) ||
      !nzchar(value)) {
    fail(location, "must be one non-empty string")
  }
  invisible(value)
}
scalar_logical <- function(value, location) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    fail(location, "must be one boolean")
  }
  invisible(value)
}
scalar_number <- function(value, location, minimum = 0) {
  if (!is.numeric(value) || length(value) != 1L || is.na(value) ||
      !is.finite(value) || value < minimum) {
    fail(location, paste0("must be one finite number >= ", minimum))
  }
  invisible(value)
}
scalar_integer <- function(value, location, minimum = 1) {
  value <- scalar_number(value, location, minimum)
  if (value != floor(value)) {
    fail(location, "must be an integer")
  }
  invisible(value)
}
expect_value <- function(value, expected, location) {
  if (!identical(value, expected)) {
    fail(location, paste0("must equal `", expected, "`"))
  }
}

expect_value(
  scalar_string(field(record, "schema_version", "$"), "$.schema_version"),
  "cudaverse-benchmark/1",
  "$.schema_version"
)
status <- scalar_string(
  field(record, "evidence_status", "$"),
  "$.evidence_status"
)
if (!(status %in% c("example", "measured"))) {
  fail("$.evidence_status", "must be `example` or `measured`")
}
scalar_string(field(record, "benchmark_id", "$"), "$.benchmark_id")
recorded_at <- scalar_string(
  field(record, "recorded_at", "$"),
  "$.recorded_at"
)
if (!grepl(
  "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?Z$",
  recorded_at
)) {
  fail("$.recorded_at", "must be a UTC RFC 3339 timestamp ending in Z")
}

sources <- field(record, "sources", "$")
if (!is.list(sources) || !length(sources)) {
  fail("$.sources", "must contain at least one source")
}
for (i in seq_along(sources)) {
  location <- paste0("$.sources[", i, "]")
  repository <- scalar_string(
    field(sources[[i]], "repository", location),
    paste0(location, ".repository")
  )
  if (!grepl("^cudaverse/[A-Za-z0-9._-]+$", repository)) {
    fail(paste0(location, ".repository"), "must name a cudaverse repository")
  }
  commit <- scalar_string(
    field(sources[[i]], "commit", location),
    paste0(location, ".commit")
  )
  if (!grepl("^[0-9a-f]{40}([0-9a-f]{24})?$", commit)) {
    fail(paste0(location, ".commit"), "must be a full 40- or 64-hex Git ID")
  }
  scalar_logical(
    field(sources[[i]], "dirty", location),
    paste0(location, ".dirty")
  )
}

environment <- field(record, "environment", "$")
scalar_string(
  field(environment, "hardware_label", "$.environment"),
  "$.environment.hardware_label"
)
scalar_string(field(environment, "os", "$.environment"), "$.environment.os")
scalar_string(
  field(environment, "architecture", "$.environment"),
  "$.environment.architecture"
)
cpu <- field(environment, "cpu", "$.environment")
scalar_string(field(cpu, "model", "$.environment.cpu"), "$.environment.cpu.model")
scalar_integer(
  field(cpu, "logical_cores", "$.environment.cpu"),
  "$.environment.cpu.logical_cores"
)
scalar_integer(
  field(environment, "memory_bytes", "$.environment"),
  "$.environment.memory_bytes"
)
gpu <- field(environment, "gpu", "$.environment")
scalar_string(field(gpu, "model", "$.environment.gpu"), "$.environment.gpu.model")
scalar_integer(field(gpu, "count", "$.environment.gpu"), "$.environment.gpu.count")
scalar_integer(
  field(gpu, "memory_bytes", "$.environment.gpu"),
  "$.environment.gpu.memory_bytes"
)
software <- field(environment, "software", "$.environment")
for (name in c("r_version", "cuda_driver", "cuda_runtime")) {
  scalar_string(
    field(software, name, "$.environment.software"),
    paste0("$.environment.software.", name)
  )
}
versions <- field(software, "package_versions", "$.environment.software")
if (!is.list(versions) || !length(versions)) {
  fail("$.environment.software.package_versions", "must not be empty")
}
invisible(lapply(
  seq_along(versions),
  function(i) scalar_string(
    versions[[i]],
    paste0("$.environment.software.package_versions.", names(versions)[[i]])
  )
))

workload <- field(record, "workload", "$")
scalar_string(field(workload, "name", "$.workload"), "$.workload.name")
category <- scalar_string(
  field(workload, "category", "$.workload"),
  "$.workload.category"
)
allowed_categories <- c(
  "dense", "sparse", "learning", "single-cell", "graph", "embedding"
)
if (!(category %in% allowed_categories)) {
  fail("$.workload.category", "uses an unsupported category")
}
scalar_integer(field(workload, "seed", "$.workload"), "$.workload.seed", -2147483648)
scalar_string(field(workload, "dtype", "$.workload"), "$.workload.dtype")
dimensions <- unlist(field(workload, "dimensions", "$.workload"), use.names = FALSE)
if (!length(dimensions) || any(!is.finite(dimensions)) ||
    any(dimensions < 1) || any(dimensions != floor(dimensions))) {
  fail("$.workload.dimensions", "must contain positive integers")
}
parameters <- field(workload, "parameters", "$.workload")
if (!is.list(parameters)) {
  fail("$.workload.parameters", "must be an object")
}

correctness <- field(record, "correctness", "$")
if (!isTRUE(scalar_logical(
  field(correctness, "passed", "$.correctness"),
  "$.correctness.passed"
))) {
  fail("$.correctness.passed", "must be true before timing is evidence")
}
for (name in c("reference_backend", "comparison")) {
  scalar_string(
    field(correctness, name, "$.correctness"),
    paste0("$.correctness.", name)
  )
}
scalar_number(
  field(correctness, "tolerance", "$.correctness"),
  "$.correctness.tolerance"
)
scalar_number(
  field(correctness, "max_abs_error", "$.correctness"),
  "$.correctness.max_abs_error"
)

timing <- field(record, "timing", "$")
expect_value(
  scalar_string(field(timing, "clock", "$.timing"), "$.timing.clock"),
  "elapsed_wall",
  "$.timing.clock"
)
scalar_integer(
  field(timing, "warmup_iterations", "$.timing"),
  "$.timing.warmup_iterations"
)
iterations <- scalar_integer(
  field(timing, "measured_iterations", "$.timing"),
  "$.timing.measured_iterations",
  3
)
if (!isTRUE(scalar_logical(
  field(timing, "cuda_synchronized", "$.timing"),
  "$.timing.cuda_synchronized"
))) {
  fail("$.timing.cuda_synchronized", "must be true")
}
transfer <- scalar_string(
  field(timing, "transfer_policy", "$.timing"),
  "$.timing.transfer_policy"
)
if (!(transfer %in% c("included", "excluded", "separate", "not_applicable"))) {
  fail("$.timing.transfer_policy", "uses an unsupported policy")
}

measurements <- field(record, "measurements", "$")
if (!is.list(measurements) || length(measurements) < 2L) {
  fail("$.measurements", "must contain at least two series")
}
elapsed_devices <- character()
keys <- character()
for (i in seq_along(measurements)) {
  measurement <- measurements[[i]]
  location <- paste0("$.measurements[", i, "]")
  implementation <- scalar_string(
    field(measurement, "implementation", location),
    paste0(location, ".implementation")
  )
  device <- scalar_string(
    field(measurement, "device", location),
    paste0(location, ".device")
  )
  if (!(device %in% c("cpu", "cuda", "hybrid"))) {
    fail(paste0(location, ".device"), "uses an unsupported device")
  }
  metric <- scalar_string(
    field(measurement, "metric", location),
    paste0(location, ".metric")
  )
  if (!(metric %in% c("elapsed_seconds", "throughput", "peak_memory_bytes"))) {
    fail(paste0(location, ".metric"), "uses an unsupported metric")
  }
  scalar_string(field(measurement, "unit", location), paste0(location, ".unit"))
  values <- unlist(field(measurement, "values", location), use.names = FALSE)
  if (!length(values) || !is.numeric(values) || any(!is.finite(values)) ||
      any(values < 0)) {
    fail(paste0(location, ".values"), "must contain finite non-negative numbers")
  }
  if (metric == "elapsed_seconds") {
    if (length(values) != iterations) {
      fail(paste0(location, ".values"), "must contain measured_iterations values")
    }
    elapsed_devices <- c(elapsed_devices, device)
  }
  key <- paste(implementation, device, metric, sep = "/")
  if (key %in% keys) {
    fail(location, paste0("duplicates measurement series `", key, "`"))
  }
  keys <- c(keys, key)
  summary <- field(measurement, "summary", location)
  expected <- c(
    count = length(values),
    minimum = min(values),
    median = stats::median(values),
    maximum = max(values)
  )
  actual <- c(
    count = scalar_integer(
      field(summary, "count", paste0(location, ".summary")),
      paste0(location, ".summary.count")
    ),
    minimum = scalar_number(
      field(summary, "minimum", paste0(location, ".summary")),
      paste0(location, ".summary.minimum")
    ),
    median = scalar_number(
      field(summary, "median", paste0(location, ".summary")),
      paste0(location, ".summary.median")
    ),
    maximum = scalar_number(
      field(summary, "maximum", paste0(location, ".summary")),
      paste0(location, ".summary.maximum")
    )
  )
  if (!isTRUE(all.equal(actual, expected, tolerance = 1e-12))) {
    fail(paste0(location, ".summary"), "does not match the raw values")
  }
}
if (!("cpu" %in% elapsed_devices) || !("cuda" %in% elapsed_devices)) {
  fail("$.measurements", "must include CPU and CUDA elapsed_seconds series")
}

claims <- field(record, "claims", "$")
publication_ready <- scalar_logical(
  field(claims, "publication_ready", "$.claims"),
  "$.claims.publication_ready"
)
scalar_string(field(claims, "scope", "$.claims"), "$.claims.scope")
if (!("break_even" %in% names(claims))) {
  fail("$.claims", "missing required field `break_even`")
}
if (!is.null(claims$break_even)) {
  scalar_string(claims$break_even, "$.claims.break_even")
}

if (publishable) {
  if (!identical(status, "measured")) {
    fail("$.evidence_status", "must be `measured` for publication")
  }
  if (!isTRUE(publication_ready)) {
    fail("$.claims.publication_ready", "must be true for publication")
  }
  dirty <- vapply(sources, function(source) isTRUE(source$dirty), logical(1))
  if (any(dirty)) {
    fail("$.sources", "publishable evidence cannot use a dirty source tree")
  }
}

cat(
  "Valid cudaverse benchmark evidence:",
  basename(path),
  if (publishable) "(publishable)" else paste0("(", status, ")"),
  "\n"
)
