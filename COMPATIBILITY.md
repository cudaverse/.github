# Compatibility contract

The supported main-branch source stack contains two packages.

| Package | Main-branch version | Strong cudaverse dependency |
|---|---:|---|
| `cudaverse` | 0.4.1 | None |
| `cudacellr` | 0.4.0 | `cudaverse (>= 0.4.1)` |

The core version is [published on CRAN](https://cran.r-project.org/package=cudaverse).
The extension no longer declares a development `Remotes` dependency and can
use that published core. The core 0.4.1.9000 development candidate in
[PR #55](https://github.com/cudaverse/cudaverse/pull/55) remains separate from
this main-branch stack.

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
