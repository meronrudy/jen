Name: GCS Storage Adapter
Type: storage
Purpose: Store artifacts, logs, SBOMs, and attestations in Google Cloud Storage.

Configuration:
- bucket, region, credentials via Workload Identity or keyRef

Features:
- Uniform bucket-level access, retention policies, fixity checks

Security:
- CMEK support, audit logs
