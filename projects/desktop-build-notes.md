# Desktop Build Notes

The project now has a Tauri desktop wrapper in `src-tauri`.

## Current status

The web app builds successfully with:

```powershell
npm run build
```

The Tauri project is scaffolded and detected by:

```powershell
npx tauri info
```

The desktop runtime now includes:

- Tauri commands for native runtime status
- Automatic collector startup attempt when the desktop UI mounts
- Start and Stop collector controls in Settings
- Detection of externally running collectors
- Managed collector PID reporting
- Desktop storage under the OS app-data directory
- Managed collector shutdown when the desktop window is destroyed
- Browser fallback that leaves the web dashboard unchanged

The current collector launcher uses the installed Node.js runtime and the source collector script. A distributable release must replace this with a bundled sidecar executable before public installation packages are published.

## Local toolchain status

Installed on June 14, 2026:

- Rust `1.96.0`
- Cargo `1.96.0`
- rustup `1.29.0`

Still required:

- Visual Studio Build Tools 2022
- Desktop development with C++ / MSVC
- Windows SDK

The automated Build Tools installation was cancelled at the Windows elevation prompt and returned installer code `1602`. Approve that installer before running the native build.

After MSVC is installed, open a fresh terminal and run:

```powershell
npm run desktop:dev
npm run desktop:build
```

Validation completed without MSVC:

```powershell
npm run build
cargo fmt --all -- --check
npx tauri info
```

`cargo check` currently stops at `link.exe not found`, before the Tauri application can be linked.

## Desktop app settings

- Product name: What Do You Do
- Identifier: `com.whatdoyoudo.desktop`
- Default window: 1280x820
- Minimum window: 1024x700
- Frontend build output: `dist`
- Dev server: `http://127.0.0.1:5173`
- Collector API: `http://127.0.0.1:17321`
- Desktop data: OS app-data directory under `com.whatdoyoudo.desktop`

## Distribution follow-up

Before producing a public installer:

1. Convert the collector into a Tauri sidecar executable.
2. Bundle the sidecar for the Windows target triple.
3. Remove the release-time dependency on Node.js and the source checkout.
4. Add a system tray and optional start-on-login setting.
5. Build, sign, install, and test the release bundle on a clean Windows account.
