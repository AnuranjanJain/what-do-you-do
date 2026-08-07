# Release Blockers

Audit date: 2026-08-07

These checks are the minimum gate for a trusted public Windows release. They are
ordered by risk, not by convenience.

## P0 - Must be green

### RB-01: No fabricated activity on failure

- Stop the collector, corrupt a response, and simulate a timeout.
- The UI shows empty or stale real data with a clear status.
- No synthetic record appears in timeline, charts, totals, or AiOS sync.

### RB-02: Authenticated local collector

- Request every read and write route without a token: reject.
- Request with an invalid token: reject.
- Request with a valid token from the app: allow.
- Verify the token is not exposed in URLs, logs, screenshots, or public source.

### RB-03: One Windows collector

- A clean install contains only the supported Flutter collector.
- No Node process or `start-collector.ps1` is launched by WDYD.
- Startup settings cannot create a duplicate collector.
- The release architecture test checks the installed folder and process list.

### RB-04: Atomic persistence

- Kill the app during capture and correction writes.
- Restart and verify the previous valid record is readable.
- Concurrent capture and correction preserve both changes or return a conflict.

## P1 - Must be green before public beta

### RB-05: Sensitive data protection

- Encrypt activity notes, corrections, hackathon plans, and sync state with an OS-
  protected key, or explicitly remove sensitive fields from the privacy promise.
- Test backup, restore, delete, and account separation.

### RB-06: Pairing and sync contract

- AiOS snapshot schema is versioned and runtime-validated.
- Locked, offline, stale, invalid, and updated responses each have a test fixture.
- Activity sync is idempotent across restarts, browser profiles, and retries.

### RB-07: Release artifact security

- Upgrade high npm advisories.
- Sign the Windows binary/installer and publish checksums.
- Verify a clean-machine install and Start Menu/Search behavior.

### RB-08: CI and release-path tests

- CI runs web build, Flutter analyze/test/build, Rust checks, dependency audit, and
  artifact inspection.
- A Windows smoke job covers native activity, tray, close-to-tray, exit, startup,
  settings, and local data persistence.

### RB-09: Authenticated AiOS pairing

- AiOS refuses to start its local API without a generated per-install token.
- WDYD accepts only the paired service identity/version and valid token.
- A fake loopback service and empty-token configuration are rejected in tests.

### RB-10: Reproducible Gmail setup

- A clean install can complete the documented Google read-only OAuth flow without
  asking users to paste refresh tokens or copy secrets into undocumented folders.
- Missing client provisioning, test-user denial, callback failure, cancellation,
  token refresh, and restart states each have explicit recovery UI.

### RB-11: Recoverable companion workers

- Gmail, GitHub, opportunity, notification, and import workers survive transient
  provider failures, persist cursors atomically, and expose last-error/last-success
  timestamps.
- A crash/restart test proves no duplicate sync or silent permanent stop.

### RB-12: AI safety and planning evidence

- Raw email is treated as untrusted model input with strict output schemas.
- Low-confidence/fallback classifications are labeled and do not silently create
  high-impact actions.
- Search coverage, timezone conversion, calendar conflicts, dependency IDs, and
  planner rescheduling have evaluation fixtures.

### RB-13: GitHub coverage and rate limits

- Repository sync documents its coverage, paginates or uses cursors, handles private
  repos/rate limits, and reports stale/partial snapshots.
- Completion and inactivity summaries are not presented as complete from first-page
  samples.

## P2 - Required for quality sign-off

- Narrow viewport has no unintended horizontal overflow.
- Date controls clearly distinguish today, history, future, and no-data states.
- Accessibility checks cover focus, keyboard, semantics, contrast, and reduced motion.
- Classification confidence is labeled as a score and evaluated against corrections.
- Flutter README and root README describe the same platform/runtime behavior.

## Release Decision Rule

Any failed P0 item is an automatic no-go. Any failed P1 item, including RB-09 through
RB-13, requires an explicit
written risk acceptance from the product and security owners; default behavior is to
hold the release.
