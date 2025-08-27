# Replace the base image reference below with a pinned digest per supply-chain policy.
FROM python:3.11-slim@sha256:REPLACE_WITH_BASE_DIGEST

WORKDIR /workspace
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# Install minimal runtime deps (avoid heavy libs in template)
COPY scripts/ /workspace/scripts/
COPY params.toml /workspace/
RUN python -V

CMD ["bash", "-lc", "python scripts/train.py --config params.toml"]
