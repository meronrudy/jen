# jenx CLI (Pilot Scaffold)

jenx is the Journal of Executable Neuroscience command-line interface for authors, reviewers, editors, and operators. It scaffolds reproducibility bundles, validates JEN RO-Crate profiles, runs bounded local smoke tests, generates attestations, and interacts with submission and archival services.

Status: Pilot scaffold (commands and flags subject to change before GA)
License: Apache-2.0 (proposed)
Audience: Authors, Reviewers, Editors, Platform Engineers

Overview

- Author workflow
  - Initialize a new Executable Research Article (ERA) bundle with templates.
  - Validate against the JEN RO-Crate profile (JEN-ROCP-1.0).
  - Build container and run bounded local smoke tests.
  - Generate SBOMs and rerun attestations.
  - Prepare DOI-ready metadata and submit.

- Reviewer workflow
  - Fetch artifacts and regenerate figures.
  - Launch parameterized re-runs from config deltas.
  - Produce verification reports and badge requests.

- Operator workflow
  - Validate bundles in CI.
  - Emit and verify attestations.
  - Manage policy profiles for environments and networks.

Installation (pilot)

- Python-based shim recommended for pilot:
  - pipx install jenx (planned)
  - Alternatively, use a containerized distribution: ghcr.io/jen/jenx:0.1.0
- Runtime dependencies: Python 3.11+, docker/podman for local runs, jq, yq

Command reference

jenx init
- Scaffold a new JEN bundle from a template (language or modality).
- Examples:
  - jenx init --template era-python --name my-snn-paper
  - jenx init --template neuromorphic-loihi --name my-loihi-benchmark
- Flags:
  - --template [era-python|era-julia|workflow-cwl|workflow-nextflow|neuromorphic-loihi|neuromorphic-spinnaker]
  - --name NAME
  - --license SPDX
  - --output DIR

jenx validate
- Validate a bundle’s JEN RO-Crate profile and required components.
- Examples:
  - jenx validate --schema schemas/ro-crate/jen-rcp-1.0.json --manifest jen-rocp.json
- Flags:
  - --schema PATH (default: schemas/ro-crate/jen-rcp-1.0.json)
  - --manifest PATH (default: jen-rocp.json)
  - --strict (treat warnings as errors)
- Validation checks:
  - Presence of required sections and fields
  - Container image digest pinning
  - Data DOI reachability (metadata fetch)
  - Raw artifact index integrity

jenx build
- Build the execution environment image (Dockerfile or repo2docker).
- Examples:
  - jenx build --strategy dockerfile
  - jenx build --strategy repo2docker
- Flags:
  - --strategy [dockerfile|repo2docker|auto]
  - --tag NAME[:TAG] (default: jen-local:latest)
  - --sbom PATH (emit SPDX or CycloneDX)
  - --lock [pip|conda|nix] (emit/refresh lockfiles where possible)

jenx run
- Execute the declared command in a bounded local container for smoke tests.
- Examples:
  - jenx run --image jen-local:latest --config params.toml
- Flags:
  - --image IMAGE
  - --command "snn train --config params.toml" (overrides manifest)
  - --config PATH
  - --cpu 2 --memory 8Gi --time 60
  - --no-network (default) | --allow host1,host2
  - --artifacts-out ./runs/local
- Outputs:
  - Structured logs, exit code, raw artifacts, checksums

jenx sbom
- Generate an SBOM for the built image and validate against policy thresholds.
- Examples:
  - jenx sbom --image jen-local:latest --format SPDX-2.3 --out jen-sbom.spdx.json
- Flags:
  - --image IMAGE
  - --format [SPDX-2.3|CycloneDX-1.5]
  - --out PATH
  - --scan (run vulnerability scan)
  - --policy policies/vuln-thresholds.yaml

jenx attest create
- Produce a rerun attestation JSON from the last execution context.
- Examples:
  - jenx attest create --bundle-doi 10.5281/zenodo.12345 --out attestations/rerun.json
