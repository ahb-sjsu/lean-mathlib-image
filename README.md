# lean-mathlib-image

A container image with a Lean 4 toolchain and a prebuilt Mathlib, for compiling Lean projects that depend on Mathlib
without building Mathlib first. It is meant for build workers on clusters, where a container that starts compiling
at once is worth more than one that first downloads and unpacks several gigabytes.

```
ghcr.io/ahb-sjsu/lean-mathlib:v4.33.1-mathlib-0df444a3
```

| path in the image | contents |
|---|---|
| `/opt/lean/toolchain` | the Lean toolchain (`bin/lean`, `lib/lean`); on `PATH` |
| `/opt/lean/packages/<name>/.lake/build/lib/lean` | the compiled libraries of Mathlib and its dependencies |
| `/opt/lean/packages/<name>/LICENSE` | each dependency's license |
| `/opt/lean/lake-manifest.json` | the exact dependency revisions |

Python 3 and `nats-py` are included for worker processes. The image holds no project code.

To compile a module against it, put every `/opt/lean/packages/*/.lake/build/lib/lean` and `/opt/lean/toolchain/lib/lean`
on `LEAN_PATH` along with your project's own build output.

## How it is built

`.github/workflows/image.yml` builds on GitHub's runners and pushes to GitHub Container Registry. Each build is
pinned by two inputs: the Lean release tag and the Mathlib commit. The dependency revisions follow Mathlib's own
manifest at that commit (`lake update`), and the compiled libraries come from Mathlib's official cache
(`lake exe cache get`), so a given pair always gives the same environment. Run the workflow by hand with other inputs
for another pair.

The first image serves [leanfarm](https://github.com/ahb-sjsu), a build farm for large Lean developments.

## Licenses

Lean 4, Mathlib, Batteries, Aesop, Qq, ProofWidgets, Plausible, ImportGraph and LeanSearchClient are licensed under
Apache-2.0, and Lean's `Cli` package under MIT. This is according to each repository's license file, checked on
2026-11-23. Each package's license file is copied into the image beside its library. This repository's own files
carry two licenses, split by what the file is:

| what | license | file |
|---|---|---|
| Dockerfile and workflow | MIT | [LICENSE](LICENSE) |
| Prose (this README) | CC BY 4.0 | [LICENSE-TEXT](LICENSE-TEXT) |
