# Replace with pinned digest base image per policy
FROM julia:1.10-slim@sha256:REPLACE_WITH_BASE_DIGEST
WORKDIR /workspace
COPY Project.toml /workspace/
RUN julia -e "using Pkg; Pkg.instantiate()"
COPY params.toml /workspace/
COPY scripts/ /workspace/scripts/
CMD ["bash","-lc","julia --project -e \"include(\\\"scripts/train.jl\\\"); main(\\\"params.toml\\\")\""]
