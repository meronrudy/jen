Name: Slurm Adapter
Type: compute-adapter
Purpose: Submit batch jobs to Slurm; stage inputs/outputs; capture logs.

Configuration:
- endpoint (ssh/api), partition, containerRuntime (apptainer), scratchPath
- module load sequence (optional)

Lifecycle:
- init -> map spec to sbatch -> monitor -> collect artifacts

Permissions:
- Access to scratch and artifact storage; limited network egress

Events:
- execution.state.changed, queue.estimate.updated
