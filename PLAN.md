# Native Windows support: remaining work

This is a handoff for follow-up agents. Read `AGENTS.md` first and preserve its
constraints. Windows support is implemented across the shared compiler and
runtimes, but “implemented” does not mean every platform or hardware path has
been runtime-validated.

## Constraints

- Keep Linux behavior and implementations unchanged wherever possible. Reuse
  shared code; do not add Windows-only optimizations or silent stubs.
- `bend2/bend.ts` is human-written language code and must not be edited. A
  narrowly authorized import-path fix was already made; do not broaden it.
- Do not edit repository allow lists or token caps.
- Keep native Windows runtime results distinct from cross-compilation and
  compile/link-only results. Do not claim full parity without the relevant
  runtime checks.
- Commit at meaningful milestones. Before pushing, inspect branch/upstream.

## Delivered

- Windows CPU runtime portability and Windows implementations for sockets,
  process execution, files, randomness, audio, and windows, sharing the
  existing runtime/effect logic where possible.
- Windows JS backend IO bindings and effects; focused JS checks ran natively.
- CLI executable naming, import handling (including Unicode paths), foreign
  code/build paths, Windows `--verdict` executable handling, and CUDA cache,
  environment, discovery, and linking paths.
- A fork-specific Windows preview release and PowerShell installer. The README
  documents installation and removal. This is not integration with the
  upstream Bend distribution/site.
- Installer Preview 2 fixes architecture detection in Windows PowerShell 5.1;
  validated under PowerShell 5.1 with a disposable install and `bend version`.
- Native Windows CPU/JS and focused effect checks, plus Windows Lean 4.34.0
  `--verdict` checks. Linux behavior was compared for available focused cases.

## Remaining work and validation blockers

1. **CUDA device execution:** CUDA Toolkit 13.4 was installed and Windows
   CUDA build/link paths were checked without a GPU. Kernel/device execution
   still needs a compatible NVIDIA GPU and driver. Do not describe SDK-only
   checks as CUDA runtime validation.
2. **GUI and audio runtime:** implementations compile, but interactive window
   and audio behavior has not been validated end-to-end on this machine.
3. **Windows `array_fork`:** investigate the native Windows memory fault in
   `tests/run/array_fork.bend`, observed with CUDA both enabled and disabled.
   Keep this distinct from the CUDA SDK/device blocker.
4. **Full project gates:** rerun `gates/test.ts`, `gates/safe.ts`, and other
   applicable gates when mini-cluster DNS is available and `ttok` is installed.
   Previous gate execution was blocked by cluster DNS; `gates/repo.ts` also
   could not complete without `ttok`. Do not change gate allow lists or caps.
   The earlier broad sweep included standalone inputs requiring harness or
   foreign imports; `select_eintr` and `fifo_eof` are POSIX-specific test
   sources, not by themselves product compiler failures.
5. **Upstream distribution:** inspect `../bend-lang.com` before attempting
   official installer/update integration. It was absent in the prior
   environment. Do not invent Windows distribution URLs. The fork preview
   installer is the available distribution path; `bend update` is not an
   upstream Windows update integration.

The installer is published as a release asset, not tracked in the repository,
because the repository gate does not allow a root `install.ps1` file.

## Validation notes

- Windows native CPU/JS/effect and `--verdict` checks are runtime results.
- Windows CUDA host compilation/linking is compile-only; no CUDA GPU/driver
  was available for device execution.
- Cross-compilation proves only that the target builds, not that it runs on
  Windows. Record target architecture and compiler for each such result.
- Native interactive GUI/audio checks and the mini-cluster gates remain
  outstanding as noted above.
