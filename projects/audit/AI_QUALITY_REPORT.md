# AI Quality Report

Audit date: 2026-08-07

## Scope Clarification

WDYD is the activity-awareness client. It does not contain the Gmail/Ollama planner,
GitHub intelligence, or the full email classifier. Those responsibilities are
delegated to the optional AiOS companion, as documented in `README.md` and
`projects/architecture.md`. This is a valid product boundary, but it means WDYD's
quality depends on a stable, authenticated, versioned AiOS contract.

## Current Intelligence Pipeline

The WDYD collector performs deterministic local classification from process name,
window title, and idle duration. In the Node path this begins at
`scripts/collector/local-activity-collector.mjs:540-577`; the Flutter equivalent is
`flutter_app/lib/src/collector_api.dart:193-209`.

```text
Win32 or PowerShell snapshot
  -> idle threshold
  -> process/title substring rules
  -> category and subcategory
  -> static confidence heuristic
  -> session aggregation
  -> optional AiOS summary sync
```

No email body, Gmail model, Ollama prompt, embedding store, or planner model is
implemented in this repository. No claim that WDYD itself understands email should
be made in the WDYD UI; it should show that the intelligence is supplied by AiOS.

## Findings

### AI-01 - Confidence is a heuristic, not a calibrated probability

- Problem: Confidence is assigned from category/title rules and displayed as a
  percentage, but there is no labeled evaluation set, calibration curve, or model
  version.
- Impact: Users can interpret `96%` as a measured probability when it is only a rule
  outcome. Wrong labels may influence wellbeing summaries.
- Affected files: Node classifier, Flutter classifier, activity models and cards.
- Root cause: Human-readable confidence was added before an evaluation protocol.
- Risk: Misleading insight quality.
- Suggested fix: Call it a confidence score, store the rule/model version, collect
  opt-in correction metrics, and publish precision/recall by category.
- Complexity: Medium. Priority: P1.

### AI-02 - Title substring rules are brittle

- Problem: Classification uses process/title text. Generic terms can collide across
  apps and browser tabs; a code-related word in a document or a meeting title can
  produce the wrong category.
- Impact: Coding, browsing, communication, and watching can be mislabeled without
  clear explanation.
- Affected files: `scripts/collector/local-activity-collector.mjs:540-645`,
  `flutter_app/lib/src/collector_api.dart:193-209` and classifier helpers.
- Root cause: Sparse local signal and no context-aware feature model.
- Risk: Incorrect productivity analytics and user frustration.
- Suggested fix: Use app identity as the primary signal, title rules as a secondary
  signal, expose the reason for each label, and evaluate against user corrections.
- Complexity: Medium. Priority: P1.

### AI-03 - Corrections do not form a learning loop

- Problem: WDYD can save corrections and notes, but there is no visible training
  dataset, per-rule correction counter, retraining process, or model update path.
- Impact: Repeated misclassification remains repeated work for the user.
- Affected files: correction routes and UI, local session records.
- Root cause: Correction persistence was implemented as editing, not feedback.
- Risk: Quality does not improve over time.
- Suggested fix: Keep a privacy-safe local feedback table, report category confusion,
  and use it to tune deterministic rules before considering a local model.
- Complexity: Medium. Priority: P2.

### AI-04 - AiOS integration lacks a tested semantic contract

- Problem: `src/services/aios.ts` discovers candidate ports and trusts JSON shapes;
  `flutter_app/lib/src/agent_desktop_api.dart` has its own pairing and snapshot
  behavior. There is no shared fixture suite in this repository.
- Impact: WDYD can show stale or partial planner, PAT, reminder, or opportunity
  data while the bridge appears connected.
- Affected files: `src/services/aios.ts`, `flutter_app/lib/src/agent_desktop_api.dart`,
  `src/main.tsx` and AiOS contract docs.
- Root cause: The bridge evolved in two clients without one versioned schema.
- Risk: Cross-app trust failures.
- Suggested fix: Version the envelope, validate it, include generated-at/source
  metadata, and test old/new fixtures plus locked/offline states.
- Complexity: Medium. Priority: P1.

### AI-05 - Synthetic fallback contaminates AI-facing analytics

- Problem: `src/main.tsx:205-210` replaces sessions with simulated data after a fetch
  failure. The sync and summary paths can then operate on that state unless the user
  notices the mode label.
- Impact: AiOS may receive or display summaries derived from synthetic sessions.
- Affected files: `src/main.tsx:187-217`, `src/services/aios.ts:168-232`.
- Root cause: Demo data is not typed or marked as non-syncable.
- Risk: False AI context and incorrect plans.
- Suggested fix: Separate `RealSession` and `DemoSession` or attach a non-syncable
  provenance flag; never send demo records to AiOS.