- Flags:
  - --bundle-doi DOI
  - --bundle-digest sha256:...
  - --image-digest sha256:...
  - --config PATH --config-digest sha256:...
  - --datasets DOI=sha256:... (repeatable)
  - --out PATH

jenx attest sign
- Sign an attestation using Sigstore/cosign.
- Examples:
  - jenx attest sign --in attestations/rerun.json --out attestations/rerun.json.sig --keyless
- Flags:
  - --in PATH
  - --out PATH
  - --keyless | --key PATH
  - --rekor-url https://rekor.sigstore.dev

jenx attest verify
- Verify signature and schema of an attestation.
- Examples:
  - jenx attest verify --in attestations/rerun.json --sig attestations/rerun.json.sig

jenx submit
- Package and submit a bundle to the JEN portal or editorial adapter.
- Examples:
  - jenx submit --endpoint https://jen.example.org/api --token $TOKEN
- Flags:
  - --endpoint URL
  - --token TOKEN
  - --bundle PATH (.tar.gz) | --dir PATH (to be tar’d)
  - --manifest jen-rocp.json
  - --dry-run

jenx review regen
- Reviewer: regenerate figures using the visualization mapping.
- Examples:
  - jenx review regen --manifest jen-rocp.json --out ./regen
- Flags:
  - --manifest PATH
  - --out DIR
  - --figure-id ID (repeatable)
  - --tolerance-profile docs/review/tolerance-policies.md

jenx review sweep
- Reviewer: run parameter sweeps defined via config diffs.
- Examples:
  - jenx review sweep --config-diff sweeps/learning_rate.yaml --n 5
- Flags:
  - --config-diff FILE (YAML/JSON of param overrides)
  - --n INT (number of runs)
  - --parallel INT

Templates and quickstarts

- ERA Python: structure includes:
  - jen-rocp.json (pre-filled skeleton)
  - params.toml (primary config)
  - Dockerfile (minimal with pinned digest base)
  - scripts/ (train.py, viz.py)
  - data/ (small example dataset or fetch script)
- ERA Julia: analogous to Python with Project.toml/Manifest.toml
- Workflow CWL/Nextflow: includes pipeline descriptors and minimal inputs
- Neuromorphic Loihi/SpiNNaker:
  - Adapter-ready job spec examples
  - Hardware manifest capture hooks
  - Simulation fallbacks for offline testing

Policy integration checkpoints

- Supply chain:
  - All images referenced by digest; signed at submission or pre-publish.
  - SBOM generated and scanned; policy enforced in protected runs.
- Egress:
  - Default-deny; allow DOI/data registries from policy file.
- Reproducibility:
  - Seeds declared; lockfiles present when applicable.
  - Rerun attestation generated post-run.

Exit codes and diagnostics

- 0: success
- 2: validation errors (schema or missing components)
- 3: build failures
- 4: policy enforcement failures (SBOM/CVE/license/egress)
- 5: execution runtime failures
- 6: submission or network errors

Examples

- Initialize and validate a Python ERA:
  - jenx init --template era-python --name jen-demo
  - cd jen-demo
  - jenx validate
  - jenx build --strategy auto --tag jen-demo:local
  - jenx run --image jen-demo:local --config params.toml
  - jenx sbom --image jen-demo:local --format SPDX-2.3 --out jen-sbom.spdx.json
  - jenx attest create --bundle-doi 10.5281/zenodo.demo --out attestations/rerun.json
  - jenx attest sign --in attestations/rerun.json --keyless
  - jenx submit --endpoint https://jen.example.org/api --token $TOKEN

Roadmap

- Alpha: Python CLI with core commands; containerized distribution; schema-aware validators.
- Beta: Plugin SDK generators, figure regeneration helpers, sensitivity analysis helpers.
- GA: Rich TUI, multi-language SDKs, marketplace discovery.

Contributing

- Proposed license: Apache-2.0
- DCO-based contribution workflow
- Code of conduct (to be added)
- Please file issues for command coverage gaps and UX suggestions.