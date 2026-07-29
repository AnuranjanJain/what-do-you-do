# Local Collector Notes

The `linux-browser` branch keeps the loopback collector described below for the
React/Vite client. The `windows-native` branch collects the same signal types
inside the Flutter process through Win32 APIs and does not open port `17321`.

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

## Windows native replacement

The Windows installer copies the Flutter runtime into:

```text
%LOCALAPPDATA%\Programs\What Do You Do\
```

The Windows app Settings screen can create Startup folder shortcuts for:

- launching the app at sign-in
- launching the app hidden in the tray at sign-in

The native app stores sessions under `%LOCALAPPDATA%\What Do You Do\data`.
