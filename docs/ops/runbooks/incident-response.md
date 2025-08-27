Title: Incident Response Runbook (Pilot)
Scope: CI triage, execution backpressure, admissions denials, storage, identity.

Severities:
- SEV1: user-visible outage or data loss risk
- SEV2: partial impact or degraded SLOs
- SEV3: non-urgent issues

Checklist:
- Declare incident; assign commander; open comms
- Triage: identify failing SLO, component, blast radius
- Mitigate: scale, rollback, disable feature flag, apply exception
- Communicate: status page updates and partner notices
- Post-incident: timeline, root cause, corrective actions
