[CmdletBinding()]
param(
  [string]$PackageDirectory = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($PackageDirectory)) {
  $latest = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'dist\windows') -Directory -Filter 'What-Do-You-Do-Windows-v*' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if ($null -eq $latest) { throw 'No Windows release package found under dist\windows.' }
  $PackageDirectory = $latest.FullName
}
$packageRoot = (Resolve-Path -LiteralPath $PackageDirectory).Path
$manifestPath = Join-Path $packageRoot 'release-manifest.json'
$hashPath = Join-Path $packageRoot 'SHA256SUMS.txt'
if (-not (Test-Path -LiteralPath $manifestPath)) { throw 'release-manifest.json is missing.' }
if (-not (Test-Path -LiteralPath $hashPath)) { throw 'SHA256SUMS.txt is missing.' }
if (-not (Test-Path -LiteralPath (Join-Path $packageRoot 'Install-WhatDoYouDo.ps1'))) {
  throw 'Install-WhatDoYouDo.ps1 is missing.'
}
if (-not (Test-Path -LiteralPath (Join-Path $packageRoot 'app\what_do_you_do.exe'))) {
  throw 'app\what_do_you_do.exe is missing.'
}
if (Test-Path -LiteralPath (Join-Path $packageRoot 'app\start-collector.ps1')) {
  throw 'Obsolete start-collector.ps1 must not ship with the native app.'
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.runtime -ne 'flutter-windows-native') { throw 'Unexpected runtime in release manifest.' }
if ($manifest.platform -ne 'windows-x64') { throw 'Unexpected platform in release manifest.' }
foreach ($entry in $manifest.files) {
  $filePath = Join-Path $packageRoot ($entry.path -replace '/', '\')
  if (-not (Test-Path -LiteralPath $filePath)) { throw "Manifest file is missing: $($entry.path)" }
  $actual = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actual -ne $entry.sha256) { throw "Hash mismatch: $($entry.path)" }
}

Write-Output "Windows release smoke passed: $($manifest.product) v$($manifest.version)+$($manifest.build)"
Write-Output 'Verified native runtime payload, manifest hashes, installer, and no legacy collector launcher.'
