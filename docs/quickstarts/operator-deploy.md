Title: Quickstart — Operator Deploy (Dev/Staging)
Goal: Bring up JEN on an existing cluster for dev or staging.

1) Provision cluster (see infra/modules/k8s-core/README.md).
2) Configure DNS and TLS (values overlay).
3) Create or reference required secrets (OIDC, ORCID, storage, registry).
4) Install JEN chart:
   - helm upgrade --install jen charts/jen -n jen-system -f charts/jen/values.yaml -f charts/jen/values-staging.yaml
5) Validate:
   - kubectl -n jen-system get pods
   - Access portal and review workbench endpoints
6) Configure CI triage (.github/workflows/triage.yml) in your article repo.
