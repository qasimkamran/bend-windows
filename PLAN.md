# Bend 2.0.34 Windows fork handoff

Updated 2026-10-03 for `update/bend-2.0.34`. This replaces the old Windows
porting checklist. Read `AGENTS.md` first. The integration is committed as
`67941b37` (parents: fork `7901c190`, upstream v2.0.34 `7d8a3eb0`).

## Constraints

- Keep Linux behavior and implementations unchanged wherever possible. Reuse
  shared code; do not add Windows-only optimizations or silent stubs.
- `bend2/bend.ts` is human-written language code and must not be edited. The
  existing, narrowly authorized Windows import-path fix must not be broadened.
  This integration imported upstream language changes without authoring new
  language changes; its only difference from upstream is that existing fix.
- Do not edit repository allow lists or token caps. An over-cap file must be
  simplified in place, not split into other files to evade its cap.
- Distinguish native Windows execution, cross-compilation, compile/link checks
  and actual GPU execution. Do not claim platform parity from build success.
- Commit at meaningful milestones. Before pushing, inspect branch/upstream.

## Delivered

- Merged upstream v2.0.34, including the v2.0.33 updates: shared-graph
  conversion, base-library simplifications, U32-to-Nat widening, shared-array
  redirect and display-layout fixes, effect ID parsing, and the Lean kernel's
  lambda-argument fix. Upstream regression tests and release notes are included.
- Preserved the fork's Windows CPU runtime, C and JS effects, CLI executable
  handling, imports, foreign C/dlfcn support, CUDA paths, and Lean integration.
- Resolved the process helper conflict by retaining `process_append`'s boolean
  result: Windows pipe readers use it to stop when the combined output limit
  is exceeded. Added `tests/io/process_output_limit_bun.bend`, covering stdout,
  stderr and combined limits while the child would otherwise keep running.
- Updated README and CHANGELOG for this integration and its validation limits.
- Preserved the tracked `install.ps1` and its `-Local` branch-commit install
  behavior. The installer is allowed by the existing repository gate. This
  branch has not been pushed and no new preview release has been published.

## Verified on this branch

- **Windows x64, Bun and LLVM-MinGW:** 349 distinct local Bend test cases
  passed across 923 probes. Coverage includes all 123 `tests/compile` cases,
  all 101 `tests/reg` cases, 77 base-library/import cases, the upstream additions,
  and focused array and IO cases. Expected output comes from each file's `#|`
  lines; expected failures and unprintable mains follow the gate's conventions.
  This is local coverage, not a successful full mini-cluster gate run.
- **CPU and JS effects:** file, TCP/UDP, process, channel, timer and randomness
  checks passed, including the new process output-limit regression.
- **Arrays:** `array_fork.bend` and the selected array suite passed with four
  CPU workers and `--gpu off`. The old PLAN's memory-fault report was not
  reproduced in these runs; it is not a verified current failure. This does
  not establish GPU behavior or exhaustive stress-test stability.
- **Lean 4.34.0:** the updated kernel built natively and
  `bun bend2/main.ts tests/proof/cong_lambda_argument.bend --verdict` printed
  `ALL PROOFS CHECK`.
- **CUDA Toolkit 13.4:** `spin_array_hold.bend` built and linked with CUDA;
  its executable printed the expected results with `--gpu off`. With
  `--gpu on`, it reported no usable GPU. No device execution was validated.
- **Audio entry points:** `audio_only_open`, `audio_only_write` and
  `audio_only_close` passed their device-independent paths on C and JS.
  These tests do not validate sound playback.
- **Repository gate:** now runnable with locally installed `ttok`; it reports
  `PASS: 48 / 50`, with the two inherited failures listed below.
- **TypeScript:** checking the fork and an unmodified upstream v2.0.34 checkout
  produced the same 12 diagnostics. No new integration diagnostic was found.
- `git diff --check` passed. Gate rules and caps were not changed.

Local harness, aggregate results and logs are under the ignored
`.tmp/upgrade-2034/` directory; `validation.json` records the 349 cases.
These are temporary validation artifacts, not a replacement for project gates.

## Remaining work

1. **Repository gate compliance:** `comp.ts` exceeds its unchanged 64,000-token
   cap: 68,739 before this integration, 68,899 afterward. Substantial in-place
   simplification is still needed. `PLAN.md` is also tracked outside the allow
   list. Do not silently expand the allow list or remove this requested handoff;
   resolve its disposition with the user and repository owner.
2. **Full project gates:** the `cluster` hostname currently fails to resolve.
   Run the test, safety, performance and other applicable gates when cluster
   access and their dependencies are available. Missing `ttok` is no longer
   the local blocker; the measured repository failures above are real.
3. **CUDA runtime:** validate device compilation and execution with an accessible,
   compatible NVIDIA GPU/driver. `nvidia-smi` reported insufficient permissions
   in this session; do not infer that the machine has no GPU. Cover shared-array
   redirects, parallel execution and GPU cache behavior on the device.
4. **Interactive GUI/audio:** exercise windows, input, rendering and audio
   playback on Windows. Build success and the device-independent audio tests
   do not establish end-to-end behavior.
5. **TypeScript diagnostics:** upstream v2.0.34 has existing errors in `bend.ts`,
   `safe.ts` and documentation generators, including missing `canvas` types and
   the film's `findLastIndex` library target. Track these separately from the
   Windows merge. Do not change protected language code to make this check pass.
6. **Distribution:** if requested, push this branch and prepare a Windows preview
   release from the tested commit. The existing installer downloads published
   releases; it does not make this unpublished branch available automatically.
   Official upstream Windows distribution/update integration is separate work:
   inspect the site repository before changing it, and do not invent URLs.

The user's pre-existing untracked `test.exe` was left untouched.
