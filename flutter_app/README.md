# What Do You Do - Windows Flutter App

Native-rendered Windows app for the local-first `What Do You Do` activity
intelligence system. Linux v1 uses the React/Vite browser dashboard in the
repository root; Android and iOS remain future companion targets.

The client reads privacy-filtered sessions from the local collector at
`http://127.0.0.1:17321`. It does not collect operating-system signals itself.
When AiOS Desktop is running, the app pairs through the loopback-only local API
and reads approved service summaries without sending raw private activity.

## Windows development

Start the collector from the repository root:

```powershell
npm run collector:dev
```

Then run Flutter:

```powershell
C:\Users\anura\development\flutter\bin\flutter.bat run -d windows
```

Build:

```powershell
C:\Users\anura\development\flutter\bin\flutter.bat build windows --release
```

Install for Windows Search / Start Menu:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\install\install.ps1
```

The installer copies the local collector into the app install directory and
adds `start-collector.ps1`. The Settings screen can create Windows Startup
shortcuts for the app and for this hidden collector launcher. The Windows app
also keeps a tray icon: closing or minimizing hides the window, and Settings
contains the explicit app exit action.

The complete release folder is:

```text
build\windows\x64\runner\Release\
```

Run checks:

```powershell
C:\Users\anura\development\flutter\bin\flutter.bat analyze
C:\Users\anura\development\flutter\bin\flutter.bat test
```
