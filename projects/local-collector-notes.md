# Local Collector Notes

The project includes a local Windows activity collector used by both the Linux
browser dashboard and the Windows Flutter app.

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
- `/sessions?date=YYYY-MM-DD`
- `/dates`

Daily session files are stored under:

```text
data/activity-sessions/YYYY-MM-DD.json
```

## Commands

Start the web app:

```powershell
npm run dev
```

Start the local collector in another terminal:

```powershell
npm run collector:dev
```

When the collector is running, the dashboard switches from simulator fallback to live desktop collector mode. The dashboard can also view persisted history by date.

## Windows installed app startup

The Flutter installer copies the collector scripts into:

```text
%LOCALAPPDATA%\Programs\What Do You Do\collector\
```

It also installs:

```text
%LOCALAPPDATA%\Programs\What Do You Do\start-collector.ps1
```

The Windows app Settings screen can create Startup folder shortcuts for:

- launching the app at sign-in
- launching the hidden local collector at sign-in

The packaged launcher stores sessions under `%LOCALAPPDATA%\What Do You Do\data`
and logs under `%LOCALAPPDATA%\What Do You Do\logs`.
