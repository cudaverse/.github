# Compatibility contract

The supported source stack contains two packages.

| Package | Development version | Strong cudaverse dependency |
|---|---:|---|
| `cudaverse` | 0.1.0 | None |
| `cudacellr` | 0.4.0 | `cudaverse (>= 0.1.0)` |

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
