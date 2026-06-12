# Security

## Security Model

What Do You Do is local-first. The collector binds only to `127.0.0.1`, stores activity under the local `data/` directory, and permits browser requests only from localhost or the Tauri webview.

The app does not intentionally persist:

- screenshots
- keystrokes
- private messages
- raw window titles
- executable paths
- browser page content

Only classified session summaries are written to disk. AiOS synchronization is optional, summary-only, and restricted to loopback addresses.

## Implemented Controls

- Loopback-only collector and AiOS endpoints
- Origin validation for browser requests
- JSON-only mutation endpoints
- 64 KB request-body limit
- Input length and enum validation
- HTTP/HTTPS-only external hackathon links
- Tauri Content Security Policy
- Minimal Tauri capability set
- No-store API responses and MIME sniffing protection

## Data at Rest

Activity sessions, notes, corrections, hackathon plans, and sync state are currently stored as local JSON. They are not encrypted by the application. Use an encrypted Windows account or disk and do not share the project data directory with untrusted users.

Application-level encryption is planned before handling highly sensitive notes or mailbox-derived content.

## Reporting

Do not include private activity data, tokens, local file paths, or screenshots in public security reports. Report the minimum reproduction needed and redact personal information.

The latest completed review is documented in [Security Audit - June 12, 2026](projects/security-audit-2026-06-12.md).
