$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$workspaceRoot = Resolve-Path (Join-Path $repoRoot "..")
$releaseDir = Join-Path $repoRoot "build\windows\x64\runner\Release"
$exeName = "what_do_you_do.exe"
$sourceExe = Join-Path $releaseDir $exeName
$installDir = Join-Path $env:LOCALAPPDATA "Programs\What Do You Do"
$releaseMetadataPath = Join-Path $workspaceRoot "release.json"
$appVersion = if (Test-Path -LiteralPath $releaseMetadataPath) {
  [string]((Get-Content -LiteralPath $releaseMetadataPath -Raw | ConvertFrom-Json).windows_version)
} else {
  "1.0.2"
}
$desktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "What Do You Do.lnk"
$startMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$startMenuShortcut = Join-Path $startMenuDir "What Do You Do.lnk"
$uninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\What Do You Do Flutter"

if (-not (Test-Path -LiteralPath $sourceExe)) {
  throw "Release executable not found. Build first with: flutter build windows --release"
}

$resolvedRelease = (Resolve-Path -LiteralPath $releaseDir).Path
$resolvedRepo = (Resolve-Path -LiteralPath $repoRoot).Path
if (-not $resolvedRelease.StartsWith($resolvedRepo, [StringComparison]::OrdinalIgnoreCase)) {
  throw "Refusing to install from outside the Flutter app workspace."
}

$managedRoots = @($sourceExe, $installDir) | ForEach-Object {
  [System.IO.Path]::GetFullPath($_).TrimEnd('\') + '\'
}
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
  Where-Object {
    $process = $_
    $process.Name -eq $exeName -and $process.ExecutablePath -and
      (($managedRoots | Where-Object {
        $process.ExecutablePath.StartsWith($_, [StringComparison]::OrdinalIgnoreCase)
      }).Count -gt 0)
  } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 500

Remove-Item -LiteralPath $installDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Get-ChildItem -LiteralPath $releaseDir | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $installDir -Recurse -Force
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "uninstall.ps1") -Destination $installDir -Force

$installedExe = Join-Path $installDir $exeName
$installedUninstallScript = Join-Path $installDir "uninstall.ps1"
$shell = New-Object -ComObject WScript.Shell
foreach ($shortcutPath in @($desktopShortcut, $startMenuShortcut)) {
  $shortcut = $shell.CreateShortcut($shortcutPath)
  $shortcut.TargetPath = $installedExe
  $shortcut.WorkingDirectory = $installDir
  $shortcut.IconLocation = "$installedExe,0"
  $shortcut.Description = "What Do You Do"
  $shortcut.Save()
}

New-Item -Path $uninstallKey -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name "DisplayName" -Value "What Do You Do" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name "DisplayVersion" -Value $appVersion -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name "Publisher" -Value "Anu Ranjan" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name "DisplayIcon" -Value $installedExe -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name "InstallLocation" -Value $installDir -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name "UninstallString" -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$installedUninstallScript`"" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name "NoModify" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $uninstallKey -Name "NoRepair" -Value 1 -PropertyType DWord -Force | Out-Null

Start-Process -FilePath $installedExe -WorkingDirectory $installDir
Write-Output "Installed and launched: $installedExe"
