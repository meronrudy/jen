Title: Determinism and Tolerance Harness (Pilot)
Goal: Rebuild and rerun bundles to confirm reproducibility within policy.

Steps:
1) Rebuild environment from pinned digest/locks
2) Execute declared command with fixed seeds and locale/TZ
3) Compare raw artifacts against reference via:
   - Exact hash (bit-reproducible) or
   - Numeric tolerances (scalar, arrays) or spike-train windows
4) Emit pass/fail and diffs; produce rerun attestation

Artifacts:
- checksums.sha256, diff.json, attestation JSON

CI:
- Integrate with .github/workflows/triage.yml smoke run
