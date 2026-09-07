# Native CUDA correctness checkpoint

These reports test core commit `2faaa385fcbc9365371476733236578baafaebae`
(cudaverse 0.4.1) and cell commit `61f7b71838f1dbc6f9fc1303b1d65f05f867850f`
(cudacellr 0.4.0) in an isolated Linux R 4.5.3 environment without torch.
They are **not** CRAN acceptance or evidence of a general performance advantage.

Subsequent testing found a case outside this checkpoint: native PCA in 0.4.1
can give identical observations slightly different scores, changing the order
of tied neighbours. A device-resident score-projection correction and exact
regression test are under development in
[PR #55](https://github.com/cudaverse/cudaverse/pull/55). The original reports
remain unchanged and should not be read as proof that every edge case passes.

| Report | Verified scope |
| --- | --- |
| h100-native-validation.json | 46 native tests; 8,592 expectations; no failures, errors, skips, or warnings; native selection after restoring test-modified options |
| h100-contract-supplement.json | 48 strict numerical cases, including float32/float64, integer exactness, sign-invariant PCA, stable ties; 1,000 complete small resident PCA-to-kNN cycles with zero tracked allocator growth |
| h100-native-session.json | Two distinct R sessions, injected out-of-memory recovery, zero final tracked allocations, clean process exits |
| h100-single-cell-parity.json | Three seeded CPU/native workflows, exact neighbour indices, elementwise distance tolerances, source commits and installed-file hashes |
| h100-install-size.json | Observed allocated disk usage; the R packages are measured separately from the complete test environment |

The H100 was shared with existing applications. Whole-device memory is recorded
but cannot be attributed solely to this process. Retained timing benchmarks
must wait for an idle GPU. Current R-release/R-devel and platform CI provide
separate evidence; these Linux R 4.5.3 tests do not replace those checks.

The public supplement omits process names and identifiers from its two GPU
inventories. Counts and memory measurements are unchanged; the unredacted
original is retained locally. Other report fields are unchanged.

## Reproduction

`h100-linux-64.lock` pins 142 upstream archives with SHA-256 checksums; replay
with micromamba 2.9.0 (`micromamba create -p /absolute/env -f h100-linux-64.lock`).
It installs R, compilers, CUDA libraries and test dependencies, not torch or
LibTorch. It contains archive references, not bundled vendor binaries.

Check out the exact commits above and install core then cell with `R CMD INSTALL`
inside that environment. Run scripts with `Rscript --vanilla`. The native scripts
run from the clean core checkout and require `CUDAVERSE_NATIVE_TESTS=true` plus
the output variable documented in each script. Set `CUDAVERSE_CUSOLVER_PATH` to
the environment's `lib/libcusolver.so.11`.

The single-cell script records source checkouts at
`/home/exouser/cudaverse-validation/{cudaverse,cudacellr}`; preserve those paths
or deliberately adapt them for another machine. It uses `CUDAVERSE_CELL_REPORT`
for its output path. The session report comes from the frozen core's
`tools/run-native-session-contract.R SOURCE_PATH REPORT_PATH`.

The submitted tarball SHA-256 is
`a6c4cc0c8a35de6d148f502b257158f4d91d5cd0827913f726fdfb0c0847f1ab`.
The original v0.4.1 release attachment predates that amended submission; see
the release notes for the distinction. No new CRAN submission accompanies
these reports.

Run `Rscript verify-evidence.R .` with jsonlite and digest installed to verify
the bundle checksums and key reported acceptance conditions.
