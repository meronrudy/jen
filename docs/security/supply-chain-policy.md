Title: JEN Supply Chain Security Policy
Status: Draft for Pilot
Version: 1.0
Owners: Security Engineering, SRE, Platform Team
Last-Updated: 2025-08-27

1. Scope and objectives
- Scope: All container images, plugins, reproducibility bundles, CI runners, and dependencies used in JEN builds, triage executions, interactive sessions, workflow jobs, and hardware broker adapters.
- Objectives:
  - Integrity: Only verified, signed, policy-compliant artifacts are admitted.
  - Transparency: Every build and execution emits attestations with provenance.
  - Isolation: Execution sandboxes run with least privilege and controlled egress.
  - Observability: Security events are logged and actionable.

2. Artifact trust and signing
2.1 Container images
- Requirement: All images (core services, plugin images, execution images) must be signed using Sigstore cosign (keyless or key-based) with entries in a transparency log.
- Admission: Kubernetes admission controller verifies signatures against trusted identities (OIDC issuers or certificate subjects).
- Pinning: Images must be referenced by immutable digests (e.g., sha256:...).
- Base images: Approved base image list maintained; base image digests must be pinned.

2.2 Plugins
- Packaging: Plugins are OCI images or signed bundles containing manifest, SBOM, policy, capabilities, and permissions.
- Signing: cosign signatures; in-toto attestations for build steps.
- Marketplace: Only curated, scanned, and signed plugins are listed and allowed in production.

2.3 Reproducibility bundles
- Integrity: Bundle archives require content-addressed digests (sha256 or sha512).
- Verification: CI validates bundle digest, schema (JEN-ROCP), and SBOM presence for environments.

3. SBOM and vulnerability management
3.1 SBOM requirements
- Format: SPDX 2.3 or CycloneDX ≥ 1.5.
- Coverage: OS packages, language packages, transitive deps, base image layers, and source URIs.
- Storage: SBOM stored with artifact metadata and referenced from RO-Crate.

3.2 Vulnerability scanning
- Tools: Trivy/Grype or equivalent; scans at build time and on scheduled intervals.
- Thresholds:
  - CRITICAL: Block unless explicit time-bounded waiver approved by Security Engineering; must include mitigating controls.
  - HIGH: Allowed only with waiver for pilot; target zero HIGH by GA.
  - MEDIUM/LOW: Logged; regressions tracked.
- New findings post-publication:
  - Advisory: Publish a security note on the article page if environment image is affected.
  - Patch: Provide a patched environment image digest and update bundle metadata (new minor version) when feasible.

4. Build provenance and attestations
4.1 CI/CD provenance
- In-toto SLSA-style attestations must include:
  - Subject: image digest or bundle digest.
  - Materials: repo commit, Dockerfile path, lockfiles, base image digest.
  - Builder: CI runner identity, environment.
  - Predicate: steps executed, tools and versions, policy outcomes.
- Storage: Attestations stored in object storage and linked from provenance API; signatures verified at retrieval.

4.2 Execution attestations
- Every triage-passing run produces a rerun attestation including command, config, environment digest, hardware manifest (if any), and checksums of outputs.

5. Execution sandbox hardening
5.1 Container runtime security
- Non-root containers; read-only root filesystem when possible.
- Drop all capabilities; add selectively per plugin need; no SYS_ADMIN.
- Apply seccomp and AppArmor/SELinux profiles.
- Enforce Pod Security Standards (restricted) and namespace isolation.

5.2 Network and egress controls
- Default-deny egress for execution pods.
- Egress allowlists per job derived from bundle (e.g., DOI resolvers, archives, registries) and platform policies.
- No inbound connectivity to execution pods; all control via internal APIs.

5.3 Filesystem and secrets
- Mount secrets as tmpfs with least privilege; no secret in environment variables unless strictly necessary.
- Rotate tokens; short-lived credentials for registries and storage.
- Per-plugin scoped service accounts with narrowly defined RBAC.

6. Data integrity and fixity
- All persisted artifacts include checksums (sha256 or sha512); fixity checks on ingest and periodically per lifecycle policy.
- Immutable storage for published artifacts; deletion prevented except via governed redaction process.

7. Policy enforcement in cluster
- Admission controllers:
  - ImagePolicyWebhook/OPA/Gatekeeper to enforce signatures, digest pins, and registry allowlists.
  - Custom webhook to check SBOM presence and vulnerability thresholds for annotated workloads.
- Runtime policies:
  - NetworkPolicy enforced for every namespace; no default allow.
  - ResourceQuotas and LimitRanges defined per tenant and project.

8. Keys, identities, and trust roots
- Trust stores for OIDC issuer(s), cosign roots, and transparency logs managed centrally.
- Rotation: Update trust anchors quarterly or upon compromise advisories.
- Service identities mapped to least-privilege permissions; cross-cloud identities use workload identity (GCP) or IRSA (AWS).

9. Compliance and privacy
- GDPR: PII encrypted in transit and at rest; access audited; data subject request workflows documented.
- Export control: Bundles flagged by policy cannot egress to disallowed regions; enforcement via egress controls and data tagging.
- Human/animal research: Compliance plugins required when flags present; block publication if missing approvals.

10. Monitoring, alerting, and response
- Telemetry:
  - Security metrics: signature verification rates, policy denials, CVE trends, SBOM coverage.
  - Logs: admission denials, escalation approvals, egress violations.
- Alerts:
  - CRITICAL CVE in published image: page Security on-call; create advisory within 72 hours.
  - Signature verification failure in prod: block rollout; page on-call.
- Incident management: Severity matrix, 24/7 escalation path, post-incident review with corrective actions.

11. Waivers and exceptions
- Waiver content: scope, risk assessment, compensating controls, owner, expiry date.
- Approval: Security Engineering approval required; executive sign-off for production scope.
- Audit: All waivers logged and reviewed monthly; expired waivers auto-revoke.

12. Roadmap to GA (tightening controls)
- Pilot: Allow HIGH vulnerabilities with waiver; marketplace in curated beta.
- Beta: Block HIGH by default; enforce zero network egress for most workflows; mandatory cosign for all plugins.
- GA: Block MEDIUM in core platform images; require bit-reproducible builds for designated critical workflows; mandatory periodic re-scan of archived images.

13. References
- SLSA Framework
- Sigstore cosign
- SPDX / CycloneDX
- Kubernetes Pod Security Standards
- OWASP Dependency and Pipeline Security Guidance

Appendix A: Default policy values (overridable per env)
- Approved base images: debian:stable-YYYYMMDD digest, ubuntu LTS YYYY.MM digest, distroless/static:nonroot digest.
- Registries: artifact-registry.jen.example, gcr.io/google-containers (read-only), docker.io/library (pinned digest only), ghcr.io (pinned).
- Egress allowlist domains (minimal): doi.org, zenodo.org, osf.io, pypi.org, files.pythonhosted.org, repo.anaconda.com, index.anaconda.com, ghcr.io, gcr.io, artifact-registry.*.
- Resource ceilings for triage: 4 vCPU, 16 GB RAM, 1 GPU optional, 60 min time limit.