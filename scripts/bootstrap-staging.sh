#!/usr/bin/env bash
set -euo pipefail

# JEN staging bootstrap

ENV=staging
NAMESPACE_SYSTEM=jen-system
NAMESPACE_BH=binderhub
NAMESPACE_APP=jen

kubectl create namespace "${NAMESPACE_SYSTEM}" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "${NAMESPACE_BH}" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "${NAMESPACE_APP}" --dry-run=client -o yaml | kubectl apply -f -

kubectl label ns "${NAMESPACE_SYSTEM}" pod-security.kubernetes.io/enforce=restricted --overwrite
kubectl label ns "${NAMESPACE_BH}"     pod-security.kubernetes.io/enforce=restricted --overwrite
kubectl label ns "${NAMESPACE_APP}"    pod-security.kubernetes.io/enforce=restricted --overwrite

# Secrets placeholders (replace)
kubectl -n "${NAMESPACE_SYSTEM}" create secret generic jen-oidc-client-secret --from-literal=client-secret=REPLACE --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "${NAMESPACE_SYSTEM}" create secret generic jen-orcid-client-secret --from-literal=client-secret=REPLACE --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "${NAMESPACE_SYSTEM}" create secret generic jen-storage-credentials --from-literal=placeholder=REPLACE --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "${NAMESPACE_SYSTEM}" create secret docker-registry jen-registry-credentials \
  --docker-server=us-central1-docker.pkg.dev \
  --docker-username=_json_key \
  --docker-password=REPLACE \
  --docker-email=devnull@example.org \
  --dry-run=client -o yaml | kubectl apply -f -

# Install chart
helm upgrade --install jen charts/jen \
  -n "${NAMESPACE_SYSTEM}" \
  -f charts/jen/values.yaml \
  -f charts/jen/values-staging.yaml

kubectl -n "${NAMESPACE_SYSTEM}" wait --for=condition=Available --timeout=600s deploy -l app.kubernetes.io/name=jen

echo "[*] Staging bootstrap complete."
