# Development validation checkpoint

This October 10 checkpoint, updated through October 13, records the
[PR #55](https://github.com/cudaverse/cudaverse/pull/55) assessment, its stacked
corrections and documentation integration. Core main now contains development
version 0.4.1.9000. Core 0.4.1 remains published on CRAN; no new package release
is established, and the companion upload is awaiting email confirmation.

| Source | Exact commit | Scope |
| --- | --- | --- |
| Initial core | `0c74a44a972329dea8e4926727fb70f3f947a1f7` | 0.4.1.9000 correctness and diagnostic baseline |
| Original full candidate | `2c2b569a2b503478d1141ddc6fd7f2276ff866af` | Shared-GPU contract; full core run failed distance parity |
| Corrected candidate | `5754739cfc09d730322bf7a9ea4d5d6ae02b8245` | Full core, precision and single-cell passed under the disclosed policies |
| Summary correction | `8616084ec1d37e35463cfc8596837fa3b920922d` | Exact integer diagnostic counts; package runtime unchanged |
| Combined documentation PR | `a6d3ee9ae703636230ebe4ea46af26587609c430` | Fresh PR checks; tree matches final core main |
| Integrated core main | `f93361d40d3b6f035b1494cfb968de679b165cd6` | 0.4.1.9000; final main CI and deployed-page verification passed |
| Companion | `02a5b1e130aaf5e8d3db4d6e65bba6eed74bfa40` | cudacellr 0.4.0 |

The hardware-measured core revisions (`0c74a44`, `2c2b569` and `5754739`) and
the companion were installed from clean exact sources into isolated Linux R
libraries on an A100 SXM4 40 GB with R 4.3.3 and no torch.
Source archives, installation manifests and reports identify source revisions
and installed-file fingerprints. Raw evidence remains retained outside package
source trees. This summary does not replace the raw reports or their gates.

## Approved precision and execution policy

The maintainer approved standard FP32 by default, explicit per-call TF32 and
existing FP64 on September 26. Standard FP32 benchmarks use a stated
componentwise arithmetic model while preserving the original strict comparison
and its failed-entry counts. TF32 has a separate model and exact controls.
These models do not establish accuracy for every scientific application.

The maintainer subsequently authorized the full workload sequence while the
A100 remains shared with other applications. Explicit shared mode preserves
case sizes, five warmups, ten measured samples, numerical checks, exact-source
installation checks and cudaverse-owned allocation cleanup. GPU inventories
remain mandatory; malformed or unavailable inventories fail. Observed sharing
is permitted and retained in the reports. It cannot establish uncontended
speedups, even when an individual snapshot happens to show an idle device.

## Completed evidence

At exact `0c74a44`, the shared A100 completed:

- Two installed native-backend/TF32 test files: 49 tests and 8,626 expectations,
  with no failures, errors, warnings or skips and zero final tracked allocation.
- Four base/native core smoke cases and the machine-readable report gate.
- Five precision fixtures in each of standard FP32, explicit TF32 and FP64,
  including per-call isolation and allocation cleanup.
- CPU/native single-cell smoke correctness with exact neighbour indices,
  passing distance/PCA checks, actual native computation and no fallback.

The native result covers those two test files, not the whole package suite.
Source and installation identities were verified for the relevant runs. These
smoke and diagnostic results do not substitute for the full workload sequence.

At exact `2c2b569`, shared-mode helper regression checks passed and independent
review found no blocking implementation defect. Shared single-cell smoke
benchmarking passed, including fresh child-process identity, five warmups and
ten samples. Its report labels shared execution and excludes uncontended
performance eligibility.

The full shared A100 precision experiment subsequently passed at `2c2b569`:
six fixtures (two exact controls and 64/256/1024/4096-square products), three
precision modes and both resident and host-boundary scopes. Each scope retained
five warmups and ten measured samples, totaling 360 measurements. All numerical
model, shape/dtype, provenance, precision-isolation and repeated-value checks
passed. All owned-allocation cleanup deltas were zero. Source and installation
identities were unchanged, and all 1,166 GPU observations recorded sharing.

At 4096, maximum absolute errors were approximately 0.000958 for standard FP32
and 0.1071 for permitted TF32. The original strict comparison still failed
638,414 and 16,413,669 elements respectively; those counts remain in the raw
report alongside the accepted model results. Shared timings remain descriptive
and do not establish uncontended performance.

An independent Windows R 4.6.1 / RTX 2000 Ada installation of the same source
passed the full installed package suite: 235 tests and 9,970 expectations across
20 files, with zero failures, errors, warnings or skips. Native tests were
enabled, source/installation fingerprints stayed unchanged, and native tracked
allocation returned to zero. This full-suite result is separate from the
preserved A100 diagnostic failure below.

The candidate's four-platform [R check matrix](https://github.com/cudaverse/cudaverse/actions/runs/38099228302),
[native integrity](https://github.com/cudaverse/cudaverse/actions/runs/38099228307),
[CPU integration](https://github.com/cudaverse/cudaverse/actions/runs/38099228517)
and [documentation build](https://github.com/cudaverse/cudaverse/actions/runs/38099228319)
passed. The PR did not deploy Pages; optional hardware CI skipped. The separate
[full manual/readiness run](https://github.com/cudaverse/cudaverse/actions/runs/38099232218)
also passed at exact `2c2b569`: zero errors, zero warnings and one NOTE for the
development version number 0.4.1.9000. Tests, rebuilt vignettes and PDF/HTML
manuals passed. The retained source candidate matches the transferred artifact,
with SHA-256 `b0f2905378a4ada39dc35a1366d203f3f66838d19abd5b03c3c22f3adc87879f`.

## Preserved failed diagnostic

The fresh `2c2b569` installation's native diagnostic had one failure in 8,626
expectations. The k-means recovery test's whole-device memory assertion observed
an absolute change of 10,713,890,816 bytes, exceeding its 1 MiB threshold.
The adjacent cudaverse-owned allocation equality passed, final tracked bytes
were zero, and before/after installation fingerprints verified. The other
8,625 expectations passed, with no errors, warnings or skips.

Whole-device memory includes other applications and CUDA library allocations.
Competing compute processes changed during this run, supporting external
activity as an explanation without proving attribution during the assertion
interval. This remains a failed diagnostic; it is not relabelled as an all-pass
suite. Package R, C++ and test files are unchanged from the passing `0c74a44`
run. The observations do not rule out untracked or library allocations.

## Full core failure and corrected candidate

The original full core sequence at `2c2b569` exited with status 1 after timing
all twelve cases. Final sparse-50000x128 numerical parity failed for six native
kNN distances: maximum absolute error 1.6313176432589571e-10 and maximum
pointwise tolerance ratio 1.62675440799739, with unchanged rtol 1e-8 and atol
1e-10. Exact neighbor indices, normalization and PCA checks passed; native
tracked cleanup delta was zero. The full single-cell stage did not start.
The failed raw report and log remain retained; completed timings do not turn
this into a passing benchmark.

Diagnosis reproduced cancellation using identical CPU PCA scores and an
independent analytic close-vector fixture. [PR #57](https://github.com/cudaverse/cudaverse/pull/57)
uses the CPU path's dimension-aware guard and recomputes risky pairs from
scaled coordinate differences. The analytic regression has three failures on
the original kernel and five passing assertions on the corrected exact-source
installation. A patched-PTX diagnostic of the original full-size fixture also
passes unchanged tolerances and exact indices; it does not replace the full run.

At `5754739`, [native integrity](https://github.com/cudaverse/cudaverse/actions/runs/38124095924)
and [CPU integration](https://github.com/cudaverse/cudaverse/actions/runs/38124096207)
passed. CI reproduced the committed PTX byte for byte with CUDA 12.8.1.
The exact corrected source also passed the full Windows R 4.6.1 / RTX 2000 Ada
installed suite: 236 tests, 9,975 assertions, zero failures, errors, warnings
or skips. Source and installation fingerprints remained unchanged, native
tracked allocations returned to zero, and peak tracked allocation was
6,665,596 bytes. The report SHA-256 is
`a45802aeead4fcc09120f7c73d2732cc341c27e99231a026ed260df684ab5e54`.

Its full shared-A100 precision experiment passed all six cases, three modes
and two scopes, retaining five warmups and 360 measured samples. Numerical,
metadata, repeated-value, source/install and owned-memory checks passed; final
tracked allocation was zero and peak was 805,306,368 bytes. Shared execution
remains ineligible for uncontended performance claims. Report SHA-256:
`82b663a059cb8adcc1c4fe189d8a794a1a8a4dd09c81245610e29e3990376de9`.

The corrected source's [R matrix](https://github.com/cudaverse/cudaverse/actions/runs/38124095903)
and [documentation build](https://github.com/cudaverse/cudaverse/actions/runs/38124095889)
passed. All four R platforms reported Status: OK, 1,242 passing assertions,
58 skips and no failures; the two Linux logs retain one optional
SummarizedExperiment duplicate-import warning each. These CI jobs provide no
GPU coverage. [Full readiness](https://github.com/cudaverse/cudaverse/actions/runs/38124167593)
passed with zero errors, zero warnings and one NOTE for development version
0.4.1.9000. Tests, rebuilt vignettes and PDF/HTML manual checks passed. The
transferred source artifact matches the builder's SHA-256:
`9d85a539d0ee754ff64fdc1a0380df6134d2a8db88f82d4b5d1b8f125ffffab1`.

The full core workload at exact `5754739` passed all machine-readable gates:
twelve cases on both base and native backends, full sizes, five warmups and ten
measured samples per timing scope. All native tracked cleanup deltas were zero.
The 50,000-row sparse fixture retained exact neighbor indices and had zero
failed distance elements, with maximum tolerance ratio 0.09556544316062524
under the unchanged rtol 1e-8 and atol 1e-10. Raw report SHA-256:
`2813292f8ebc885d0c0ae8b5fed25e1609f717621779f5616e45338e7f02029e`.

The sequence subsequently exited 1 because its summary rounded three strict
FP32 diagnostic failure counts. The original raw report, rejected summary and
verifier log are preserved. [PR #58](https://github.com/cudaverse/cudaverse/pull/58)
at `8616084` prints exact integer counts; its regression tests and the unchanged
summary verifier pass against the retained full report. It changes only the
summary renderer and its tests. Hardware measurements retain source identity
`5754739`; the verification record separately identifies renderer `8616084`.

The original sequence had not started full single-cell benchmarking. A separate
continuation ran the full CPU/native contract on the same exact source
installations. An initial continuation with omitted mode/backend settings was
terminated and retained as an aborted startup, not benchmark evidence. The
corrected process environment explicitly selected full benchmark mode and both
backends. No external GPU client was stopped.

That continuation exited 1 at the 10,000-cell native PCA reconstruction gate:
32 of 800,000 entries failed rtol 1e-8 with zero absolute tolerance, with maximum
absolute difference 4.722888746755416e-12. Neighbor indices, distances, PCA
subspace, backend and fresh-process parity passed. The 50,000-cell case did not
start; the failing backend's allocation measurement and final installation
verification were not reached. Failed report SHA-256:
`69dfd663381d64b6bb07808e03997126c3322749df8bddea59254b3e32529af6`.

A separate diagnostic reproduces the same 32 failures and verifies unchanged
source installations. Reconstructing from CPU QR followed by SVD also fails
seven entries against the original CPU result. Native-versus-CPU relative
Frobenius difference is 6.9342e-13; CPU-QR-versus-CPU is 1.4526e-13. This supports
near-zero comparison sensitivity rather than a demonstrated runtime defect.
[LAPACK's SVD analysis](https://netlib.org/lapack/lug/node97.html) describes
normwise backward stability and singular-vector sensitivity; it does not
guarantee relative accuracy in every near-zero reconstructed entry.

The separate benchmark harness now records policy
`core-fp64-reconstruction-parity/1`: pointwise reconstruction rtol 1e-8 and
atol 1e-10, matching the existing core FP64 reconstruction criterion. This is
an explicit acceptance-policy revision, not an unchanged-tolerance pass or a
universal SVD error bound. Each result retains the original relative-only
diagnostic and its failure count. Neighbor gates are unchanged.
Windows/Linux helper tests cover near-zero comparisons and rejection of isolated
errors; the cached fixture passes the revised criterion while retaining all
32 original failures. The original failed report remains failed.

A separate PCA-only check of the identical 50,000-cell input found two entries
failing the original relative-only subspace check (maximum absolute difference
6.06820149684495e-12). Reconstruction passed the revised criterion and retained
1,526 original strict failures. The reconstruction-only rerun was deliberately
stopped during its own fresh CPU worker after this finding; its partial results
are preserved and do not establish full validation. Both smaller cases had
passed that attempt with zero tracked cleanup deltas.

The harness now also records `core-fp64-projector-parity/1`: pointwise projector
rtol 0 and atol 1e-8, matching the existing core projector check. Its original
relative-only diagnostic remains visible. The cached 50,000-cell PCA results
pass both disclosed criteria while retaining the two subspace and 1,526
reconstruction strict failures. Windows/Linux helper tests pass, including
isolated-error rejection. These diagnostics do not replace the full workflow,
identity and memory gates.

## Completed full single-cell rerun (2026-10-13)

The fresh full CPU/native run completed at 2026-10-13 04:05:29 UTC with driver
exit status 0. All three cases (1,000 cells by 50 features, 10,000 by 100 and
50,000 by 128) passed, retaining five warmups and ten measured samples for each
backend: 60 measured samples in total. This pass uses both disclosed PCA
policy revisions above; it does not change the status of the original failed
or deliberately stopped attempts.

All cases retain exact selected features, normalized values, cell identifiers
and neighbor indices. Neighbor distances pass the unchanged rtol 1e-8, atol 0
criterion. Parent workflows pass the revised PCA reconstruction and projector
checks. Fresh-process parity covers neighbor indices/distances, actual backend
provenance and source/install identity; the parent workflow carries the PCA,
normalization and feature parity checks. Requested computational backends were
used without fallback. All native owned-allocation cleanup deltas were zero.
CPU peak RSS and continuous whole-device peak VRAM remain unavailable; the
recorded native allocator peaks cover cudaverse-owned allocations only.

The final report retains the original relative-only PCA diagnostics:

| Native case | Reconstruction failed entries | Projector failed entries |
| --- | ---: | ---: |
| 1,000 cells by 50 features | 0 / 40,000 | 0 / 1,600 |
| 10,000 cells by 100 features | 32 / 800,000 | 0 / 6,400 |
| 50,000 cells by 128 features | 1,526 / 5,100,000 | 2 / 10,404 |

The original strict criteria have rtol 1e-8 and atol 0. At 50,000 cells, maximum
absolute differences are 3.7778224992734977e-11 for reconstruction and
6.0682014968449494e-12 for the projector. All CPU strict diagnostics pass.
The accepted pointwise criteria remain reconstruction rtol 1e-8, atol 1e-10 and
projector rtol 0, atol 1e-8; neither is a universal SVD accuracy guarantee.

Before/after verification confirms unchanged core `5754739` and companion
`02a5b1e` sources and installed payloads, including the fresh worker processes.
Terminal process inspection confirmed that the driver and parent R process had
exited. All 12 downloaded evidence files match fresh remote SHA-256 values;
all nine pinned driver/harness script hashes remained unchanged through the
run. The retained offline and external verification records are
`single-cell-pca-v2-terminal-verification.json` and
`single-cell-pca-v2-terminal-external-verification.json`. The offline verifier
checks the report, journal and driver contract; it does not recompute numerical
results from raw workflow arrays. The complete report is
`single-cell-full-pca-v2-5754739cfc09d730322bf7a9ea4d5d6ae02b8245/single-cell-full.json`,
with SHA-256
`b4a4c72002b248e7dd177ba9c4815907e6bb47f2c7d4993ff16fb4d339ac3635`.

The report records shared execution and no eligibility for uncontended
performance claims. Completion of these candidate gates does not establish
integration, deployment, a release or CRAN acceptance.

## Summary correction CI

At summary-only commit `8616084`, [R checks](https://github.com/cudaverse/cudaverse/actions/runs/38332237681),
[native integrity](https://github.com/cudaverse/cudaverse/actions/runs/38332237606),
[integration](https://github.com/cudaverse/cudaverse/actions/runs/38332238207)
and [documentation build](https://github.com/cudaverse/cudaverse/actions/runs/38332237707)
passed. All four R checks report Status: OK, 1,242 passing assertions and 58
skips; each Linux log retains the optional duplicate-import warning described
above. Summary positive/rejection tests pass, and PTX reproducibility is verified.

## Source integration (2026-10-13)

The reviewed changes were integrated in sequence:

| Pull request | Merge commit | Result |
| --- | --- | --- |
| [#58](https://github.com/cudaverse/cudaverse/pull/58) | `224ae6e0a69fb6a21be9706ba47284aa768e13a3` | Summary correction into the distance-fix branch |
| [#57](https://github.com/cudaverse/cudaverse/pull/57) | `7b8ee3a465009b9e08d0b16b892fd84be90b35b0` | Distance fix and summary correction into the development branch |
| [#55](https://github.com/cudaverse/cudaverse/pull/55) | `333fb193f3fb613b0905c6b16d00b6018b9ba138` | Development changes into main |
| [#56](https://github.com/cudaverse/cudaverse/pull/56) | `f93361d40d3b6f035b1494cfb968de679b165cd6` | Windows setup and TF32 availability documentation into main |

The final merge completed at 2026-10-13 04:40:09 UTC. Final main has tree
`c8cda09a13ed55f352f8af7cbb9be860bc06a990`, matching the reviewed combined tree
and the PR #56 head `a6d3ee9`. The integrated R and native code are unchanged
from hardware-measured `5754739`. The complete tree difference from that source
is the summary renderer and its regression test, README, GPU setup vignette and
performance vignette. Hardware reports retain `5754739`; corrected core-summary
verification retains renderer `8616084`. Neither is relabelled as a new hardware
run at final main.

Fresh PR #56 [R checks](https://github.com/cudaverse/cudaverse/actions/runs/38346698333),
[native integrity](https://github.com/cudaverse/cudaverse/actions/runs/38346698360),
[CPU integration](https://github.com/cudaverse/cudaverse/actions/runs/38346698608)
and [documentation build](https://github.com/cudaverse/cudaverse/actions/runs/38346698402)
passed at `a6d3ee9`. All four R platforms recorded 1,242 passing assertions,
58 skips and zero failures. Windows/macOS had no warnings; each Linux log retains
the optional SummarizedExperiment duplicate-import warning described above.
The conditional CUDA parity job and PR Pages deployment were skipped. Native
integrity checks cover ABI and PTX reproducibility; the separate hardware
evidence above supplies GPU execution coverage. These PR results do not establish
the final main CI or Pages deployment outcome.

### Final main checks and deployment

All four final main [R checks](https://github.com/cudaverse/cudaverse/actions/runs/38347557292)
passed at `f93361d`: Windows release, macOS release, Linux release and Linux
R-devel. Each reports Status: OK, 1,242 passing assertions, 58 skips, zero
failures and zero test warnings. The R-devel job completed its cold source
dependency build before checking the package. The optional warnings in earlier
PR logs remain preserved; they were absent from this final main run.

The final main [CPU integration check](https://github.com/cudaverse/cudaverse/actions/runs/38347557461)
passed with core `f93361d` and companion `02a5b1e`. The
[site workflow](https://github.com/cudaverse/cudaverse/actions/runs/38347557262)
successfully built and deployed that source. Its publication commit is
`425345ed4e21104c4ce3ef1fca525af10aeeeb53`, with the maintainer's accepted
identity as both author and committer. GitHub Pages completed publication at
2026-10-13 04:45:25 UTC. The served homepage, matrix-multiplication reference,
performance article and GPU setup article returned HTTP 200 and exactly matched
their published Git blobs. All 32 content checks passed, including the
development/CRAN version distinction, TF32 precision qualifications and Windows
dependent-DLL search paths.

An older main `333fb19` [site build](https://github.com/cudaverse/cudaverse/actions/runs/38346588682)
failed at a 60-second CDN download timeout for `clipboard.min.js`; its logs are
retained and it did not deploy. The final-source build succeeded on its first
attempt. The earlier `224ae6e` site build's CDN timeout and successful retry
at unchanged source also remain recorded; neither transient failure is hidden.

## Remaining work

The corrected candidate's full core, precision and single-cell gates are
complete under the policies recorded above. These numerical, timing, memory and
provenance reports remain tied to their exact measured sources. Preserve all
failed and stopped attempts and identify unavailable measurements explicitly.
Shared timing samples remain descriptive; they do not support uncontended
performance claims.

Final main CI and verification of deployed reference and tutorial pages passed.
The development milestone is complete. Companion publication requires its own authorized confirmation and
verified outcome. The [September checkpoint](../2026-09-07/README.md) and its
raw historical reports remain unchanged.