- Complexity: Low to medium. Priority: P0.

### AI-06 - AiOS email prompts do not establish an untrusted-content boundary

- Problem: `C:\Users\anura\Documents\Ai Agent\app/services/ai_classifier.py:89-121`
  and `app/services/email_intelligence.py:720-752` interpolate raw subject/body
  text into local-model prompts. The returned JSON is parsed and accepted with
  weak field validation; confidence is not consistently bounded at the classifier
  boundary.
- Impact: A malicious or merely strange email can instruct the model to ignore the
  classifier task, produce misleading actions, or emit malformed categories and
  dates that reach planning.
- Affected files: AiOS local classifier, email intelligence normalizer, tasks,
  reminders, and planner inputs.
- Root cause: Email content is treated as prompt text rather than untrusted data.
- Risk: High prompt-injection, false-action, and hallucinated-deadline risk even
  though inference remains local.
- Suggested fix: Delimit untrusted fields, use a fixed system instruction, validate
  against a strict schema/enums/ranges, reject unknown actions, preserve evidence
  spans, and require confirmation before destructive or external actions.
- Complexity: Medium. Priority: P1.

### AI-07 - Local email search is lexical and coverage-limited

- Problem: `C:\Users\anura\Documents\Ai Agent\app/services/email_intelligence.py:1385-1394`
  ranks token counts over only the newest 300 messages. The configured embedding
  and vector-store settings are not the retrieval path used here.
- Impact: Queries such as “what did Amazon ask me?” can miss older mail, synonyms,
  threads, and relevant body content, while the UI can imply semantic recall.
- Affected files: AiOS semantic search endpoint, vector-store configuration, email
  insight index.
- Root cause: A lexical fallback became the production implementation without a
  visible coverage contract.
- Risk: Medium incomplete-answer risk.
- Suggested fix: Index all retained messages locally, use embeddings when available,
  retain lexical fallback with a visible mode/coverage label, and evaluate recall on
  fixed private fixtures.
- Complexity: High. Priority: P1.

### AI-08 - Planner quality is not validated against real calendar constraints

- Problem: AiOS `planning_engine.py` drops timezone information with
  `.replace(tzinfo=None)`, uses fixed work windows, and uses event titles as one of
  the dependency completion keys. `daily_planner.py` also appends fixed practice
  work without proving free time or calendar fit.
- Impact: Tasks can be placed in the wrong local time, duplicate titles can satisfy
  the wrong dependency, and plans can overbook the user's actual day.
- Affected files: AiOS planning engine, daily/weekly planner, calendar adapters,
  dependency metadata.
- Root cause: Scheduling heuristics operate on naive datetimes and weak identifiers.
- Risk: High trust loss when automated plans conflict with meetings or deadlines.
- Suggested fix: Normalize all instants to an explicit user timezone, use immutable
  event IDs for dependencies, reserve calendar slots first, cap workload, and add
  planner evaluation fixtures for conflicts, DST, deadlines, and rescheduling.
- Complexity: High. Priority: P1.

### AI-09 - Model fallback quality and confidence semantics are inconsistent

- Problem: AiOS can fall back from Ollama to keyword rules after timeout or invalid
  JSON (`app/services/ai_classifier.py:65-87`). Rule confidence is fixed at `0.82`
  or `0.35`, while downstream model confidence is user-facing without a calibration
  set or source/version label.
- Impact: A model outage silently changes behavior and can create the appearance of
  reliable probability scores where only a heuristic decision exists.
- Affected files: AiOS classifier, email insights, inbox cards, planner inputs.
- Root cause: Availability fallback and quality confidence were represented as the
  same field.
- Risk: Medium-to-high misleading automation risk.
- Suggested fix: Persist provider/mode/model version, expose fallback state, bound
  and calibrate confidence, and require human review for low-confidence actions.
- Complexity: Medium. Priority: P1.

## AI Safety Requirements

- Every insight needs source, timestamp, freshness, and confidence semantics.
- Never present a stale AiOS summary as live without a visible stale state.
- Never sync synthetic or unverified sessions.
- Make user correction and deletion affect downstream summaries.
- Keep email reasoning in AiOS/Ollama and expose only approved summaries to WDYD.
- Add evaluation fixtures for idle, coding, browser, communication, gaming, and
  ambiguous window titles.

## AI Quality Verdict

WDYD's deterministic classification is an appropriate privacy-preserving prototype,
but it is not a validated AI system. The combined product can become trustworthy
only after provenance, contract validation, correction feedback, and a real
evaluation set are in place.
