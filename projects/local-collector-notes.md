# Local Collector Notes

The project now includes a local Windows activity collector for development.

## What it collects

- Foreground app process name
- Foreground window title summary
- Idle time from Windows last-input APIs
- Local timestamp

## What it does not collect

- No screenshots
- No keystrokes
- No private message contents
- No browser page contents
- No files
- No server upload

The collector runs on:

```text
http://127.0.0.1:17321
```

Available endpoints:

- `/health`
- `/activity`
- `/sessions`

## Commands

Start the web app:

```powershell
npm run dev
```

Start the local collector in another terminal:

```powershell
npm run collector:dev
```

When the collector is running, the dashboard switches from simulator fallback to live desktop collector mode.
