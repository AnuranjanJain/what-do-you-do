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

## Local machine blockers

This machine still needs native desktop build dependencies:

- Rust
- Cargo
- rustup
- Visual Studio Build Tools with MSVC and Windows SDK components

Install Rust from:

```text
https://rustup.rs/
```

Install Visual Studio Build Tools from:

```text
https://aka.ms/vs/17/release/vs_BuildTools.exe
```

After those are installed, run:

```powershell
npm run desktop:dev
npm run desktop:build
```

## Desktop app settings

- Product name: What Do You Do
- Identifier: `com.whatdoyoudo.desktop`
- Default window: 1280x820
- Minimum window: 1024x700
- Frontend build output: `dist`
- Dev server: `http://127.0.0.1:5173`
