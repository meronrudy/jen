# JEN Kubernetes Core: Dev/Staging Bring-up Guide (Pilot)

This module documents the minimal steps to stand up Kubernetes clusters and deploy the JEN pilot stack in dev and staging. It assumes:
- Terraform >= 1.6, kubectl >= 1.29, Helm >= 3.12
- GCP (Workload Identity) and/or AWS (IRSA) credentials
- A DNS domain and TLS termination method (managed certs or pre-provisioned secret)

Contents
- Cluster provisioning (GCP or AWS)
- Access configuration (kubectl contexts)
- Base security and namespaces
- Secrets and identity
- Helm deployment (values and overlays)
- Post-deploy validation
- Teardown

Prerequisites
- Tools:
  - Terraform, kubectl, Helm, gcloud (for GCP), AWS CLI (for AWS), jq, yq
- Accounts and services:
  - GCP project with GKE API enabled; Artifact Registry and Cloud Storage available
  - or AWS account with VPC, subnets, EKS permissions, ECR/S3 access

Conventions
- Environment names: dev, staging, prod
- Namespace layout:
  - jen-system (core control plane services)
  - binderhub (interactive execution)
  - jen (APIs, adapters, broker, workbench)
- Storage bucket names:
  - jen-<env>-artifacts (object storage)

GCP: Provision a GKE cluster

1) Prepare variables (terraform.tfvars)
project_id = "your-project-id"
region     = "us-central1"
cluster_name = "jen-staging"
environment  = "staging"
initial_node_count = 2
machine_type = "e2-standard-4"
release_channel = "REGULAR"
network     = "default"
subnetwork  = "default"

2) Initialize and apply
cd infra/gcp
terraform init
terraform apply -var-file="terraform.tfvars"

3) Fetch kubeconfig
gcloud container clusters get-credentials jen-staging --region us-central1 --project your-project-id

4) Validate
kubectl get nodes
kubectl get ns

AWS: Provision an EKS cluster (requires VPC/subnets)

1) Prepare variables (terraform.tfvars)
region        = "us-east-1"
aws_profile   = "default"
cluster_name  = "jen-staging"
environment   = "staging"
vpc_id        = "vpc-xxxxxxxx"
subnet_ids    = ["subnet-aaaaaaa","subnet-bbbbbbb"]
kubernetes_version = "1.29"
endpoint_private_access = true
endpoint_public_access  = false
public_access_cidrs = ["0.0.0.0/0"]
instance_type   = "m6i.large"
node_min        = 1
node_desired    = 2
node_max        = 4
ami_type        = "AL2_x86_64"
capacity_type   = "ON_DEMAND"
node_disk_size  = 50

2) Initialize and apply
cd infra/aws
terraform init
terraform apply -var-file="terraform.tfvars"

3) Update kubeconfig
aws eks update-kubeconfig --name jen-staging --region us-east-1 --profile default

4) Validate
kubectl get nodes
kubectl get ns

Cluster hardening (baseline)

- Enable Pod Security Standards at namespace level (restricted)
- Default deny egress; apply allowlist per workload
- Enforce signed images and pinned digests using an admission controller (e.g., cosign policy webhook or Gatekeeper)
- Workload Identity (GCP) / IRSA (AWS) for access to storage and registries

Namespaces and labels

kubectl create namespace jen-system
kubectl create namespace binderhub
kubectl create namespace jen

kubectl label ns jen-system pod-security.kubernetes.io/enforce=restricted
kubectl label ns binderhub  pod-security.kubernetes.io/enforce=restricted
kubectl label ns jen        pod-security.kubernetes.io/enforce=restricted

Storage and registry configuration

- Object storage (select one):
  - GCP: Create GCS bucket jen-staging-artifacts in region us-central1; enable uniform bucket-level access.
  - AWS: Create S3 bucket; enable default encryption and bucket policy aligned to IRSA role.
- Container registry:
  - GCP: Artifact Registry repo us-central1-docker.pkg.dev/jen-staging/registry
  - AWS: ECR repository for JEN components and execution images (pull by digest only)

Secrets and identity

- OIDC client secrets (UI/API and JupyterHub):
  - Create Kubernetes secrets in jen-system and binderhub namespaces:
    kubectl -n jen-system create secret generic jen-oidc-client-secret --from-literal=client-secret=...
    kubectl -n binderhub  create secret generic hub-oauth-client-secret --from-literal=client-secret=...
- ORCID secrets:
    kubectl -n jen-system create secret generic jen-orcid-client-secret --from-literal=client-secret=...
- Storage credentials (if not using Workload Identity/IRSA):
    kubectl -n jen-system create secret generic jen-storage-credentials --from-file=creds.json
