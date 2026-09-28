# Bend on Windows

This fork adds native Windows support to Bend 2.0.32. It is a preview, not an
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

Validated natively on Windows: CPU and JavaScript execution; C file, socket,
process, and timer effects; imports including Unicode paths; and `--verdict`
with Lean 4.34.0. CUDA Toolkit 13.4 SDK discovery and compile/link plus the
no-GPU path passed. CUDA device execution, GPU kernel compilation, GUI/audio
runtime checks, and the mini-cluster gates were not validated here.

Known test limitation: `tests/run/array_fork.bend` reports memory faults on
Windows both with CUDA enabled and with CUDA disabled. This remains unresolved.
