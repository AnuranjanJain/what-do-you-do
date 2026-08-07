# Production Readiness Report

Audit date: 2026-08-07  
Release target: Windows Flutter EXE, with Linux browser client retained separately.

## Go / No-Go

**NO-GO.** The build is healthy, but the product is not ready for a trusted public
release. The blockers are privacy, data integrity, runtime consolidation, and
release-path test coverage.

## Readiness Matrix

| Dimension | Score | Assessment |
| --- | ---: | --- |
| Build reproducibility | 7/10 | Web, Flutter, Rust checks pass; no CI gate and companion worktree is dirty |
| Core functionality | 6/15 | Native activity path exists; dependent email/planner surfaces have incomplete release setup |
| Reliability and data integrity | 3/15 | Overlapping capture, non-atomic JSON writes, and timer workers without durable retries |
| Security and privacy | 3/15 | Collector is unauthenticated, data is plaintext, and AiOS pairing/token defaults are not fail-closed |
| Testing | 5/10 | WDYD checks and companion tests exist; no clean combined release/installer/contract gate |
| Performance | 4/10 | Modest bundle; serial Gmail/model/GitHub sync and runtime budgets are unmeasured |
| UX and accessibility | 5/10 | Polished baseline; narrow overflow, OAuth setup ambiguity, and weak partial-sync states |
| Architecture and maintainability | 3/10 | Multiple runtimes plus a loosely paired companion with large service boundaries |
| Documentation and release ops | 3/5 | Root docs are useful; OAuth provisioning, signing, CI, and companion guarantees remain incomplete |
| **Total** | **39/100** | Combined product is prototype/beta quality, not production quality |

## Release Blockers

1. Replace simulator-on-error behavior with no-data or stale-real-data behavior.
2. Add required per-install authentication to collector read/write routes.
3. Choose and enforce one Windows collector architecture.
4. Serialize and atomically replace persisted files.
5. Remove developer-specific AiOS path/thread data from shipped UI.
6. Remove or repair the obsolete collector startup setting and installer story.
7. Encrypt sensitive local records or narrow the privacy promise until encryption is
   implemented.
8. Add CI and installed Windows smoke tests.
9. Upgrade the audited npm dependency ranges.
10. Require authenticated AiOS pairing and a clean-install Gmail OAuth path.
11. Add recoverable companion workers, GitHub coverage/rate-limit handling, and AI safety evaluation.

## Current User-Usable Features

- Flutter Windows dashboard and native activity capture in the tested development
  environment.
- Local daily activity sessions and date history.
- Activity classification, correction/note flow, charts, and timeline views.
- Hackathon board and local planning data when the selected runtime has the data.
- Theme persistence and Windows tray/startup controls, subject to the startup
  launcher mismatch described in the audit.
- Optional AiOS loopback pairing and approved summary display when AiOS is available.

## Incomplete or Unsafe Features

- Browser fallback can display synthetic data as a normal dashboard.
- Collector access is not authenticated at the HTTP boundary.
- Plaintext JSON is not suitable for highly sensitive records.
- Mobile is not a functioning activity collector.
- Email, Gmail, Ollama, GitHub, and planner intelligence are not implemented in WDYD;
  they depend on AiOS and require authenticated contract tests. The companion currently
  has additional OAuth, worker, retrieval, planner, and first-page GitHub limitations.
- Public release signing, CI, installer verification, and packaged Windows E2E are
  not demonstrated.

## Sign-off Conditions

Security owner, product owner, and release owner should each sign off only after the
acceptance criteria in `RELEASE_BLOCKERS.md` are green on a clean Windows machine.
