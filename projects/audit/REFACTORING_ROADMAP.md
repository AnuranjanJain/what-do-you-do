# Refactoring Roadmap

Audit date: 2026-08-07  
Goal: move WDYD from a working prototype to a trustworthy local-first Windows release
while preserving the Linux browser client and AiOS boundary.

## Stage 0 - Establish the release boundary

**Priority:** P0  
**Estimate:** 2-3 days

- Declare Flutter Windows as the only packaged Windows runtime.
- Remove Tauri/Node collector startup from Windows release instructions.
- Mark Node collector as Linux/browser-only or historical.
- Remove hardcoded developer path/thread data and use pairing metadata.
- Add a release architecture test that fails if the Windows bundle contains the old
  launcher.

**Exit criteria:** A clean install has one collector, one data directory, and one
documented startup path.

## Stage 1 - Protect data integrity

**Priority:** P0/P1  
**Estimate:** 4-6 days

- Make capture single-flight in both clients or remove the retired implementation.
- Add atomic file replacement, writer serialization, revision numbers, and backup
  recovery.
- Preserve last-known real sessions with an explicit stale marker.
- Disable simulator data in production builds; keep it only behind an explicit demo
  flag.

**Exit criteria:** Process kill, slow capture, concurrent correction, and offline
  tests do not lose or fabricate user records.

## Stage 2 - Secure local boundaries

**Priority:** P0/P1  
**Estimate:** 5-8 days

- Add per-install authentication to local collector routes.
- Protect auth material with Windows DPAPI or the credential vault.
- Encrypt sensitive local files/fields and document export/delete/recovery.
- Remove `ExecutionPolicy Bypass` from any retired path; sign required installers.
- Upgrade npm advisory ranges and add dependency audit policy.
- Require AiOS local API pairing tokens, protect Gmail token encryption with an
  OS-backed key, and make Google OAuth provisioning reproducible for clean installs.

**Exit criteria:** Unauthenticated local requests fail; a copied data folder is not
plaintext-readable; release artifacts have provenance checks.

## Stage 3 - Contract and release testing

**Priority:** P1  
**Estimate:** 7-12 days

- Add React unit tests and browser smoke tests for live, stale, empty, locked, and
  invalid data states.
- Add Node/Flutter persistence and capture tests with temporary storage.
- Add AiOS snapshot fixtures, version mismatch tests, and locked/offline tests.
- Test Flutter Windows tray, close-to-tray, exit, startup, and native activity
  channel on a clean machine.
- Add CI for npm build, Flutter analyze/test/build, Rust check/clippy, audit, and
  artifact inspection.
- Add AiOS contract fixtures for required pairing tokens, OAuth provisioning,
  partial Gmail sync, GitHub rate limits, worker crashes, and stale snapshots.
- Run the companion AiOS test suite from a clean worktree; the current adjacent
  worktree is dirty and cannot serve as clean release evidence.

**Exit criteria:** CI represents the actual release path and blocks known regressions.

## Stage 4 - Contract-first feature modularization

**Priority:** P1/P2  
**Estimate:** 8-12 days

- Define a versioned local activity and AiOS snapshot schema.
- Add runtime validation and structured error states.
- Split React and Flutter shells by feature.
- Move polling and data orchestration into cancellable services.
- Add server-side/idempotent AiOS sync with a durable cursor.
- Replace AiOS loopback port scanning with one authenticated pairing descriptor.
- Separate email/GitHub/model jobs from request handlers and expose stage-level
  progress to WDYD.
- Make semantic-search coverage, model fallback, and planner timezone semantics
  explicit in the shared snapshot contract.

**Exit criteria:** Features can be tested independently and client drift produces a
clear compatibility message.

## Stage 5 - Measured performance and quality intelligence

**Priority:** P2  
**Estimate:** 6-10 days

- Measure startup, memory, CPU, disk writes, capture latency, and bridge latency.
- Replace full daily rewrites with an indexed/transactional store if measurements
  justify it.
- Calibrate classification confidence and create a local correction evaluation set.
- Evaluate AiOS prompt injection boundaries, retrieval recall, deadline extraction,
  timezone handling, dependency scheduling, and fallback behavior with private
  fixtures.
- Improve narrow viewport, keyboard, contrast, and reduced-motion behavior.

**Exit criteria:** Performance budgets and category quality thresholds are published
and enforced.

## Recommended First Milestone

Complete Stage 0 and Stage 1 together. Until runtime ownership is unambiguous and
real data cannot be silently replaced or corrupted, feature expansion increases risk
faster than value.
