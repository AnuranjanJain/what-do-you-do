# What Do You Do

Initial build for a privacy-first digital wellbeing app that understands what the user actually did across PC and mobile.

## Current MVP

- React + Vite dashboard
- Typed local activity/session models
- Simulated local activity timeline
- Computed dashboard metrics and activity summaries
- Privacy controls surface
- Project AI Agent integration gate
- Live AiOS Assistant bridge for local wellbeing activity sync
- Desktop/mobile widget preview
- Dedicated mobile dashboard preview
- Tauri desktop app wrapper
- Local Windows activity collector for foreground app and idle state
- Real local session persistence under `data/`

## Commands

```powershell
npm install
npm run dev
npm run collector:dev
npm run build
npm run desktop:dev
npm run desktop:build
```

The desktop commands require Rust/Cargo and Visual Studio Build Tools to be installed on the machine. See [desktop build notes](projects/desktop-build-notes.md).

## AiOS Assistant Bridge

`What Do You Do` can run standalone, but the dashboard now connects to the local AiOS Assistant at `http://127.0.0.1:5000`.

Workflow:

1. Start AiOS Assistant from `C:\Users\anura\Documents\Ai Agent`.
2. Unlock AiOS in the browser if the local PIN is enabled.
3. Start this app and the collector with `npm run dev` and `npm run collector:dev`.
4. Open the `Project AI Agent` panel and press `Connect`.
5. Press `Sync` to send new high-level activity sessions to AiOS.

The bridge sends only:

- app name
- broad category
- sub-activity label
- start/end time label
- duration minutes

It does not send screenshots, keystrokes, raw window titles, private messages, browser history, files, or full notes.

## Project Docs

- [Project brief](projects/what-do-you-do.md)
- [Architecture](projects/architecture.md)
- [Local collector notes](projects/local-collector-notes.md)
- [Real data pipeline](projects/real-data-pipeline.md)
