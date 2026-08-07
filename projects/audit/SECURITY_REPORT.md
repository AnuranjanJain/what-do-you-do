# Security Report

Audit date: 2026-08-07  
Threat model: single-user Windows desktop and Linux local browser client, with an
optional loopback AiOS companion. The local machine is not assumed to be free of
other processes.

## Security Verdict

The product has good privacy intent and several useful controls, but the current
collector is not authenticated and local records are not encrypted. Loopback and
Origin checks reduce remote exposure; they do not protect against a malicious local
process or a hostile local web page. This is a release blocker for a product whose
core promise is private activity data.

## Findings

### S-01 - Origin validation is not authentication

- Problem: `scripts/collector/local-activity-collector.mjs:825-841` checks the
  `Origin` header only when supplied. A request with no Origin reaches all read and
  write routes.
- Impact: Local processes can read `/sessions`, `/activity`, and `/dates`, and write
  `/sessions/correct`, `/sessions/note`, and hackathon routes.
- Affected files: Node collector server, React collector clients, Tauri launcher.
- Root cause: Browser-origin policy was used as a trust boundary.
- Risk: Critical local data disclosure or tampering.
- Suggested fix: Per-install token, OS-protected storage, required Authorization
  header, constant-time comparison, token rotation, and route-level tests.
- Complexity: Medium.
- Priority: P0.

### S-02 - Plaintext local data at rest

- Problem: `SECURITY.md:20-25` documents unencrypted JSON storage for sessions,
  notes, hackathon plans, and sync state.
- Impact: Backups, copied folders, another account with file access, or malware can
  read private records.
- Affected files: Node and Flutter persistence layers, local app-data directories.
- Root cause: Encryption was deferred.
- Risk: High, especially if notes become mailbox-derived or personally sensitive.
- Suggested fix: Encrypt sensitive fields or files with a key protected by Windows
  DPAPI/credential vault, and document export/recovery/delete semantics.
- Complexity: High.
- Priority: P1.

### S-03 - Toolchain advisories are open

- Problem: `npm audit --omit=dev --audit-level=high` reports two high findings in
  Vite/PostCSS ranges and one low esbuild finding. The reported advisories include:
  - Vite Windows alternate-path `server.fs.deny` bypass:
    `GHSA-fx2h-pf6j-xcff`
  - PostCSS source-map path traversal/disclosure:
    `GHSA-r28c-9q8g-f849`
- Impact: The local development server and build toolchain have known vulnerable
  ranges. These are primarily development-server risks, but the package policy does
  not distinguish dev and shipped runtime dependencies cleanly.
- Affected files: `package.json`, lockfile, Vite/PostCSS dependency tree.
- Root cause: Dependency update and audit gates are absent.
- Risk: High in developer environments, lower in a static release artifact.
- Suggested fix: Upgrade to patched ranges, classify Vite as a development dependency
  if the product bundle does not need it at runtime, and gate CI on high findings.
- Complexity: Low to medium.
- Priority: P1.

### S-04 - PowerShell launchers use ExecutionPolicy Bypass

- Problem: `flutter_app/lib/src/startup_manager.dart:118-122` and installer helpers
  launch PowerShell with `-ExecutionPolicy Bypass`.
- Impact: A modified local launcher can execute without the normal script policy.
- Affected files: startup manager and `flutter_app/windows/install/*.ps1`.
- Root cause: Convenience startup/install behavior.
- Risk: Medium supply-chain and local tampering exposure; amplified if the obsolete
  collector launcher remains packaged.
- Suggested fix: Remove the retired script path; for required installers, verify a
  signed/hashed script or ship native startup configuration instead.
- Complexity: Medium.
- Priority: P1.

### S-05 - Release binaries are not shown as signed

- Problem: Installer scripts copy and launch the executable but do not verify a
  publisher signature or checksum before installation.
- Impact: Windows SmartScreen friction and weaker artifact integrity for public
  releases.
- Affected files: `flutter_app/windows/install/install.ps1`, release workflow (none
  present), packaging docs.
- Root cause: No release signing or provenance pipeline.
- Risk: Medium to high for public distribution.
- Suggested fix: Sign the EXE and installer, publish checksums, and verify them in a
  clean-machine install test.
- Complexity: Medium.
- Priority: P1.

### S-06 - Local URL trust is better than the collector boundary, but incomplete

- Problem: `src/services/aios.ts:256-279` restricts the configurable AiOS URL to
  loopback, and `agent_desktop_api.dart` normalizes loopback descriptors. The Node
  collector still accepts unauthenticated no-Origin requests.
- Impact: AiOS remote exfiltration is constrained, but an attacker on the same host
  can still access WDYD directly.
- Affected files: AiOS bridge and collector server.
- Root cause: Security controls were applied to URL validation but not uniformly to
  service authentication.
- Risk: Medium after S-01 is fixed; currently part of the critical boundary.
- Suggested fix: Reuse one pairing/authentication primitive for WDYD and AiOS.
- Complexity: Medium.
- Priority: P1.

### S-07 - AiOS local API authentication is optional by configuration

