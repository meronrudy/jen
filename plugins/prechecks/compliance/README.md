Name: Compliance Prechecks
Type: precheck
Purpose: Automated license, malware, secrets, vulnerability, and export-control checks.

Inputs:
- Bundle path, JEN RO-Crate manifest, SBOM

Outputs:
- Structured report with pass/fail and remediation guidance

Policies:
- Align with policies/vuln-thresholds.yaml and docs/security/supply-chain-policy.md
