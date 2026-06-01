# What Do You Do

Initial build for a privacy-first digital wellbeing app that understands what the user actually did across PC and mobile.

## Current MVP

- React + Vite dashboard
- Typed local activity/session models
- Simulated local activity timeline
- Computed dashboard metrics and activity summaries
- Privacy controls surface
- Project AI Agent integration gate
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

## Project Docs

- [Project brief](projects/what-do-you-do.md)
- [Architecture](projects/architecture.md)
- [Local collector notes](projects/local-collector-notes.md)
- [Real data pipeline](projects/real-data-pipeline.md)