- Problem: AiOS `config.py:44` defaults `LOCAL_API_TOKEN` to an empty string, and
  `app/services/api_auth.py:6-12` rejects only when a non-empty expected token is
  configured. The pairing endpoint at `app/routes.py:2217-2232` can therefore
  return an unusable empty token while WDYD discovery still sees a service.
- Impact: Deployment behavior differs between machines; a missing token can produce
  confusing “connected” or unprotected local-service states.
- Affected files: AiOS config, API auth, pairing endpoint, WDYD discovery clients.
- Root cause: Authentication is an opt-in setting rather than a required install
  invariant.
- Risk: High local trust-boundary failure.
- Suggested fix: Generate and persist a per-install token during first run, fail
  closed when it is absent, pair through an authenticated one-time handshake, and
  test empty/default configurations.
- Complexity: Medium. Priority: P0.

### S-08 - OAuth token encryption is tied to the application secret file

- Problem: AiOS `app/services/email_intelligence.py:90-105` derives the Fernet key
  from Flask `SECRET_KEY`; `app/__init__.py:120-138` stores that secret in the
  instance directory and only attempts POSIX-style `chmod`.
- Impact: Losing, copying, or rotating the secret makes stored Gmail tokens
  unrecoverable; weak Windows ACL assumptions can expose the key and all encrypted
  refresh tokens together.
- Affected files: AiOS secret setup, token encryption, backup/restore and Windows
  packaging.
- Root cause: Application-session secret and credential-encryption key share one
  lifecycle without OS key protection or rotation semantics.
- Risk: High credential disclosure/recovery risk.
- Suggested fix: Use Windows DPAPI/Credential Manager or an OS-backed key vault,
  separate key purposes, define rotation/revocation/recovery behavior, and verify
  ACLs on a clean Windows install.
- Complexity: High. Priority: P1.

### S-09 - OAuth provisioning still requires a client-secret JSON file

- Problem: AiOS Gmail OAuth reads `google_client_secret.json` from a configured or
  bundled path (`app/services/email_intelligence.py:128-223`). A fresh install does
  not have that file unless it is provisioned outside the application.
- Impact: The advertised one-click Google login cannot be reproduced from the
  release artifact; users may copy secrets into ad-hoc directories.
- Affected files: OAuth setup, installer/package manifest, setup documentation.
- Root cause: Desktop OAuth client provisioning is not part of the release contract.
- Risk: High onboarding and secret-handling risk.
- Suggested fix: Ship a vetted public desktop client ID configuration or provide a
  secure first-run provisioning flow with clear test-user/publishing requirements;
  never ask users to paste refresh tokens.
- Complexity: Medium. Priority: P1.

### S-10 - Local model prompts accept raw email instructions

- Problem: AiOS interpolates raw email content into Ollama prompts without explicit
  untrusted-content delimiters or instruction hierarchy (`app/services/ai_classifier.py:89-121`).
- Impact: Email text can manipulate classification, suggested actions, deadlines,
  or planner context. Local-only inference reduces cloud exposure but does not
  remove prompt-injection risk.
- Affected files: AiOS classifier and downstream task/planner creation.
- Root cause: Privacy boundary was considered, but model-input integrity was not.
- Risk: High integrity risk; possible unsafe automation if actions become executable.
- Suggested fix: Treat mail as data, enforce schema/ranges, preserve source evidence,
  and require confirmation for any non-read-only action.
- Complexity: Medium. Priority: P1.

### S-11 - Companion desktop activity persists raw window titles

- Problem: AiOS `desktop_activity_worker.py` writes the active window title into
  `ActivityEvent.actual_task` while WDYD's privacy documentation describes storing
  classified summaries rather than raw titles.
- Impact: Document names, private URLs, chat subjects, or other sensitive title
  content can persist in the companion database and appear in downstream context.
- Affected files: AiOS desktop activity worker, activity model, WDYD/AiOS privacy
  documentation and snapshot serializers.
- Root cause: Temporary classification input and durable user-facing task text share
  one field.
- Risk: Medium privacy leakage and inconsistent product promise.
- Suggested fix: Store a redacted classification reason by default, keep raw titles
  in memory only, add explicit opt-in retention, and test snapshot redaction.
- Complexity: Medium. Priority: P1.

## Controls That Passed Review

- Collector and AiOS URLs are restricted to loopback in the browser bridge.
- JSON mutation payloads are length- and enum-validated in the Node collector.
- External hackathon URLs accept only HTTP/HTTPS.
- React external links use `rel="noreferrer"`.
- Tauri CSP and capabilities are explicitly configured.
- No tracked environment files, credentials, tokens, databases, or logs were found.
- Raw titles are not included in the public snapshot payload or persisted session
  schema by the reviewed collector paths, though they are temporarily used in local
  classification.

## Required Security Tests

1. Request every collector route with no Origin and confirm it is rejected without a
   valid token.
2. Request from a disallowed Origin with and without a token.
3. Verify replay and rotation behavior for the per-install token.
4. Kill the process during a write and verify recovery from the last good record.
5. Inspect release artifacts for signatures, embedded secrets, and obsolete Node
   launchers.
6. Run dependency audit in CI and document any accepted development-only advisory.
