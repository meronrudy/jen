Title: JEN Rerun Attestation Policy
Status: Draft for Pilot
Version: 1.0
Owners: Platform, Security, Editorial
Last-Updated: 2025-08-27

1. Purpose
- Provide a standardized, verifiable record that a bundle was successfully executed under controlled conditions.
- Enable automated trust decisions (badges), reproducibility audits, and long-term archival verification.

2. Scope
- Applies to all triage runs, editorial verification runs, and post-publication archival re-runs.
- Covers software-only and hardware-backed executions (neuromorphic, GPUs/TPUs, HPC).

3. Required attestation content
- subject
  - bundle: JEN bundle identifier (including version) and immutable archive digest (sha256/sha512).
  - environment: primary container image digest and base image digest.
- materials
  - config: path to primary configuration file used; config file checksum.
  - datasets: list of dataset identifiers (DOIs/URIs) with checksums of resolved content.
  - locks: references to environment lockfiles (Conda, Nix, pip, OS).
- predicate
  - command: canonical run command invoked (exact string).
  - runner: execution engine (e.g., binderhub, local-runner, slurm, loihi, spinnaker).
  - schedule: queue timestamps (queued, started, completed) and queue identifier.
  - resources: CPU, memory, GPU/accelerator type and count; time limit.
  - env: minimal environment variables that influence execution (locale, TZ).
- outputs
  - status: exitCode (0 expected) and success boolean.
  - artifacts: index of generated raw artifacts with checksums, sizes, and MIME types.
  - logs: storage URI for structured logs (stdout/stderr), with checksum.
  - metrics: basic runtime metrics (wall clock, CPU seconds, peak memory).
- hardware (if applicable)
  - manifest: vendor, model, device IDs or pool, firmware versions, scheduler job id, site identifier.
  - context: optional routing/topology snapshot; temperature and clock info if exposed.
- identity and signing
  - builder: CI/runner identity (OIDC subject), service account, and platform version.
  - signature: cryptographic signature (Sigstore/cosign) and transparency log entry URI.
  - timestamp: RFC3339 timestamp from a trusted time source (e.g., TSA or runner-controlled NTP).

4. Canonical JSON structure (pilot)
- File: attestations/rerun.json (signed as attestations/rerun.json.sig)
- JSON (keys sorted lexicographically for determinism):

{
  "apiVersion": "jen.dev/attestations/v1",
  "kind": "RerunAttestation",
  "subject": {
    "bundle": {
      "id": "doi:10.1234/abc-def",
      "digest": { "algo": "sha256", "value": "..." }
    },
    "environment": {
      "imageDigest": "sha256:...",
      "baseImageDigest": "sha256:..."
    }
  },
  "materials": {
    "config": { "path": "params.toml", "checksum": { "algo": "sha256", "value": "..." } },
    "datasets": [
      { "id": "doi:10.5281/zenodo.12345", "checksum": { "algo": "sha256", "value": "..." } }
    ],
    "locks": {
      "conda": "env.lock",
      "nix": null,
      "pip": "requirements.lock",
      "osPackages": "os.lock"
    }
  },
  "predicate": {
    "command": "snn train --config params.toml",
    "runner": "binderhub",
    "schedule": {
      "queuedAt": "2025-08-27T12:34:56Z",
      "startedAt": "2025-08-27T12:35:40Z",
      "completedAt": "2025-08-27T12:42:11Z",
      "queueId": "q-abc123"
    },
    "resources": {
      "cpu": 2,
      "memoryGB": 8,
      "gpu": { "count": 0, "type": "" },
      "accelerator": { "type": "None", "count": 0 },
      "timeLimitMinutes": 60
    },
    "env": { "LC_ALL": "C.UTF-8", "TZ": "UTC" }
  },
  "outputs": {
    "status": { "exitCode": 0, "success": true },
    "artifacts": [
      {
        "path": "runs/primary/spikes.npy",
        "checksum": { "algo": "sha256", "value": "..." },
        "sizeBytes": 1048576,
        "mimeType": "application/x-numpy",
        "description": "Raw spike times"
      }
    ],
    "logs": { "uri": "s3://jen-artifacts/attest/logs/...", "checksum": { "algo": "sha256", "value": "..." } },
    "metrics": { "wallSeconds": 391, "cpuSeconds": 768, "peakMemoryMB": 1250 }
  },
  "hardware": {
    "vendor": "Intel",
    "model": "Loihi-2",
    "deviceIds": ["loihi-2-01"],
    "firmware": "2.3.1",
    "schedulerJobId": "L2-987654",
    "site": "INRC-Cloud",
    "capabilities": { "spikePrecision": "time-binned", "supportedModels": ["LIF"], "determinism": "bounded" },
    "context": { "clock": "site-ntp", "temperatureC": 42.1, "topology": "mesh:..." }
  },
  "identity": {
    "builder": { "issuer": "https://accounts.google.com", "subject": "sa:jen-triage@project.iam.gserviceaccount.com" },
    "signature": {
      "type": "sigstore-cosign",
      "bundle": "rekor://sha256:...",
      "sigRef": "s3://jen-artifacts/attest/rerun.json.sig"
    },
    "timestamp": "2025-08-27T12:42:12Z"
  }
}

