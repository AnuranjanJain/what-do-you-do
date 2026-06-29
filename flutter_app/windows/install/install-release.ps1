$ErrorActionPreference = "Stop"

$packageAppDir = Join-Path $PSScriptRoot "app"
$exeName = "what_do_you_do.exe"
$sourceExe = Join-Path $packageAppDir $exeName
$installDir = Join-Path $env:LOCALAPPDATA "Programs\What Do You Do"
$appVersion = "1.0.1"
$desktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "What Do You Do.lnk"
$startMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$startMenuShortcut = Join-Path $startMenuDir "What Do You Do.lnk"
$uninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\What Do You Do Flutter"

if (-not (Test-Path -LiteralPath $sourceExe)) {
  throw "Release package is missing app\$exeName"
}

Get-Process what_do_you_do -ErrorAction SilentlyContinue | Stop-Process -Force
Get-CimInstance Win32_Process -Filter "Name = 'node.exe'" |
  Where-Object { $_.CommandLine -like "*local-activity-collector.mjs*" } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 500

Remove-Item -LiteralPath $installDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Get-ChildItem -LiteralPath $packageAppDir | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $installDir -Recurse -Force
}

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
