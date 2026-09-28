[CmdletBinding()]
param(
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'Programs\Bend'),
  [string]$CompilerPath,
  [string]$ReleaseTag,
  [switch]$Local,
  [switch]$NoPath
)

$ErrorActionPreference = 'Stop'
$repo = 'qasimkamran/bend-windows'
$headers = @{ 'User-Agent' = 'Bend-Windows-Installer';
  'Accept' = 'application/vnd.github+json' }
$temp = Join-Path ([IO.Path]::GetTempPath()) ('bend-install-' + [guid]::NewGuid())

function get_bun {
  $found = Get-Command bun -ErrorAction SilentlyContinue
  if ($found) { return $found.Source }
  $local = Join-Path $env:USERPROFILE '.bun\bin\bun.exe'
  if (Test-Path -LiteralPath $local) { return $local }

  Write-Output 'Installing Bun for the current user...'
  $script = (Invoke-WebRequest 'https://bun.sh/install.ps1' -UseBasicParsing).Content
  & ([scriptblock]::Create($script))
  if (Test-Path -LiteralPath $local) { return $local }
  $found = Get-Command bun -ErrorAction SilentlyContinue
  if ($found) { return $found.Source }
  throw 'Bun installation did not provide bun.exe.'
}

function install_zip([string]$url, [string]$archive, [string]$destination, [string]$digest = '') {
  & curl.exe --location --fail --silent --show-error --retry 3 --output $archive $url
  if ($LASTEXITCODE -ne 0) { throw "Download failed: $url" }
  if ($digest -match '^sha256:(.+)$') {
    $actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $Matches[1].ToLowerInvariant()) {
      throw "Archive hash mismatch: $url"
    }
  }
  New-Item -ItemType Directory -Path $destination -Force | Out-Null
  Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
}

