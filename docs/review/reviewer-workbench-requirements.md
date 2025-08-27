Title: Reviewer Workbench v1 Requirements (Pilot)
Status: Draft
Scope: Figure regeneration, parameterized re-runs, tolerance checks, badge request flow

Capabilities
- Load bundle manifest (jen-rocp.json), resolve artifacts, and list figures with dependencies.
- One-click figure regeneration for any figure mapping entry.
- Parameterized re-runs: accept config diffs; record deltas and link new runs in provenance.
- Tolerance checks: compare regenerated outputs with published references; show pass/fail with metrics.
- Reviewer report export: structured JSON and human-readable summary; badge request submission.

UX
- Left nav: Manifest, Figures, Runs, Checks, Report.
- Figures table: figure id, regenerate button, last result, tolerance status.
- Runs pane: inputs, parameters diff, logs, artifacts, and attestation preview.

Nonfunctional
- p95 figure regeneration under 3 minutes on reference bundles.
- Safe read-only defaults; no destructive actions; network egress locked to allowlist.

Security/Privacy
- No PII; access via reviewer tokens; immutable logs; audit events on all actions.
