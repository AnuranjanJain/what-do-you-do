# UX and Accessibility Report

Audit date: 2026-08-07  
Surfaces reviewed: React browser client at desktop and 390px viewport, Flutter
Windows shell and settings, README screenshots, and error/fallback states.

## What Works Well

- The product language communicates local-first behavior and AiOS separation.
- The Flutter shell has explicit tray hide and full exit actions in Settings.
- Date controls, dark mode, collector status, and AiOS status are visible.
- The native app has a coherent dashboard, timeline, hackathon, and settings model.
- Important buttons generally have text labels; native icon controls use tooltips in
  the reviewed Flutter date controls.

## Findings

### UX-01 - Simulator mode is too close to normal mode

- Problem: The browser renders a full dashboard with simulated activity after a
  collector failure. The mode is shown as `Simulator fallback`, but it is visually
  similar to real data.
- Impact: Users can make decisions from fabricated totals and timelines.
- Affected files: `src/main.tsx:187-217`, `:701-750`, `:1200-1217`.
- Root cause: Demo fallback is integrated into the main data state.
- Risk: Critical trust and comprehension issue.
- Suggested fix: Use a blocking empty state with a clear recovery action; allow demo
  mode only from a separate developer control.
- Complexity: Medium. Priority: P0.

### UX-02 - Narrow browser layout has horizontal clipping pressure

- Problem: A 390px browser probe reported a document width greater than the viewport,
  and the horizontal navigation/date controls were partially clipped. The page uses
  desktop-density card groups at narrow widths.
- Impact: Users cannot reliably reach controls or read the full date/action row on a
  phone-sized viewport.
- Affected files: `src/main.tsx` date/navigation markup and `src/styles.css` responsive
  rules.
- Root cause: A dense desktop dashboard is compressed instead of reflowed into a
  mobile interaction model.
- Risk: Broken mobile/browser usability.
- Suggested fix: Test at 320, 390, 768, and 1280px; wrap controls, reduce card
  density, and make horizontal scrolling intentional with visible affordance.
- Complexity: Medium. Priority: P1.

### UX-03 - Date navigation exposes an unavailable action

- Problem: The React UI renders `Next day` even when it is disabled on today
  (`src/main.tsx:758-775`). Flutter permits date selection from 2024 through today
  (`flutter_app/lib/src/shell.dart:792-801`), while the product currently needs clear
  handling of future/no-data dates.
- Impact: Users see an action that cannot work and may not understand whether a date
  has no records or the collector is broken.
- Affected files: React date strip and Flutter date picker.
- Root cause: Navigation controls are always rendered and state/freshness are not
  separated.
- Risk: Confusing date history and support questions.
- Suggested fix: Hide or replace unavailable actions, show explicit no-data states,
  and keep date bounds derived from available dates plus the current day.
- Complexity: Low. Priority: P2.

### UX-04 - Error recovery is not consistently actionable

- Problem: Collector and AiOS errors are often reduced to status text. The React
  polling effects have no request timeout or retry/backoff UI, and the native app
  uses a general offline message.
- Impact: Users cannot tell whether to restart WDYD, AiOS, or a connector.
- Affected files: `src/main.tsx`, `src/services/*.ts`,
  `flutter_app/lib/src/app_controller.dart:102-115`.
- Root cause: Error state is treated as a string rather than a recovery state model.
- Risk: Repeated manual restarts and false bug reports.
- Suggested fix: Provide `offline`, `stale`, `locked`, `syncing`, and `invalid-data`
  states with one primary action each.
- Complexity: Medium. Priority: P1.

### UX-05 - Runtime wording conflicts with the native architecture

- Problem: Flutter README and some browser settings language still mention starting
  the Node collector, while the native app claims in-process collection.
- Impact: Users can follow instructions that create a duplicate or obsolete service.
- Affected files: `flutter_app/README.md:15-43`, `src/main.tsx:1245-1307`.
- Root cause: Migration text was not cleaned after the platform split.
- Risk: Poor first-run experience.
- Suggested fix: Make Windows copy only describe the EXE; move Linux instructions to
  the Linux client documentation.
- Complexity: Low. Priority: P1.

### UX-06 - Accessibility verification is incomplete

- Problem: Build and widget tests do not include automated accessibility assertions.
  There is no evidence of keyboard traversal, focus visibility, screen-reader
  semantics, reduced-motion behavior, or contrast checks across all dashboard states.
- Impact: Important controls may be hard to use without a mouse or with assistive
  technology.
- Affected files: React and Flutter UI surfaces.
- Root cause: Visual QA is ahead of semantic QA.
- Risk: Medium accessibility regression risk.
- Suggested fix: Add axe or equivalent browser checks, Flutter semantics tests,
  keyboard-only smoke flows, focus screenshots, and reduced-motion coverage.
- Complexity: Medium. Priority: P2.

### UX-07 - Companion sync state does not distinguish partial progress

- Problem: AiOS native sync surfaces a general message while Gmail, analysis, GitHub,
  planning, and worker stages run. The WDYD bridge then consumes summaries without a
  shared freshness/partial-result state.
- Impact: Users cannot tell whether mail is connected but still indexing, GitHub is
  rate-limited, or the planner is showing an older successful snapshot.
- Affected files: WDYD `src/services/aios.ts`, native agent API, AiOS sync route and
  worker status UI.
- Root cause: Multi-stage work is represented as one boolean/message instead of a
  progress envelope.
- Risk: Medium decision-making and support risk.
- Suggested fix: Return stage-level status, started/completed timestamps, last good
  snapshot, stale threshold, retry action, and a clear “partial” state.
- Complexity: Medium. Priority: P1.

### UX-08 - OAuth setup errors remain operationally confusing

- Problem: AiOS can fail before browser authorization when the Google client-secret
  file is missing (`app/services/email_intelligence.py:128-223`), while Google can
  also return developer/test-user access errors. The UI cannot reliably distinguish
  provisioning, account authorization, callback, and token-refresh states.
- Impact: Users may repeatedly retry a browser login when the local installation is
  missing required configuration or the OAuth app is not published/test-approved.
- Affected files: AiOS OAuth sign-in job, Gmail settings, installer/setup docs.
- Root cause: Several failure classes are collapsed into one sign-in workflow.
- Risk: Medium onboarding friction and unsafe support workarounds.
- Suggested fix: Give each state a specific recovery action, show whether the browser
  is open, preserve cancel/back behavior, and never expose secrets in error text.
- Complexity: Medium. Priority: P1.

## UX Acceptance Checklist

- No synthetic data appears without an explicit demo choice.
- Every offline/locked/stale state has a clear action and does not lose last-known
  real data.
- No horizontal overflow at 320/390/768px.
- Current date, no-data date, future date, and corrupted-data states are distinct.
- All controls are reachable by keyboard and have accessible names.
- Animations honor reduced-motion preferences.
