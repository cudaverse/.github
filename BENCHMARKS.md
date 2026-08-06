# cudaverse benchmark contract

`cudaverse-benchmark/1` is the organization-wide evidence format for paired
CPU/CUDA performance measurements. It prevents results from becoming generic
speed claims when they were measured on only one machine or workload.

The machine-readable contract is
[`schemas/benchmark-v1.schema.json`](schemas/benchmark-v1.schema.json). Every
saved result must also pass
[`scripts/validate-benchmark.R`](scripts/validate-benchmark.R).

## Required experiment order

1. Use one deterministic input and record its seed, shape, data type, and
   sparsity where applicable.
2. Run the CPU reference and CUDA candidate on the same input.
3. Fail the run if correctness or provenance parity fails. A failed comparison
   is not performance evidence.
4. Warm up both implementations, synchronize CUDA before each timer stops, and
   record every repetition rather than only a summary.
5. State whether host/device transfer is included, excluded, measured
   separately, or not applicable.
6. Save the exact source SHAs, package versions, R/CUDA software, named CPU,
   named GPU, RAM/VRAM, OS, and architecture with the measurements.

Timing must use elapsed wall time. GPU work is asynchronous, so a result with
`timing.cuda_synchronized = false` is invalid. CPU and CUDA elapsed-time series
are both mandatory. Additional throughput or memory measurements may be added
without replacing the raw timing series.

## Evidence and publication

During development, set `evidence_status` to `example` and
`claims.publication_ready` to `false`. A publishable result must instead:

- set `evidence_status` to `measured`;
- pass every correctness check;
- set `claims.publication_ready` to `true`; and
- pass the validator with `--publishable`.

```sh
Rscript scripts/validate-benchmark.R result.json --publishable
```

The `claims.scope` text must limit conclusions to the recorded hardware,
software, workload, and transfer policy. Report measured break-even points
where the data supports them; do not generalize to all GPUs, CPUs, datasets, or
cudaverse operations.

Raw JSON evidence belongs in a GitHub Actions artifact or Release. Do not
commit repeated benchmark outputs, plots, runtime caches, or downloaded data to
package repositories. The organization contract CI validates the format only;
actual GPU execution remains manual until the isolated NVIDIA runner boundary
documented in `ROADMAP.md` is established.

## Package integration

Package benchmark scripts may keep package-specific setup, but must emit one
JSON document per workload conforming to this contract. The example at
[`examples/benchmark-v1.example.json`](examples/benchmark-v1.example.json)
shows the minimum paired record. Correctness checks remain package-owned
because tolerances and invariants differ across dense, sparse, learning, and
single-cell workloads.
