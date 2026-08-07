# Desktop Build Notes

The supported installed desktop app is the Flutter Windows client in
`flutter_app/`. The React/Vite browser client remains the Linux v1 surface.
The older Tauri wrapper is historical migration reference only.

## Build and install

Build the Windows release:

```powershell
cd flutter_app
C:\Users\anura\development\flutter\bin\flutter.bat build windows --release
```

Install into the current Windows user profile:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\install\install.ps1
```

Installed location:

```text
%LOCALAPPDATA%\Programs\What Do You Do\
```

## Installed files

The installer copies:

- `what_do_you_do.exe`
- `flutter_windows.dll`
- Flutter `data/`

It also creates Desktop and Start Menu shortcuts and registers the app in the
current user's Windows Installed Apps list.

## Startup services

The Settings screen can create user Startup folder shortcuts for:

- launching the app at sign-in
- launching the app hidden in the tray at sign-in

The native Windows runner keeps a tray icon alive. Closing or minimizing the
window hides it instead of quitting; the Settings screen exposes the explicit
exit action.

The Windows app collects foreground activity in-process through a native Win32
method channel. It does not launch Node, PowerShell polling, or a collector HTTP
server.

Runtime data:

```text
%LOCALAPPDATA%\What Do You Do\data
%LOCALAPPDATA%\What Do You Do\logs
```

## Release artifact

From the repository root, build and verify the complete release package:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-windows-release.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-windows-release.ps1
```

The package contains the full Flutter release directory, installer,
uninstaller, a release manifest, and SHA-256 checksums. The `.exe` alone is
included for inspection, but the ZIP is the usable app package because the
executable requires the adjacent Flutter DLL and data directory.

Recommended asset name:

```text
What-Do-You-Do-Windows-v1.0.2.zip
```

Release ZIP layout:

```text
Install-WhatDoYouDo.ps1
app/
|-- what_do_you_do.exe
|-- flutter_windows.dll
|-- data/
|-- uninstall.ps1
```

## Validation checklist

```powershell
npm run build
cd flutter_app
C:\Users\anura\development\flutter\bin\flutter.bat analyze
C:\Users\anura\development\flutter\bin\flutter.bat test
C:\Users\anura\development\flutter\bin\flutter.bat build windows --release
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\install\install.ps1
```

Then verify:

- installed app launches
- live activity appears without a Node process or port `17321` listener
- Settings shows startup, background tray, native activity, hide, and exit controls