- Registry credentials (if needed):
    kubectl -n jen-system create secret docker-registry jen-registry-credentials \
      --docker-server=us-central1-docker.pkg.dev \
      --docker-username=_json_key \
      --docker-password="$(cat creds.json)" \
      --docker-email=devnull@example.org

Helm deployment

1) Create a values overlay for your environment (values-staging.yaml). Use charts/jen/values.yaml as a starting point and override:
- global.environment
- global.objectStorage.provider/bucket/region
- identity.oidc issuer/clientId/secret ref
- archive targets (zenodo sandbox token secret)
- adapter endpoints and secret names

2) Install CRDs/controllers if required (egress controller, admission webhook). If using your own implementations, deploy them first.

3) Deploy core chart
helm upgrade --install jen charts/jen -n jen-system -f charts/jen/values.yaml -f values-staging.yaml

4) Deploy BinderHub (if packaged separately) or ensure subcharts enabled in values. Confirm pods:
kubectl -n binderhub get pods
kubectl -n jen-system get pods
kubectl -n jen get pods

Policy references

- Vulnerability thresholds: policies/vuln-thresholds.yaml enforced via CI/admission
- Egress allowlist: policies/egress-allowlist.yaml realized as NetworkPolicy/egress proxy rules
- Supply-chain policy: docs/security/supply-chain-policy.md is the source of truth for admission requirements

Post-deploy checks

- Ingress and certificates:
  - Confirm DNS A/AAAA records point to the ingress controller; TLS certificate present in jen-staging-tls secret.
- Health/liveness:
  - API gateway responds on /healthz
  - Event bus ready; provenance DB reachable
- BinderHub:
  - Test a simple repo2docker launch; verify pod security context and network egress allowlist.
- Storage:
  - Write test object to artifact bucket; verify fixity checks; ensure immutability on published paths is enforced by policy.
- Admission controllers:
  - Deploy a test unsigned image and confirm rejection
  - Deploy image without SBOM annotation and confirm policy denial (if enabled)

CI triage bootstrap (high level)

- Configure a CI workflow (GitHub Actions/GitLab) to:
  - Validate bundle schema (schemas/ro-crate/jen-rcp-1.0.json)
  - Build container image with repo2docker or Dockerfile
  - Scan SBOM and CVEs; enforce thresholds
  - Run declared command with resource profile (ephemeral namespace, restricted PSS, allowlisted egress)
  - Persist logs and raw artifacts to object storage
  - Emit rerun attestation and mark status in editorial adapter
- Provide CI runner identity with least-privilege access to:
  - Pull/push registry (digest only)
  - Read/write artifact bucket prefixes for triage runs

Cost controls and quotas (pilot defaults)

- BinderHub: idle timeout 30 minutes; max session 2 hours
- Batch: time limit 60 minutes; CPU 2, memory 8Gi default; GPU off by default
- Hardware broker: user concurrent jobs = 2; monthly budgets per user/project

Troubleshooting

- Image pull / auth:
  - Ensure IRSA/Workload Identity roles have proper registry permissions
  - Verify image references are by digest; re-tagging without digest pinning can cause policy denials
- Network policy:
  - If data fetch fails, examine egress denials; update allowlist (temporary exception) with expiry
- CVE gate:
  - Check vulnerability scan report; request a time-bounded waiver with compensating controls if unavoidable
- BinderHub builds:
  - Inspect repo2docker logs; confirm CPU/memory requests; increase cache PVC if frequent evictions

Teardown

- Helm uninstall:
  helm uninstall jen -n jen-system
- Remove namespaces (ensure no PVCs needed for retention):
  kubectl delete ns jen binderhub jen-system
- Terraform destroy clusters:
  cd infra/gcp && terraform destroy
  cd infra/aws && terraform destroy

Appendix: Minimal values-staging.yaml example

global:
  environment: "staging"
  objectStorage:
    provider: "gcs"
    bucket: "jen-staging-artifacts"
    region: "us-central1"
identity:
  oidc:
    issuerUrl: "https://accounts.google.com"
    clientId: "YOUR_OIDC_CLIENT_ID"
    clientSecretRef: "jen-oidc-client-secret"
ojsAdapter:
  endpoint: "https://ojs.example.org/api"
binderhub:
  session:
    cpu: "1"
    memory: "2Gi"
archive:
  zenodo:
    sandbox: true
    depositionTokenSecret: "zenodo-token"

References
- Supply chain policy: docs/security/supply-chain-policy.md
- Vulnerability thresholds: policies/vuln-thresholds.yaml
- Egress allowlist policy: policies/egress-allowlist.yaml
- RO-Crate profile: schemas/ro-crate/jen-rcp-1.0.json
- Helm values baseline: charts/jen/values.yaml