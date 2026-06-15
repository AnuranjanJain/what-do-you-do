# What Do You Do - Flutter Client

Native-rendered Windows, Android, and iOS client for the local-first
`What Do You Do` activity intelligence system.

The client reads privacy-filtered sessions from the local collector at
`http://127.0.0.1:17321`. It does not collect operating-system signals itself.
When AiOS Desktop is running, the collector pairs with it automatically and
sends only closed, privacy-filtered activity summaries to the local dashboard.

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

The complete release folder is:

```text
build\windows\x64\runner\Release\
```

Run checks:

```powershell
C:\Users\anura\development\flutter\bin\flutter.bat analyze
C:\Users\anura\development\flutter\bin\flutter.bat test
```
