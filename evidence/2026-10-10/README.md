# Development validation checkpoint

This October 10 checkpoint records the draft
[PR #55](https://github.com/cudaverse/cudaverse/pull/55) assessment. Core
0.4.1 remains published on CRAN. The candidate has not been integrated into
main or released, and the companion upload is awaiting email confirmation.

| Source | Exact commit | Scope |
| --- | --- | --- |
| Initial core | `0c74a44a972329dea8e4926727fb70f3f947a1f7` | 0.4.1.9000 correctness and diagnostic baseline |
| Current core | `2c2b569a2b503478d1141ddc6fd7f2276ff866af` | Adds explicit shared-GPU benchmark execution and reporting |
| Companion | `02a5b1e130aaf5e8d3db4d6e65bba6eed74bfa40` | cudacellr 0.4.0 |

Both core revisions and the companion were installed from clean exact sources
into isolated Linux R libraries on an A100 SXM4 40 GB with R 4.3.3 and no torch.
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

The candidate's four-platform [R check matrix](https://github.com/cudaverse/cudaverse/actions/runs/38099228302),
[native integrity](https://github.com/cudaverse/cudaverse/actions/runs/38099228307),
[CPU integration](https://github.com/cudaverse/cudaverse/actions/runs/38099228517)
and [documentation build](https://github.com/cudaverse/cudaverse/actions/runs/38099228319)
passed. The PR did not deploy Pages; optional hardware CI skipped. The separate
[full manual/readiness run](https://github.com/cudaverse/cudaverse/actions/runs/38099232218)
is pending at this checkpoint.

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

## Remaining work

The separate full precision, core and single-cell sequence is in progress.
Review its completed numerical, timing, memory and provenance reports together
with exact-candidate readiness artifacts before integrating PR #55. Preserve
any failure and identify unavailable measurements explicitly. Shared timing
samples remain descriptive; they do not support uncontended performance claims.

After integration, verify main CI and the deployed reference and tutorial
pages. Companion publication requires its own authorized confirmation and
verified outcome. The [September checkpoint](../2026-09-07/README.md) and its
raw historical reports remain unchanged.
