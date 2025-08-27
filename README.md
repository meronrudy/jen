# Journal of Executable Neuroscience — Pilot Scaffold

This repository provides infrastructure-as-code, policies, schemas, Helm values, CI, templates, and docs to stand up the JEN pilot.

Key paths:
- infra/gcp/cluster.tf — GKE cluster (Terraform)
- infra/aws/cluster.tf — EKS cluster (Terraform)
- infra/modules/k8s-core/README.md — bring-up guide
- charts/jen/values.yaml — Helm baseline
- charts/jen/values-staging.yaml — staging overlay
- charts/jen/values-dev.yaml — dev overlay
- schemas/ro-crate/jen-rcp-1.0.json — JEN RO-Crate profile
- docs/security/supply-chain-policy.md — supply-chain security policy
- policies/vuln-thresholds.yaml — vulnerability thresholds
- policies/egress-allowlist.yaml — egress policy
- .github/workflows/triage.yml — CI triage workflow
- templates/ — author templates
- scripts/bootstrap-*.sh — bootstrap helpers

Next steps:
- Provision dev/staging clusters and install the chart.
- Onboard pilot authors using the ERA templates and the author quickstart.
- Configure reviewer workbench and editorial adapter integrations.

License: Apache-2.0 (proposed)
