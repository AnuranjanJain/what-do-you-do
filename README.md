# What Do You Do

<p align="center">
  <img src="docs/readme-banner.svg" alt="What Do You Do animated banner" />
</p>

<p align="center">
  <b>A cute local-first activity dashboard that answers the question: where did my day go?</b>
</p>

<p align="center">
  <img alt="Local first" src="https://img.shields.io/badge/local--first-yes-FFD84D?style=for-the-badge&labelColor=1F211D" />
  <img alt="Windows app" src="https://img.shields.io/badge/Windows-native%20Flutter-5ED9E8?style=for-the-badge&labelColor=1F211D" />
  <img alt="Desktop only" src="https://img.shields.io/badge/browser%20server-not%20required-DFF0E4?style=for-the-badge&labelColor=1F211D" />
  <img alt="Privacy" src="https://img.shields.io/badge/raw%20data-on%20device-DFF0E4?style=for-the-badge&labelColor=1F211D" />
</p>

## Peek

<p align="center">
  <img src="docs/screenshots/theme-switch.gif" alt="Light and dark mode preview" />
</p>

<table>
  <tr>
    <td><img src="docs/screenshots/dashboard-light.png" alt="Light Windows desktop dashboard" /></td>
    <td><img src="docs/screenshots/dashboard-dark.png" alt="Dark Windows desktop dashboard" /></td>
  </tr>
</table>

## The Vibe

This branch is the installed **Windows-native Flutter app**. It owns its packaged
collector, reads local activity, and talks to AiOS through loopback-only approved
summaries. No Vite server or browser dashboard is required on Windows.

The Linux/browser implementation is preserved on the
[`linux-browser`](https://github.com/AnuranjanJain/what-do-you-do/tree/linux-browser)
branch.

| App | Job |
| --- | --- |
| **What Do You Do** | Observes activity and explains where the day went. |
| **[AiOS Assistant](https://github.com/AnuranjanJain/aios-assistant)** | Connects mail, projects and memory, then plans what should happen next. |

WDYD v2 keeps the boundary clean:

- **AiOS owns Email Intelligence**: Gmail OAuth, encrypted tokens, local email sync, Ollama analysis, semantic search, and daily/weekly planning.
- **AiOS owns Command Planner rows**: hackathons, repo work, email tasks, learning videos, goals, work done, work left, and next questions.
- **WDYD displays the result**: planner cards, today/week/month command rows, urgent email counts, deadlines, waiting-for, suggestions, and focus summaries.

## How It Works

```mermaid
flowchart LR
  windows["WDYD Flutter EXE"] --> collector["App-owned local collector"]
  signals["Windows activity signals"] --> collector
  collector --> store["Local JSON data"]
  store --> windows
  windows --> dashboard["Dashboard + widgets + hackathons"]
  dashboard --> privacy["Privacy controls"]
  dashboard -. approved summaries only .-> aios["AiOS / Project AI Agent"]
  aios --> planner["Planner summaries + command rows"]
  planner --> dashboard
```

No screenshots, keystrokes, private messages, raw browser history, or full notes are sent to the agent. The bridge shares only approved summaries.

## Platform Branches

| Branch | Product surface |
| --- | --- |
| `windows-native` | Installed Flutter desktop app with app-owned local services |
| `linux-browser` | React/Vite browser dashboard and Linux collector workflow |

## Install It On Windows

```powershell
cd flutter_app
C:\Users\anura\development\flutter\bin\flutter.bat build windows --release
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\install\install.ps1
```

After install, Windows Search should find **What Do You Do** from the Start Menu shortcut.

Launch the installed app directly. Do not run `npm run dev` or keep a browser
window open. Google/email intelligence remains owned by the installed AiOS app.

In **Settings**, Windows users can enable:

- launch the app at sign-in
- open the app in the background tray at sign-in
- start the packaged local collector at sign-in
- hide the window to the tray or fully exit the app

For Windows development:

```powershell
cd flutter_app
C:\Users\anura\development\flutter\bin\flutter.bat run -d windows
```

## Project Map

```text
.
|-- flutter_app/              Windows native Flutter app
|   |-- lib/src/               app shell, controller, APIs, models, theme
|   |-- test/                  layout, summary, parsing, settings tests
|   `-- windows/install/       local Windows install + uninstall scripts
|-- scripts/                  collector source packaged by the Windows installer
|-- data/                     local-only session, sync, and hackathon data
|-- docs/screenshots/         README screenshots and GIF previews
`-- projects/                 architecture notes and build plans
```

## Local APIs

```text
GET  /health
GET  /sessions?date=YYYY-MM-DD
GET  /hackathons
POST /hackathons/save
POST /hackathons/timeline
POST /hackathons/delete
```

AiOS bridge endpoints are discovered through loopback pairing, usually at `http://127.0.0.1:5050`.

```text
GET /api/local/pairing
GET /api/live
GET /api/workers
GET /api/hackathons
GET /api/placements
GET /api/neopat
GET /api/intelligence/today
GET /api/intelligence/search?q=internship
```

## Privacy Promise

Raw activity stays on device by default. The app is designed around boring-but-good rules: loopback APIs, local JSON storage, visible sync controls, and agent features that unlock only when the companion desktop agent is installed and paired.

More detail lives in [SECURITY.md](SECURITY.md), [projects/architecture.md](projects/architecture.md), and [projects/flutter-migration.md](projects/flutter-migration.md).
