# Technical Debt Report

Audit date: 2026-08-07  
Scope: WDYD repository at `3048213`

## Debt Summary

The largest debt is architectural rather than stylistic: the project migrated from
a Node/Tauri/browser collector to a Windows Flutter in-process collector, but the
old implementation remains active in code, installer helpers, docs, and startup
settings. This creates multiple sources of truth for the same product behavior.

| Area | Debt | Interest if deferred | Priority |
| --- | --- | --- | --- |
| Runtime ownership | Node, Tauri, and Flutter collectors coexist | Every bug fix needs multiple implementations | P0 |
| Persistence | Plain JSON without atomic writes or locks | Corruption and lost edits become harder to recover | P1 |
| React structure | `src/main.tsx` and `src/styles.css` are large feature containers | High regression surface and weak testability | P2 |
| API contracts | JSON casts without runtime schemas or versions | Client/agent drift becomes silent | P1 |
| Test system | No React, collector, installer, tray, or CI coverage | Green tests do not represent the release path | P1 |
| Configuration | Developer-specific AiOS identity in source | Broken installs and privacy leakage | P1 |
| Startup | Retired collector shortcut remains in settings | Duplicate services and confusing setup | P1 |
| Documentation | Flutter README describes old Node setup | Developers launch the wrong architecture | P2 |
| Versioning | Root, Flutter, and installer versions differ | Ambiguous release/support diagnostics | P3 |

## Debt Register

### TD-01 - Runtime consolidation

**Files:** `scripts/collector/local-activity-collector.mjs`, `src-tauri/src/lib.rs`,
`flutter_app/lib/src/collector_api.dart`, `flutter_app/windows/install/start-collector.ps1`.

**Current state:** Three collection routes can be discovered. The Flutter app is the
intended Windows client, but the old HTTP collector and Tauri launcher remain usable.

**Refactor:** Put the Windows collector behind a native interface only. Move the
Node collector and Tauri wrapper under a clearly historical/Linux-only boundary and
remove their Windows startup references.

**Payoff:** One classification model, one persistence contract, fewer security
surfaces, and smaller release artifacts.

**Effort:** 3-5 engineering days plus install regression testing.

### TD-02 - Persistence abstraction

**Files:** Node persistence functions at `scripts/collector/local-activity-collector.mjs:247-277`;
Flutter persistence at `flutter_app/lib/src/collector_api.dart:212-292`.

**Current state:** Both implementations serialize full JSON snapshots and write them
directly. There is no revision number or writer lock.

**Refactor:** Introduce a repository interface with atomic replace, revision checks,
bounded backups, corruption recovery, and a future encrypted backend.

**Payoff:** Data integrity becomes testable and storage can later move to SQLite
without changing dashboard contracts.

**Effort:** 3-4 engineering days.

### TD-03 - Feature-oriented frontend boundaries

**Files:** `src/main.tsx`, `src/styles.css`, `flutter_app/lib/src/shell.dart`.

**Current state:** Fetching, state, navigation, layouts, and feature-specific
controls are interleaved in large files.

**Refactor:** Split `activity`, `timeline`, `hackathons`, `college`, `agent`, and
`settings` into feature modules. Keep API hooks and view models outside render code.

**Payoff:** Smaller review units, focused tests, and fewer accidental layout changes.

**Effort:** 5-8 engineering days; do after runtime consolidation.

### TD-04 - Versioned local contracts

**Files:** `src/services/collector.ts`, `src/services/hackathons.ts`,
`src/services/aios.ts`, `flutter_app/lib/src/agent_desktop_api.dart`, model files.

**Current state:** Several `response.json()` values are cast directly to TypeScript
types. AiOS endpoints are discovered opportunistically across ports.

**Refactor:** Define a shared contract document, add response schema validation,
include API/data versions, and expose one pairing descriptor.

**Payoff:** Clear incompatibility errors instead of malformed UI and fewer discovery
requests.

**Effort:** 4-6 engineering days.

### TD-05 - Test pyramid and CI

**Files:** `package.json`, `flutter_app/test/`, installer scripts; no `.github` workflow.

**Current state:** Flutter unit/widget tests are the strongest coverage. React and
collector behavior are mostly validated by the build and manual probing.

**Refactor:** Add React tests, Node collector integration tests using a temporary
data directory, Flutter Windows channel fakes, packaged smoke tests, and CI gates.

**Payoff:** Green status becomes meaningful for the actual release path.

**Effort:** 5-10 engineering days.

### TD-06 - Companion-service contract and pairing

**Files:** WDYD AiOS bridge clients; AiOS `app/routes.py:2217-2232`,
`app/services/api_auth.py`, and runtime discovery.

**Current state:** Clients scan loopback ports and accept self-reported service
metadata. Token presence is configuration-dependent and there is no shared schema,
identity, or compatibility handshake.

**Refactor:** Define one paired local-service descriptor with a required token,
service identity, protocol version, capabilities, and freshness. Validate it in both
clients and add fake-service/invalid-token tests.

**Payoff:** Fewer confused-deputy failures and clear offline/locked/version-mismatch
states.

**Effort:** 3-5 engineering days.

### TD-07 - AiOS background work needs job semantics

**Files:** AiOS worker scripts, `app/services/workers.py`, Gmail/GitHub sync, and
WDYD status consumers.

**Current state:** Provider work runs in timer loops with direct JSON checkpoints,
serial network calls, no durable retry budget, and no stage-level progress.

**Refactor:** Add durable jobs/cursors, atomic checkpoints, retry/backoff, rate-limit
handling, and structured run telemetry consumed by both desktop clients.

**Payoff:** Recoverable sync, predictable latency, and honest freshness indicators.

**Effort:** 6-10 engineering days.

### TD-08 - AI evidence and evaluation contract

**Files:** AiOS classifier, email intelligence, semantic search, planning engine,
and WDYD AI summary cards.

**Current state:** Raw email text is placed in prompts, fallback confidence is fixed,
search is newest-300 lexical retrieval, and planner outputs lack timezone/conflict
evaluation.

**Refactor:** Store model/provider/version, evidence references, bounded schemas,
retrieval coverage, and evaluation fixtures for injection, dates, conflicts, and
low-confidence cases.

**Payoff:** Safer local intelligence and measurable quality instead of plausible
demo output.

**Effort:** 6-12 engineering days.

## Recommended Debt Order

1. Remove the Windows legacy runtime ambiguity.
2. Add authenticated, atomic, encrypted storage primitives.
3. Add contracts and end-to-end release tests.
4. Split frontend modules and improve measured performance.
5. Harden the AiOS pairing and background-job contract.
6. Add AI evidence/evaluation coverage.
7. Normalize versions and clean docs/dependencies.
