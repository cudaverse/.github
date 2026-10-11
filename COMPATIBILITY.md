# Compatibility contract

The supported main-branch source stack contains two packages. This table
records the state before integration of development PR #55 (2026-10-10).

| Package | Main-branch version | Strong cudaverse dependency |
|---|---:|---|
| `cudaverse` | 0.4.1 | None |
| `cudacellr` | 0.4.0 | `cudaverse (>= 0.4.1)` |

Core 0.4.1 is [published on CRAN](https://cran.r-project.org/package=cudaverse).
The extension no longer declares a development `Remotes` dependency and can
use that published core. The extension's October 7 upload awaits email
confirmation; source compatibility and passing checks do not establish CRAN
acceptance of `cudacellr`.

Draft [PR #55](https://github.com/cudaverse/cudaverse/pull/55) contains core
0.4.1.9000 at `2c2b569a2b503478d1141ddc6fd7f2276ff866af`. Its native duplicate-PCA
correction and explicit `tensor_matmul(..., precision = "tf32")` option are
development changes, unavailable from the CRAN 0.4.1 installation. Candidate
validation pairs that exact core with unchanged `cudacellr` main commit
`02a5b1e130aaf5e8d3db4d6e65bba6eed74bfa40`; it does not change the published
core or the main-branch compatibility table. The
[current evidence summary](evidence/2026-10-10/README.md) records the completed
checks, shared-device limitation and pending full results. The original full
core run failed its distance tolerance on six values. Stacked
[PR #57](https://github.com/cudaverse/cudaverse/pull/57) fixes native Euclidean
cancellation at `5754739cfc09d730322bf7a9ea4d5d6ae02b8245`; a new exact-source
full validation sequence is running against the same companion revision.

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
