# Security Audit - June 12, 2026

## Scope

This review covered the React dashboard, local Node.js collector, AiOS bridge, local JSON persistence, external links, npm dependencies, and Tauri desktop configuration.

## Findings Resolved

### Local API request protection

Collector mutation endpoints now reject requests from untrusted browser origins, require `application/json`, limit request bodies to 64 KB, and apply request/header timeouts.

Verified responses:

- trusted localhost origin: `200`
- hostile web origin: `403`
- incorrect content type: `415`
- oversized request body: `413`

### Local-only AiOS boundary

Browser and collector AiOS URLs are now restricted to `localhost`, `127.0.0.1`, or IPv6 loopback. Remote URLs are rejected before activity summaries can be transmitted.

### Collector privacy boundary

The public `/activity` response no longer exposes raw foreground window titles or executable paths. The `/health` response no longer reveals the absolute local storage directory.

The public snapshot is limited to:

- capture time
- idle duration
- platform
- process name
- raw-content storage flag

### Desktop webview hardening

The Tauri app now has an explicit Content Security Policy covering local collector/AiOS connections, Tauri IPC, local assets, scripts, styles, forms, frames, and embedded objects.

### External link validation

Hackathon links now permit only `http` and `https` URLs at both storage and rendering boundaries.

## Verification

- TypeScript and Vite production build passed.
- Node collector syntax check passed.
- `npm audit` reported zero known vulnerabilities.
- Tauri CLI parsed and reported the configured CSP.
- Isolated collector probes used a temporary data directory and did not modify real activity records.

## Remaining Risks

Local JSON data is not encrypted by the application. Activity sessions, notes, hackathon plans, and sync state currently rely on Windows account and disk security.

The Tauri desktop binary was not compiled during this audit because Rust, Cargo, MSVC, and the Windows SDK are not installed on the test machine. The web build and Tauri configuration checks passed.

## Recommended Next Steps

1. Encrypt sensitive local fields with a key protected by Windows DPAPI or the OS credential vault.
2. Add automated collector security tests to CI.
3. Add Cargo dependency auditing once the Rust toolchain is installed.
4. Sign desktop release artifacts and publish checksums.
