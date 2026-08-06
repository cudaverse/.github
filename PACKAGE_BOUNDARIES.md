# Package boundaries

The organization exposes two active packages. New functionality should be a
module inside an existing package unless it has a genuinely different user
base and dependency boundary.

## `cudaverse`

Owns all general-purpose numerical functionality:

- device selection and compute provenance;
- dense tensors and sparse matrices;
- decompositions, distances, neighbours, and clustering;
- graph construction and community detection;
- embedding algorithms and backend adapters.

These areas are separate source files and documentation sections, not separate
packages. A new algorithm does not justify a new package.

## `cudacellr`

Owns functionality whose meaning is specifically single-cell:

- count normalization and highly variable feature selection;
- feature-by-cell workflow orchestration;
- SingleCellExperiment and SeuratObject mapping.

It delegates general PCA, kNN, sparse, graph, and embedding work to
`cudaverse`.

## Rule for any future package

A third package requires all three conditions:

1. users commonly need it without either active package's primary workflow;
2. it introduces a substantial dependency or release-policy boundary;
3. placing it in an existing package would make that package materially harder
   to install, test, or understand.

Code size, a new algorithm family, or a desire for a matching name is not
enough. Shared functionality belongs at the lowest general layer and is wrapped
by domain workflows rather than reimplemented.
