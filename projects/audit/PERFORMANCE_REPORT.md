# Performance Report

Audit date: 2026-08-07

## Current Measurements

The release web build completed with the following Vite output:

| Artifact | Size | Gzip |
| --- | ---: | ---: |
| JavaScript | 265.63 kB | 80.22 kB |
| CSS | 62.57 kB | 11.84 kB |
| HTML | 0.40 kB | not reported |

These are bundle measurements only. No startup, capture latency, disk I/O, battery,
memory, or packaged Windows measurements are currently recorded.

## Hotspots

### P-01 - Fixed-rate asynchronous sampling

- Problem: Node runs PowerShell every 2.5 seconds at
  `scripts/collector/local-activity-collector.mjs:515-537,1010-1012`. Flutter uses
  `Timer.periodic` at `flutter_app/lib/src/collector_api.dart:54-63`.
- Impact: Expensive captures can overlap and consume CPU while the prior capture is
  still being normalized or persisted.
- Suggested fix: Single-flight capture, adaptive polling when idle, and instrumentation
  for capture, normalization, and write duration.
- Complexity: Low to medium. Priority: P1.

### P-02 - Full daily JSON rewrites

- Problem: Each update serializes and writes the complete daily record. Node does so
  at `scripts/collector/local-activity-collector.mjs:247-259`; Flutter does so at
  `flutter_app/lib/src/collector_api.dart:253-266`.
- Impact: Disk churn grows with the number of sessions; larger files increase write
  latency and crash exposure.
- Suggested fix: Append-only event log with periodic compaction, or SQLite with an
  indexed session table and a transaction.
- Complexity: High. Priority: P1 for long-running users.

### P-03 - Browser polling fans out across features

- Problem: `src/main.tsx:269-280` refreshes several AiOS feeds every 30 seconds,
  while the main session feed refreshes every three seconds at `:189-216`.
- Impact: Repeated local HTTP and JSON work, even when no underlying data changed.
- Suggested fix: Use a consolidated snapshot, ETag/version polling, or event-driven
  invalidation. Add request cancellation on route change/unmount.
- Complexity: Medium. Priority: P2.

### P-04 - AiOS backlog drains sequentially in batches of five

- Problem: `src/services/aios.ts:168-201` sends sessions one at a time and caps each
  pass at five.
- Impact: A long offline period creates a slow catch-up path and more repeated timer
  work.
- Suggested fix: Add an idempotent batch endpoint or bounded concurrency with retry
  backoff and a durable cursor.
- Complexity: Medium. Priority: P1.

### P-05 - AiOS Gmail sync performs serial full-message fetches

- Problem: `C:\Users\anura\Documents\Ai Agent\app/services/email_intelligence.py:423-468`
  fetches each message individually with `format="full"` after history/recent
  discovery. There is no provider backoff, batch fetch, or concurrency budget.
- Impact: A 500-message multi-account refresh can hold the worker for a long time,
  consume Gmail quota, and make the native UI appear stalled.
- Affected files: AiOS Gmail sync service, email worker, sync API.
- Root cause: Incremental ID discovery and content retrieval are one serial loop.
- Risk: High latency and quota exhaustion on realistic mailboxes.
- Suggested fix: Batch metadata/body retrieval where supported, bound concurrency,
  persist cursors per stage, honor Retry-After, and expose progress/freshness.
- Complexity: High. Priority: P1.

### P-06 - AiOS local-model requests can block a worker for 45 seconds per message

- Problem: `app/services/ai_classifier.py:77-87` uses a 45-second blocking Ollama
  request, while `app/services/email_intelligence.py:736-752` uses a 25-second
  blocking request. Analysis is performed in synchronous loops.
- Impact: A model stall multiplies across a large inbox and delays reminders,
  planning, and the visible sync completion state.
- Affected files: AiOS classifier, email analysis loop, email worker.
- Root cause: Inference timeout is per request, with no queue, cancellation, or
  bounded batch deadline.
- Risk: High perceived hangs and backlog growth.
- Suggested fix: Use a bounded analysis queue, checkpoint after each message, enforce
  a cycle budget, retry only transient failures, and surface partial progress.
- Complexity: Medium to high. Priority: P1.

### P-07 - GitHub refresh fans out to many fixed API calls per repository

- Problem: `app/services/github_intelligence.py:103-114` makes separate requests for
  repository metadata, commits, PRs, issues, branches, releases, discussions,
  workflows, and contributors for each linked repository.
- Impact: Sync latency and rate-limit pressure scale linearly with repositories;
  there is no ETag, freshness skip, webhook, or rate-limit budget.
- Affected files: AiOS GitHub intelligence and email-cycle orchestration.
- Root cause: Every cycle rebuilds a bounded snapshot rather than incrementally
  updating changed resources.
- Risk: Medium to high CPU/network/latency risk.
- Suggested fix: Use conditional requests, per-resource cursors, webhook invalidation,
  bounded parallelism, and a rate-limit-aware scheduler.
- Complexity: High. Priority: P1.

### P-08 - Worker state writes are direct and unbounded

- Problem: AiOS worker scripts write JSON state directly every 20-30 seconds and
  `app/services/workers.py:58-59` writes process state without atomic replacement.
  Processed-file and worker histories can grow without a retention policy.
- Impact: A crash can truncate state; growing state increases startup and scan time.
- Affected files: AiOS worker scripts and worker manager.
- Root cause: Timer loops use files as both checkpoint and queue without a storage
  contract.
- Risk: Medium data-loss and long-run performance risk.
- Suggested fix: Atomic checkpoints, bounded histories, schema/version fields, and
  a transactional job table or append-only log.
- Complexity: Medium. Priority: P1.

## Memory and Storage Risks

- React keeps the full selected-day session array in memory; the data volume is
  bounded in the collector but should still be tested at the configured maximum.
- Flutter caps sessions at 96 in its native collector, while the Node implementation
  has its own limit. These limits should be one versioned contract.
- Daily files and hackathon files are parsed and rewritten as whole documents.
- No index or query plan exists because storage is JSON. Historical views will scan
  files as the data set grows.

## Missing Measurements

The following are required before performance sign-off:

| Metric | Target to define |
| --- | --- |
| Cold Windows startup to usable dashboard | Define and measure on a clean machine |
| Capture-to-render latency | Define p50/p95 |
| Idle CPU and active CPU | Define budget for laptop use |
| Disk writes per hour | Define budget and observe over an 8-hour day |
| Memory after 1, 7, and 30 days | Run with realistic session history |
| AiOS snapshot latency | Define p50/p95 and stale threshold |
| UI frame time during refresh | No jank during polling or chart updates |

## Performance Test Plan

1. Run the packaged Windows EXE for eight hours with active, idle, and date-switching
   behavior.
2. Capture CPU, private bytes, handles, file writes, and JSON sizes.
3. Inject slow PowerShell/Win32 reads and prove capture does not overlap.
4. Generate the maximum daily session history and test dashboard and date navigation.
5. Simulate AiOS downtime and measure retry/backoff behavior.
6. Repeat the browser probe at 390, 768, and 1280 pixels with a performance trace.

## Performance Verdict

The current bundle is modest, but runtime cost is not established. The largest wins
are architectural: remove duplicate collectors, serialize capture, stop full-file
rewrites, and replace fan-out polling with versioned snapshots.
