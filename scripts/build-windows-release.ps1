[CmdletBinding()]
param(
  [string]$Flutter = (Join-Path $env:USERPROFILE 'development\flutter\bin\flutter.bat'),
  [string]$Version = '',
  [int]$BuildNumber = 0,
  [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$flutterApp = Join-Path $repoRoot 'flutter_app'
$pubspecPath = Join-Path $flutterApp 'pubspec.yaml'
$installScript = Join-Path $flutterApp 'windows\install\install-release.ps1'
$uninstallScript = Join-Path $flutterApp 'windows\install\uninstall.ps1'

if (-not (Test-Path -LiteralPath $pubspecPath)) {
  throw "Flutter package manifest not found: $pubspecPath"
}
if (-not (Test-Path -LiteralPath $Flutter)) {
  throw "Flutter executable not found: $Flutter"
}

$pubspec = Get-Content -LiteralPath $pubspecPath -Raw
if ([string]::IsNullOrWhiteSpace($Version)) {
  $versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$')
  if (-not $versionMatch.Success) {
    throw 'Could not read version from flutter_app/pubspec.yaml.'
  }
  $Version = $versionMatch.Groups[1].Value
  if ($BuildNumber -eq 0) {
    $BuildNumber = [int]$versionMatch.Groups[2].Value
  }
}
if ($BuildNumber -le 0) {
  throw 'BuildNumber must be a positive integer.'
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
  throw "Version must use x.y.z format: $Version"
}

$outputRoot = if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
  Join-Path $repoRoot 'dist\windows'
} else {
  [IO.Path]::GetFullPath($OutputDirectory)
}
$resolvedRepo = (Resolve-Path $repoRoot).Path.TrimEnd('\') + '\'
$resolvedOutput = [IO.Path]::GetFullPath($outputRoot).TrimEnd('\') + '\'
if (-not $resolvedOutput.StartsWith($resolvedRepo, [StringComparison]::OrdinalIgnoreCase)) {
  throw "Refusing to write a release outside the repository: $outputRoot"
}

function Invoke-Flutter([string[]]$Arguments) {
  & $Flutter @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter command failed with exit code ${LASTEXITCODE}: flutter $($Arguments -join ' ')"
  }
}

Push-Location $flutterApp
try {
  Invoke-Flutter @('pub', 'get')
  Invoke-Flutter @('build', 'windows', '--release', "--build-name=$Version", "--build-number=$BuildNumber")
} finally {
  Pop-Location
}

$flutterRelease = Join-Path $flutterApp 'build\windows\x64\runner\Release'
$sourceExe = Join-Path $flutterRelease 'what_do_you_do.exe'
if (-not (Test-Path -LiteralPath $sourceExe)) {
  throw "Flutter did not produce the Windows executable: $sourceExe"
}

$packageRoot = Join-Path $outputRoot "What-Do-You-Do-Windows-v$Version"
$appRoot = Join-Path $packageRoot 'app'
$zipPath = Join-Path $outputRoot "What-Do-You-Do-Windows-v$Version.zip"
if (Test-Path -LiteralPath $packageRoot) { Remove-Item -LiteralPath $packageRoot -Recurse -Force }
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
New-Item -ItemType Directory -Path $appRoot -Force | Out-Null

Get-ChildItem -LiteralPath $flutterRelease | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $appRoot -Recurse -Force
}
Copy-Item -LiteralPath $installScript -Destination (Join-Path $packageRoot 'Install-WhatDoYouDo.ps1') -Force
Copy-Item -LiteralPath $uninstallScript -Destination (Join-Path $appRoot 'uninstall.ps1') -Force

$payloadFiles = Get-ChildItem -LiteralPath $appRoot -File -Recurse | Sort-Object FullName
$fileEntries = foreach ($file in $payloadFiles) {
  $relative = $file.FullName.Substring($packageRoot.Length + 1).Replace('\', '/')
  [ordered]@{
    path = $relative
    bytes = $file.Length
    sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
  }
}
$manifest = [ordered]@{
  product = 'What Do You Do'
  platform = 'windows-x64'
  version = $Version
  build = $BuildNumber
  runtime = 'flutter-windows-native'
  signed = $false
  files = @($fileEntries)
}
$manifestPath = Join-Path $packageRoot 'release-manifest.json'
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding utf8

$hashLines = foreach ($file in ($payloadFiles + (Get-Item -LiteralPath $manifestPath))) {
  $relative = $file.FullName.Substring($packageRoot.Length + 1).Replace('\', '/')
  $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
  "$hash  $relative"
}
$hashLines | Set-Content -LiteralPath (Join-Path $packageRoot 'SHA256SUMS.txt') -Encoding ascii

Compress-Archive -Path (Join-Path $packageRoot '*') -DestinationPath $zipPath -CompressionLevel Optimal
$zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath (Join-Path $outputRoot "What-Do-You-Do-Windows-v$Version.zip.sha256") -Value "$zipHash  $(Split-Path $zipPath -Leaf)" -Encoding ascii

Write-Output "Package: $packageRoot"
Write-Output "Archive: $zipPath"
Write-Output "Archive SHA-256: $zipHash"
