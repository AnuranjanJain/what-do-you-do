# Flutter Windows App

The native Windows application UI lives in `flutter_app/`.

Flutter is the installed Windows app surface. The React/Vite browser dashboard
remains the Linux v1 surface. Each platform owns its local collection runtime
while keeping the same privacy and data contracts.

## Reused system boundary

```text
Local activity signals
        |
        v
Win32 activity method channel inside the Flutter process
        |
        +--> daily local JSON storage under LocalAppData
        |
        +--> Windows Flutter app
        |
        +--> optional approved AiOS summaries

Linux browser client --> Linux local collector/API --> Linux local JSON
```

The Windows Flutter client currently owns:

- foreground-window and idle snapshots through Win32
- classification, session rollovers, and daily local JSON persistence in Dart
- local hackathon and settings persistence
- AiOS Desktop pairing through `GET /api/local/pairing`
- AiOS Desktop service reads through `GET /api/live`, `GET /api/workers`,
  `GET /api/desktop/status`, `GET /api/hackathons`, `GET /api/placements`,
  and `GET /api/neopat`

No raw window title, screenshot, keystroke, message, or file content is sent to
the UI.

## Implemented Windows app screens

- Responsive desktop navigation
- Dashboard with real local metrics
- Focus bar chart and activity mix chart
- Date-aware activity timeline
- Hackathon board
- Privacy control center
- Project AI Agent feature surface
- Desktop and widget previews
- Runtime settings, light/dark mode, and Windows startup service controls

## Development

Flutter SDK location on the current development machine:

```text
C:\Users\anura\development\flutter
```

Run the Windows Flutter app:

```powershell
cd flutter_app
C:\Users\anura\development\flutter\bin\flutter.bat run -d windows
```

Build Windows:

```powershell
C:\Users\anura\development\flutter\bin\flutter.bat build windows --release
```

Install Windows:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\install\install.ps1
```

The unpackaged Windows output is:

```text
flutter_app\build\windows\x64\runner\Release\
```

Keep the entire Release directory together; the executable depends on the
adjacent Flutter DLL and data directory.

The installer copies only the Flutter release. Settings can create a Windows
Startup shortcut for the app in visible or hidden tray mode.

## Next Windows app work

1. Add correction and note editing from Flutter.
2. Add create/edit/delete forms for hackathons.
3. Add native Windows notifications.
4. Sign the Flutter Windows release.
5. Revisit Android/iOS as future companion clients after the Windows app is stable.

The React/Vite client remains in the repository as the Linux/browser client.
The Tauri wrapper remains historical migration reference unless it is removed
in a later cleanup.
