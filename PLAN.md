# Native Windows support for Bend2

## Objective and constraints

Extend Bend2 to support native Windows with feature parity with Linux, while
minimizing code growth and preserving existing Linux behavior. This plan is
intended for execution by GPT-6 Luna Medium.

- Read and follow `AGENTS.md` before implementation.
- Do not edit `bend2/bend.ts`, including for portability fixes. Report any
  blocker that cannot be resolved outside it.
- Keep one compiler, shared runtime algorithms, and shared effect control flow.
  Put platform differences at narrow OS boundaries; do not duplicate the
  scheduler, evaluator, IO loop, or whole effects unnecessarily.
- Do not introduce Windows specific optimizations or silent feature stubs.
- Preserve Linux implementations wherever practical, including errors,
  timeouts, resource cleanup, and established backend behavior.
- Do not change repository allow lists or token caps. Prefer existing files
  for permanent implementation changes. This handoff document is not a reason
  to add an exception to the repository gate.

## Findings from the initial inspection

No implementation changes or validation runs preceded this plan.

| Area | Dependencies to inspect and adapt |
| --- | --- |
| `bend2/main.ts` | Compiler discovery, Unix linker flags, executable paths, CUDA discovery, shell updater, browser launcher |
| C runtime in `bend2/comp.ts` | pthreads, mmap, memory protection, signal handlers, clocks, CPU availability, POSIX sockets and readiness |
| JS runtime in `bend2/comp.ts` | Direct FFI calls into Linux/macOS libc, including networking and error handling |
| `bend2/effs/` | File operations, networking, POSIX subprocess execution, randomness, Linux/macOS window and audio implementations |
| `bend2/safe.ts` | Lean kernel build and executable handling for `--verdict` |
| Sibling `../bend-lang.com` | Installer, release tooling, and distribution integration |

These are starting points, not an exhaustive inventory. Search for additional
platform assumptions before editing.

## Execution stages

### 1. Inventory, baseline, and toolchain

1. Inspect the working tree and preserve unrelated user changes.
2. Read the CLI, embedded C/JS runtimes, effects, kernel launch code, and gates.
3. Create a checklist covering every CLI command and effect, CPU execution,
   JS execution, CUDA, foreign code, imports, and `--verdict`.
4. Record current Linux behavior using existing tests and documented contracts.
   Preserve established differences between backends while matching each
   backend's behavior across operating systems.
5. Inspect available compilers and Windows execution facilities. Select a
   Windows Clang toolchain compatible with generated C, atomics, thread local
   storage, constructors, and CUDA. Verify uncertain API/toolchain details in
   official documentation.
6. Evaluate any compatibility dependency against packaging, code size, and
   feature parity before adopting it. Do not assume MSVC-targeting Clang and
   MinGW-targeting Clang have identical behavior.

Deliverable: a concrete parity checklist and toolchain decision before broad
runtime edits.

### 2. CLI and build portability

1. Adapt compiler discovery, executable suffixes, paths, linker arguments, and
   Windows CUDA discovery. Keep the build pipeline shared.
2. Inspect emitted source paths and embedded assets for quoting and path issues.
3. Adapt browser launching and inspect installation/update integration.
4. Inspect `safe.ts` for Windows kernel build and executable handling.
5. Check imports, foreign code, Unicode paths, and paths containing spaces.

Do not invent Windows installer URLs or claim update support before the
distribution endpoint exists.

### 3. CPU runtime portability

1. Introduce small OS adaptations for thread creation, mutexes, conditions,
   clocks, and CPU availability.
2. Adapt virtual memory reservation, commitment, release, and protection.
   Existing large sparse allocations must retain their intended behavior;
   simply committing their full size may make the runtime unusable.
3. Preserve stack guards and the runtime's failure behavior using appropriate
   Windows mechanisms. Inspect every mapping use, including GPU-related maps.
4. Keep the scheduler, evaluator, memory layout, and algorithms shared.

Validate ordinary CPU programs and parallel execution before moving on.

### 4. Files, networking, processes, and other effects

1. Adapt file operations, standard streams, randomness, and environment access.
2. Adapt sockets and readiness while preserving partial reads/writes, EOF,
   deadlines, and cleanup.
3. Adapt subprocess execution, including argument quoting, environment,
   stdin/stdout/stderr, exit status, timeout behavior, and resource cleanup.
4. Preserve shared effect control flow and isolate OS calls where practical.

Explicitly audit these differences rather than hiding them with casts or
replacement constants:

- Pointer widths, integer widths, and handle representation.
- Socket handles versus CRT file descriptors and their close operations.
- Windows and POSIX error domains and translation into Bend IO failures.
- Binary versus text streams, newline translation, and byte counts.
- Readiness behavior for sockets, pipes, files, and standard input.
- Resource inheritance and subprocess argument parsing.

### 5. JS backend

1. Audit `io_sys()` and every JS effect that depends on libc FFI.
2. Implement Windows OS bindings or an equivalent shared abstraction with the
   same observable behavior. Bun running on Windows alone is insufficient.
3. Check ABI signatures, handle widths, buffer lifetimes, and error retrieval.
4. Validate the JS effects independently against the parity checklist.

### 6. Window, audio, and CUDA

1. Add Windows window and audio OS implementations, reusing existing rendering
   and buffering logic. Preserve input, frame, title, grab, and cleanup behavior.
2. Adapt CUDA library discovery, linking, runtime compilation, and embedded
   device program handling for Windows.
3. Preserve shared host/device code and current CPU fallback behavior.
4. Validate graphics, audio, and CUDA on suitable Windows hardware. Do not
   silently substitute unsupported-operation stubs for existing capabilities.

Platform-exclusive APIs such as Metal remain platform-specific; parity means
equivalent Bend capabilities through the applicable backend.

### 7. Distribution and final validation

1. Inspect the sibling site repository if available and coordinate Windows
   installation, updates, and release artifacts within authorized scope.
2. Use existing Bend tests first. Add focused Bend cases for uncovered behavior,
   following the repository's `#|` expected-output convention.
3. Run equivalent cases on Linux and native Windows for CPU, JS, IO, foreign
   calls, CLI behavior, and `--verdict`; exercise CUDA where hardware permits.
4. Run required repository checks through their supported environment. The
   documented gates use the mini cluster; do not claim they passed if that
   environment is unavailable.
5. Measure file/token growth against the unchanged caps and remove unnecessary
   duplication. Include documentation updates needed to use Windows support.

## Working method and completion criteria

- Work in small stages and validate each before continuing. Intermediate stages
  are checkpoints, not a reduction in the requested scope.
- At each stage, report changed files, added size, validation results, and
  remaining blockers.
- Do not treat successful compilation as proof of runtime parity. Distinguish
  implementation completed, cross compilation passed, and native Windows
  execution passed.
- If Windows execution, hardware, cluster access, or the sibling release
  repository is unavailable, complete independent work and identify precisely
  what remains unverified or blocked.
- Do not declare full Windows support until the parity checklist is satisfied.
  Linux-only checks cannot establish Windows correctness.

The largest expected work areas are IO parity and virtual memory handling.
Keep Linux regression checks alongside Windows validation throughout the work.