5. Signing and verification
- Signing: cosign keyless signing preferred; fallback to key-based with HSM-backed keys for air-gapped deployments.
- Transparency: record in public transparency log when online; mirror entry in internal log for audit.
- Verification:
  - Verify signature against trusted roots; confirm payload digest matches stored object.
  - Validate JSON against API schema; ensure required fields present and policy thresholds met.
  - Cross-check environment and base image digests against admission records.

6. Policy gates and badges
- Computationally Verified (triage)
  - Criteria: exitCode=0; all required fields; dataset checksums verified; environment image signed; egress within policy; artifacts fixity validated.
- Hardware Parity Verified
  - Criteria: run on declared hardware; hardware manifest present; vendor constraints honored; variability within tolerance windows.
- Reproduction Verified (replication report)
  - Criteria: independent rerun attestation referencing original bundle; metrics within declared tolerances; provenance edges recorded.

7. Tolerances and determinism (summary)
- Seeds must be set and recorded; non-determinism flagged with bounded variance policy.
- Defaults (pilot; overridable per article type):
  - Scalar metrics: relative tolerance ≤ 1%.
  - Curves/arrays: MAE normalized ≤ 1% of dynamic range or SSIM ≥ 0.98 where applicable.
  - Spike trains: ≤ 2 ms window for event alignment and aggregate rate drift ≤ 2%.
- Store tolerance profile in the bundle and attach to attestation.

8. Storage, retention, and privacy
- Store attestations with artifacts in object storage; retain for the lifetime of the publication plus 10 years minimum.
- PII-free: attestations must not include personal data beyond service identities; redact paths that could leak secrets.
- Fixity: checksums validated at ingest and on quarterly audits.

9. Air-gapped and offline mode
- Use key-based signing with internal CA; store signatures and attestations in internal registry.
- When later connected, optional publication to public transparency logs with backdated timestamps and notarized proof of time.

10. Failure taxonomy and remediation
- failure.build: container build failed; include logs and failing step.
- failure.runtime: non-zero exit; include last N log lines and suggestion (from heuristics).
- failure.data: dataset fetch or checksum mismatch; include URL and expected checksum.
- failure.policy: SBOM/CVE/license/egress violation; include policy id and remediation link.
- failure.capacity: queue timeout or resource denial; include queue, backoff, and ETA if available.

11. Governance and versioning
- API: jen.dev/attestations/v1 initial; backward-compatible additions only in minor updates; breaking changes require new version.
- Deprecation: one minor version cycle; migration tooling provided in CLI.

12. CLI integration (jenx)
- jenx attest create: generates payload from execution context.
- jenx attest sign: applies cosign signature.
- jenx attest verify: verifies signature and schema; prints human-readable summary.
- jenx attest upload: stores to configured object store and records pointer in provenance.

Appendix A: Minimal JSON Schema (excerpt)

{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "JEN Rerun Attestation",
  "type": "object",
  "required": ["apiVersion", "kind", "subject", "materials", "predicate", "outputs", "identity"],
  "properties": {
    "apiVersion": { "type": "string", "const": "jen.dev/attestations/v1" },
    "kind": { "type": "string", "const": "RerunAttestation" },
    "subject": { "type": "object" },
    "materials": { "type": "object" },
    "predicate": { "type": "object" },
    "outputs": { "type": "object" },
    "hardware": { "type": "object" },
    "identity": { "type": "object" }
  },
  "additionalProperties": true
}

References
- RO-Crate, DataCite, in-toto, Sigstore, SLSA, SPDX/CycloneDX, Kubernetes Pod Security Standards