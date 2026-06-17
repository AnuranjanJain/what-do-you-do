# Flutter Migration

The primary application UI now lives in `flutter_app/`.

Flutter replaces the HTML/CSS/WebView interface with a natively compiled,
canvas-rendered client for Windows, Android, and iOS. The local collector and
privacy boundary remain unchanged.

## Reused system boundary

```text
Windows activity signals
        |
        v
Node local collector on 127.0.0.1:17321
        |
        +--> daily local JSON storage
        |
        +--> Flutter Windows / Android / iOS client
        |
        +--> optional approved AiOS summaries
```

The Flutter client currently uses:

- `GET /health`
- `GET /sessions?date=YYYY-MM-DD`
- `GET /hackathons`
- AiOS Desktop pairing through `GET /api/local/pairing`
- AiOS Desktop service reads through `GET /api/live`, `GET /api/workers`,
  `GET /api/desktop/status`, `GET /api/hackathons`, `GET /api/placements`,
  and `GET /api/neopat`

No raw window title, screenshot, keystroke, message, or file content is sent to
the UI.

## Implemented Flutter screens

- Responsive desktop and mobile navigation
- Dashboard with real local metrics
- Focus bar chart and activity mix chart
- Date-aware activity timeline
- Hackathon board
- Privacy control center
- Project AI Agent feature surface
- Desktop and mobile widget previews
- Runtime settings and light/dark mode

## Development

Flutter SDK location on the current development machine:

```text
C:\Users\anura\development\flutter
```

Run the collector from the repository root:

```powershell
npm run collector:dev
```

Run Flutter:

```powershell
cd flutter_app
C:\Users\anura\development\flutter\bin\flutter.bat run -d windows
```

Build Windows:

```powershell
C:\Users\anura\development\flutter\bin\flutter.bat build windows --release
```

The unpackaged Windows output is:

```text
flutter_app\build\windows\x64\runner\Release\
```

Keep the entire Release directory together; the executable depends on the
adjacent Flutter DLL and data directory.

## Next migration work

1. Move the collector into a bundled native sidecar.
2. Add correction and note editing from Flutter.
3. Add create/edit/delete forms for hackathons.
4. Add approved-summary sync controls to the Flutter UI.
5. Add native Windows notifications, tray behavior, and startup settings.
6. Implement Android/iOS companion discovery instead of assuming loopback.
7. Package and sign the Flutter Windows release.

The React/Tauri client remains in the repository as a migration reference. It
should be retired after the Flutter client reaches feature parity.
