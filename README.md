# The Journal of Executable Neuroscience (JEN)
From archival availability to operational, verifiable, and executable science

JEN is a new publishing model for computational neuroscience. It replaces the static, narrative-only paper with an Executable Research Article (ERA): a manuscript that ships with a runnable, validated Reproducibility Bundle. Authors must prove that their results can be rebuilt and re-run end-to-end; reviewers explore the work interactively; readers can press Run Paper to reproduce figures and extend analyses. This repository contains the pilot scaffold—policy, schema, infrastructure, and templates—to stand up JEN and publish the inaugural issue.

Why executable science
- The scientific record should be verifiable. In practice, complex dependencies, undocumented steps, and shifting environments make many results irreproducible.
- Code-and-data availability solves discovery, not executability. Readers are left to rebuild fragile environments and “glue code.”
- JEN’s standard moves the responsibility to authors at submission time and automates verification via CI. The result is less wasted effort, more robust claims, and a healthier incentive system.

What JEN publishes
- Executable Research Articles (ERAs): novel research with a required, passing Reproducibility Bundle.
- Methods & Frameworks: tools, simulators, and workflows, delivered with a working bundle.
- Replication Reports: re-executions, robustness checks, and adaptations of previously published bundles.
- Perspectives: essays on standards, ethics, and best practices for reproducibility and open science.

The Reproducibility Bundle (what every ERA must provide)
1) Declarative experiment configuration
   - Human-readable params (e.g., params.toml) that drive runs without editing code.
2) Data
   - Embedded small data or scripted fetch of DOI-identified datasets with checksums and access terms.
3) Environment container
   - Docker/Containerfile, pinned base image, exact versions and lockfiles; SBOM included.
4) Raw run artifacts
   - Direct outputs of the canonical command (logs, metrics, spike trains, etc.) with checksums.
5) Visualization state
   - Scripts/mappings to regenerate every figure programmatically from raw artifacts.

How peer review works (dual-track)
- Stage 1: Automated triage (CI/CD)
  - Build the container; run the declared command under resource/time limits; badge “Computationally Verified” on success; return full logs on failure.
- Stage 2: Human review
  - Scientific review: novelty, rigor, clarity.
  - Executable review: regenerate figures, inspect artifacts, and probe robustness by editing parameters. No reviewer is asked to debug builds.

Technical architecture at a glance
- Submission and CI/CD
  - Editorial portal integration triggers a pipeline that builds images, executes the command, captures provenance/attestations, and enforces policy gates.
- Execution sandbox
  - Self-hosted BinderHub for interactive sessions and batch runs; roadmap to interoperate with partner platforms as needed.
- Archival and long-term executability
  - Bundles deposited with DOIs; structured as RO-Crate with a JEN profile; SBOMs and attestations retained to combat software rot and enable future re-execution.

Governance and community
- Community-led scientific editorial board plus a Technical Advisory Board for infrastructure and standards.
- Strategic partnerships with leading institutes and neuromorphic providers to guarantee hardware access during review.
- Alignment with open science ethics and best practice guidance.

Redefining impact: the Executable Citation Index
- Dual citation of paper DOI and bundle DOI.
- New metrics surfaced on article pages:
  - Re-execution Count (how often readers successfully re-run),
  - Fork/Derivative Count (how many new submissions build on a bundle),
  - Verification Score (how many published Replication Reports validate/extend it).

Roadmap to launch
- Phase 1 (Pilot): Curated issue with flagship ERAs and at least one Replication Report; end-to-end interactive publication.
- Phase 2 (Community): Open submissions, training at major conferences, and public Executable Citation Index dashboards.
- Phase 3 (Policy): Formalize the JEN bundle profile, align funder mandates, and offer the executable pipeline model broadly.

Using this repository (pilot scaffold)
- Infrastructure-as-code
  - GKE cluster (Terraform): [infra/gcp/cluster.tf](infra/gcp/cluster.tf)
  - EKS cluster (Terraform): [infra/aws/cluster.tf](infra/aws/cluster.tf)
  - Bring-up guide (namespaces, policies, Helm): [infra/modules/k8s-core/README.md](infra/modules/k8s-core/README.md)
- Helm chart and values
  - Baseline: [charts/jen/values.yaml](charts/jen/values.yaml)
  - Overlays: [charts/jen/values-dev.yaml](charts/jen/values-dev.yaml), [charts/jen/values-staging.yaml](charts/jen/values-staging.yaml)
- Policy and schema
  - JEN RO-Crate profile (JEN-ROCP-1.0): [schemas/ro-crate/jen-rcp-1.0.json](schemas/ro-crate/jen-rcp-1.0.json)
  - Supply chain policy: [docs/security/supply-chain-policy.md](docs/security/supply-chain-policy.md)
  - Vulnerability thresholds: [policies/vuln-thresholds.yaml](policies/vuln-thresholds.yaml)
  - Egress allowlist: [policies/egress-allowlist.yaml](policies/egress-allowlist.yaml)
  - Rerun attestation policy: [docs/policy/rerun-attestation.md](docs/policy/rerun-attestation.md)
- CI triage workflow
  - GitHub Actions scaffold (validate, build, SBOM, smoke run): [.github/workflows/triage.yml](.github/workflows/triage.yml)

Quickstarts
- Authors (Python ERA): [docs/quickstarts/author-python.md](docs/quickstarts/author-python.md)
  - Start with templates: [templates/era-python](templates/era-python), [templates/era-julia](templates/era-julia), [templates/workflows/cwl](templates/workflows/cwl)
- Reviewers: [docs/quickstarts/reviewer.md](docs/quickstarts/reviewer.md)
  - Reviewer Workbench requirements and tolerance policies: [docs/review/reviewer-workbench-requirements.md](docs/review/reviewer-workbench-requirements.md), [docs/review/tolerance-policies.md](docs/review/tolerance-policies.md)
- Operators: [docs/quickstarts/operator-deploy.md](docs/quickstarts/operator-deploy.md)
  - Bootstrap scripts: [scripts/bootstrap-dev.sh](scripts/bootstrap-dev.sh), [scripts/bootstrap-staging.sh](scripts/bootstrap-staging.sh)

Neuromorphic and HPC adapters (pilot templates)
- Loihi: [templates/neuromorphic/loihi](templates/neuromorphic/loihi)
- SpiNNaker: [templates/neuromorphic/spinnaker](templates/neuromorphic/spinnaker)
- Slurm/HPC adapter spec: [plugins/adapters/slurm/README.md](plugins/adapters/slurm/README.md)

Security, provenance, and policy
- All images must be pinned by digest and signed (Sigstore recommended).
- SBOMs (SPDX/CycloneDX) are required; vulnerability gates enforced per environment.
- Every passing run emits a rerun attestation with environment digest, inputs, outputs, and hardware context where applicable.

Contributing and license
- Contributions follow a DCO-based workflow; see issues and docs for priorities.
- Proposed license: Apache-2.0.

Vision in one line
- Publish not just claims but proofs—complete, runnable, and preserved—so that anyone can verify, learn from, and build on computational neuroscience with confidence.