try {
  New-Item -ItemType Directory -Path $temp -Force | Out-Null
  $null = get_bun

  $arch = $env:PROCESSOR_ARCHITEW6432
  if ([string]::IsNullOrWhiteSpace($arch)) { $arch = $env:PROCESSOR_ARCHITECTURE }
  if ([string]::IsNullOrWhiteSpace($arch)) {
    throw 'Could not determine the Windows processor architecture.'
  }
  $target = switch ($arch.ToUpperInvariant()) {
    { $_ -in 'AMD64', 'X64' } { 'x86_64' }
    { $_ -in 'ARM64', 'AARCH64' } { 'aarch64' }
    default { throw "Unsupported Windows architecture: $arch" }
  }

  if ([string]::IsNullOrWhiteSpace($CompilerPath)) {
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/mstorsjo/llvm-mingw/releases/latest' -Headers $headers
    $toolName = "llvm-mingw-$($release.tag_name)-ucrt-$target"
    $asset = $release.assets | Where-Object name -EQ "$toolName.zip" | Select-Object -First 1
    if (-not $asset) { throw "LLVM-MinGW release $($release.tag_name) has no $target toolchain." }
    $toolRoot = Join-Path $InstallRoot "toolchains\$toolName"
    $CompilerPath = Get-ChildItem -LiteralPath $toolRoot -Filter "$target-w64-mingw32-clang.exe" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    if (-not $CompilerPath) {
      Write-Output "Installing LLVM-MinGW $($release.tag_name) ($target)..."
      $toolArchive = Join-Path $temp "$toolName.zip"
      install_zip $asset.browser_download_url $toolArchive $toolRoot $asset.digest
      $CompilerPath = Get-ChildItem -LiteralPath $toolRoot -Filter "$target-w64-mingw32-clang.exe" -File -Recurse | Select-Object -First 1 -ExpandProperty FullName
    }
  }
  if (-not (Test-Path -LiteralPath $CompilerPath -PathType Leaf)) {
    throw "LLVM-MinGW compiler not found: $CompilerPath"
  }
  $CompilerPath = (Resolve-Path -LiteralPath $CompilerPath).Path

  if ($Local) {
    $branch = (& git -C $PSScriptRoot branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
      throw 'The -Local option requires install.ps1 to run inside a Git branch checkout.'
    }
    $sha = (& git -C $PSScriptRoot rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $sha -notmatch '^[0-9a-f]{40}$') {
      throw 'Could not resolve the current branch commit for a local install.'
    }
  } else {
    if ([string]::IsNullOrWhiteSpace($ReleaseTag)) {
      $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases?per_page=100" -Headers $headers
      $latest = $releases | Where-Object { -not $_.draft } | Sort-Object published_at -Descending | Select-Object -First 1
      if (-not $latest) { throw "No published Bend release exists at $repo." }
      $ReleaseTag = $latest.tag_name
    }
    $tag = [uri]::EscapeDataString($ReleaseTag)
    $commit = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/commits/$tag" -Headers $headers
    $sha = $commit.sha
  }
  $sourceRoot = Join-Path $InstallRoot "versions\$sha"
  if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'bend2\main.ts'))) {
    Write-Output "Installing Bend $($sha.Substring(0, 8))..."
    if ($Local) {
      $archive = Join-Path $temp 'bend.zip'
      & git -C $PSScriptRoot archive --format=zip --output=$archive $sha
      if ($LASTEXITCODE -ne 0) { throw "Could not archive local Bend commit $sha." }
      $sourceRootTemp = Join-Path $temp 'source'
      New-Item -ItemType Directory -Path $sourceRootTemp | Out-Null
      Expand-Archive -LiteralPath $archive -DestinationPath $sourceRootTemp -Force
      $source = $sourceRootTemp
    } else {
      install_zip "https://api.github.com/repos/$repo/zipball/$sha" (Join-Path $temp 'bend.zip') (Join-Path $temp 'source')
      $source = Get-ChildItem -LiteralPath (Join-Path $temp 'source') -Directory | Select-Object -First 1
      if ($source) { $source = $source.FullName }
    }
    if (-not $source -or -not (Test-Path -LiteralPath (Join-Path $source 'bend2\main.ts'))) {
      throw 'The Bend source archive has an unexpected layout.'
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $sourceRoot) -Force | Out-Null
    Move-Item -LiteralPath $source -Destination $sourceRoot
  }

  $bin = Join-Path $InstallRoot 'bin'
  New-Item -ItemType Directory -Path $bin -Force | Out-Null
  New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
  [IO.File]::WriteAllText((Join-Path $InstallRoot 'bunfig.toml'), '', [Text.UTF8Encoding]::new($false))
  $rootRelative = $InstallRoot.TrimEnd('\', '/')
  if ($CompilerPath.StartsWith($rootRelative + '\', [StringComparison]::OrdinalIgnoreCase)) {
    $ccRelative = $CompilerPath.Substring($rootRelative.Length).TrimStart('\', '/')
    $ccValue = "%BEND_HOME%\$($ccRelative.Replace('/', '\'))"
  } else {
    $ccValue = $CompilerPath
  }
  $launcher = @(
    '@echo off'
    'setlocal'
    'set "BEND_HOME=%~dp0.."'
    'for %%I in ("%BEND_HOME%") do set "BEND_HOME=%%~fI"'
    "set `"CC=$ccValue`""
    "bun --config=`"%BEND_HOME%\bunfig.toml`" --no-env-file `"%BEND_HOME%\versions\$sha\bend2\main.ts`" %*"
    'exit /b %ERRORLEVEL%'
  ) -join "`r`n"
  [IO.File]::WriteAllText((Join-Path $bin 'bend.cmd'), $launcher + "`r`n", [Text.Encoding]::ASCII)

  if (-not $NoPath) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @($userPath -split ';' | Where-Object { $_ })
    if (-not ($parts | Where-Object { $_.TrimEnd('\') -ieq $bin.TrimEnd('\') })) {
      [Environment]::SetEnvironmentVariable('Path', (($parts + $bin) -join ';'), 'User')
    }
    $env:Path = "$bin;$env:Path"
  }

  Write-Output "Bend is installed at $bin\bend.cmd"
  if ($Local) { Write-Output "Installed local branch '$branch' at commit $sha." }
  if ($NoPath) {
    Write-Output "Run it with: `"$bin\bend.cmd`" <file.bend>"
  } else {
    Write-Output 'Open a new terminal, then run: bend <file.bend>'
  }
  Write-Output 'Native Windows builds use LLVM-MinGW. CUDA and Lean are optional.'
} finally {
  if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
