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
- `start-collector.ps1`
- `collector/local-activity-collector.mjs`
- `collector/get-windows-activity.ps1`

It also creates Desktop and Start Menu shortcuts and registers the app in the
current user's Windows Installed Apps list.

## Startup services

The Settings screen can create user Startup folder shortcuts for:

- launching the app at sign-in
- launching the app hidden in the tray at sign-in
- launching the packaged local collector at sign-in

The native Windows runner keeps a tray icon alive. Closing or minimizing the
window hides it instead of quitting; the Settings screen exposes the explicit
exit action.

The collector launcher is hidden, checks whether `http://127.0.0.1:17321/health`
is already online, and starts Node only when needed.

Runtime data:

```text
%LOCALAPPDATA%\What Do You Do\data
%LOCALAPPDATA%\What Do You Do\logs
```

## Release artifact

The distributable release should zip the full Flutter release directory plus
the install helper files. The `.exe` alone is included for inspection, but the
ZIP is the usable app package because the executable requires the adjacent
Flutter DLL and data directory.

Recommended asset name:

```text
What-Do-You-Do-Windows-v1.0.1.zip
```

Release ZIP layout:

```text
Install-WhatDoYouDo.ps1
app/
|-- what_do_you_do.exe
|-- flutter_windows.dll
|-- data/
|-- start-collector.ps1
|-- uninstall.ps1
`-- collector/
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
- packaged collector files exist
- `GET http://127.0.0.1:17321/health` returns `200`
- Settings shows startup, background tray, collector, hide, and exit controls
