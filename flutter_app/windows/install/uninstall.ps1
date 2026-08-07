$ErrorActionPreference = "Stop"

$installDir = Join-Path $env:LOCALAPPDATA "Programs\What Do You Do"
$desktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "What Do You Do.lnk"
$startMenuShortcut = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\What Do You Do.lnk"
$startupAppShortcut = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\What Do You Do.lnk"
$startupCollectorShortcut = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\What Do You Do Collector.lnk"
$uninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\What Do You Do Flutter"

$managedRoot = [System.IO.Path]::GetFullPath($installDir).TrimEnd('\') + '\'
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
  Where-Object {
    $_.Name -eq 'what_do_you_do.exe' -and $_.ExecutablePath -and
      $_.ExecutablePath.StartsWith($managedRoot, [StringComparison]::OrdinalIgnoreCase)
  } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 300

Remove-Item -LiteralPath $desktopShortcut -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $startMenuShortcut -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $startupAppShortcut -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $startupCollectorShortcut -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $uninstallKey -Recurse -Force -ErrorAction SilentlyContinue

$cleanup = "Start-Sleep -Seconds 2; Remove-Item -LiteralPath '$($installDir.Replace("'", "''"))' -Recurse -Force"
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
  "-NoProfile",
  "-ExecutionPolicy",
  "Bypass",
  "-Command",
  $cleanup
)
