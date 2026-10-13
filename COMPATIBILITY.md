# Compatibility contract

The supported main-branch source stack contains two packages. This table
records the source state after integration of development PRs #55 through #58
on 2026-10-13; final main CI and deployed-page verification passed.

| Package | Main-branch version | Strong cudaverse dependency |
|---|---:|---|
| `cudaverse` | 0.4.1.9000 | None |
| `cudacellr` | 0.4.0 | `cudaverse (>= 0.4.1)` |

Core 0.4.1 is [published on CRAN](https://cran.r-project.org/package=cudaverse).
The extension no longer declares a development `Remotes` dependency and can
use that published core. The extension's October 7 upload awaits email
confirmation; source compatibility and passing checks do not establish CRAN
acceptance of `cudacellr`.

Core main is `f93361d40d3b6f035b1494cfb968de679b165cd6` (tree
`c8cda09a13ed55f352f8af7cbb9be860bc06a990`). Merged
[PR #55](https://github.com/cudaverse/cudaverse/pull/55) includes the native
duplicate-PCA correction and explicit
`tensor_matmul(..., precision = "tf32")` option. These development changes are
unavailable from the CRAN 0.4.1 installation. The companion remains at
`02a5b1e130aaf5e8d3db4d6e65bba6eed74bfa40`; its strong dependency still permits
published core 0.4.1. The
[current evidence summary](evidence/2026-10-10/README.md) records the completed
checks, shared-device limitation and completed full results. The original full
core run failed its distance tolerance on six values. Stacked
[PR #57](https://github.com/cudaverse/cudaverse/pull/57) fixes native Euclidean
cancellation at `5754739cfc09d730322bf7a9ea4d5d6ae02b8245`. Its full core and
precision gates passed. The initial full single-cell attempt failed its
relative-only PCA reconstruction comparison near zero; a larger-input diagnostic
also found two relative-only subspace failures. The fresh full run completed on
October 13: all three sizes passed on CPU and native backends under the disclosed
core FP64 reconstruction (rtol 1e-8, atol 1e-10) and projector (rtol 0, atol 1e-8)
criteria. Both original diagnostics remain recorded, including 32 native
reconstruction failures at 10,000 cells and 1,526 reconstruction plus two
projector failures at 50,000 cells. The same companion revision was used;
source/install identities stayed unchanged and native owned-allocation cleanup
deltas were zero. This completes candidate hardware validation under those
policies. The package code measured at `5754739` is unchanged in final main;
final main CI and deployed-page verification passed.
[PR #58](https://github.com/cudaverse/cudaverse/pull/58)
corrects rounded diagnostic counts in the benchmark summary, with no package
runtime changes. The corrected summary passes verification against the retained
core report; the original summary failure remains recorded. Its renderer commit
`8616084` is separate from hardware-measured source `5754739`. All shared-GPU
timings remain ineligible for uncontended performance claims.

Merged [PR #56](https://github.com/cudaverse/cudaverse/pull/56) adds documentation
for Windows dependent DLL paths and development-only TF32 installation. Its
combined tree passed fresh R, native-integrity, CPU integration and documentation
checks at `a6d3ee9ae703636230ebe4ea46af26587609c430` and matches final main.
That PR documentation build did not deploy Pages. The subsequent final main
build and deployment passed, and served reference/tutorial pages match the
published files. Source integration does not
change the published CRAN version or authorize companion confirmation.

`cudaverse` owns the canonical `cuda_provenance()` generic and all
general-purpose dense, sparse, algorithm, graph, and embedding APIs.
`cudacellr` re-exports that generic and owns only single-cell workflows and
object adapters.

The source dependency graph must remain acyclic:

```text
cudaverse -> cudacellr
```

The organization integration workflows install and test the main branches in
that order. Optional backends remain in `Suggests`; requesting an unavailable
backend must produce an actionable error rather than silently changing the
requested method.

The former component repositories are not part of the supported source tuple.
They are retained only as archived development history.
