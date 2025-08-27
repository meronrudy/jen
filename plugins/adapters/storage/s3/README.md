Name: S3 Storage Adapter
Type: storage
Purpose: Store artifacts, logs, SBOMs, and attestations in S3-compatible object storage.

Configuration:
- bucket, region, endpoint (optional), pathStyle, credentialsRef or IRSA

Features:
- Fixity checks on ingest, versioned storage for published artifacts, signed URLs

Security:
- SSE-KMS encryption, IAM-scoped policies, audit logs
