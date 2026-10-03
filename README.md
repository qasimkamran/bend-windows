# Bend on Windows

This fork adds native Windows support to Bend 2.0.34. It is a preview, not an
official Bend distribution. The installer and releases are published from
`qasimkamran/bend-windows`.

## Install

In PowerShell, run:

```powershell
irm https://github.com/qasimkamran/bend-windows/releases/latest/download/install.ps1 | iex
```

Open a new terminal, then use the `bend` command:

```powershell
bend guide
bend .\main.bend
bend .\main.bend --check-only
bend .\main.bend --verdict
bend .\main.bend -o .\main.exe
```

The per-user installer needs internet access. It installs Bun if absent,
downloads the matching x64 or ARM64 LLVM-MinGW toolchain, verifies its SHA-256,
and adds `bend` to the user PATH. It does not require Git or administrator
rights. Run the install command again to update. `bend` is a command shim;
`-o .\main.exe` builds a native Windows program.

To install the current commit from a local Bend checkout, run
`./install.ps1 -Local` from that checkout. This archives the checked out
branch's `HEAD` commit; uncommitted changes are not included. The installer
still downloads the Windows toolchain if it is not already installed.

CUDA and Lean are optional. Without CUDA, GPU-marked programs run on the CPU.
`--verdict` needs Lean 4.34.0. The installer does not install either dependency.

## Uninstall

In PowerShell, remove the Bend install and its user PATH entry:

```powershell
$bendHome = Join-Path $env:LOCALAPPDATA 'Programs\Bend'
$binPath = Join-Path $bendHome 'bin'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$newPath = ($userPath -split ';' | Where-Object {
  $_ -and $_.TrimEnd('\') -ine $binPath.TrimEnd('\')
}) -join ';'
[Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
Remove-Item -LiteralPath $bendHome -Recurse -Force
```

Open a new terminal afterward. This removes Bend's source snapshots, LLVM-MinGW
copy, and command shim; it leaves Bun, Lean, and CUDA installed separately.

## Windows validation

The 2.0.34 integration was checked natively on Windows x64 with Bun and
LLVM-MinGW: upstream regressions, base-library and import tests, CPU and JS
execution, and file, socket, process, channel and timer effects. Process tests
cover stdout, stderr and combined output limits. The updated Lean 4.34.0
kernel builds and passes `cong_lambda_argument.bend --verdict`.

The array tests, including `array_fork.bend`, pass with four CPU workers and
`--gpu off`. CUDA Toolkit 13.4 compile/link and CPU fallback also pass. CUDA
device execution and interactive GUI/audio behavior were not validated.

The mini-cluster hostname is unavailable here. The repository gate has two
inherited failures: tracked `PLAN.md` is outside its allow list, and `comp.ts`
exceeds its 64,000-token cap (68,739 before this integration; 68,899 after).
The allow list and caps are unchanged. TypeScript checking reports the same
diagnostics as an unmodified upstream 2.0.34 checkout.
