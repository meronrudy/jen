Name: BinderHub Executor Plugin
Type: executor
Capabilities:
- Build images via repo2docker
- Launch interactive Jupyter sessions
- Run bounded batch jobs (single-command triage)

Configuration:
- binderhub.url, jupyterhub.url, tokens/secretRefs
- session defaults: cpu, memory, timeouts
- cache: size, eviction policy

Lifecycle hooks:
- install, init, pre-execution, post-execution, on-failure

Permissions:
- Namespace-scoped service account; read/write artifacts object storage

Events:
- execution.state.changed, cache.evicted

Security:
- Non-root, restricted PSS, network egress allowlist per pod
