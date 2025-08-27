Title: Quickstart — Author (Python ERA)
Goal: Create a JEN-compliant bundle, validate, run locally, and prepare for submission.

1) Scaffold
- Copy templates/era-python into a new directory or run jenx init (when available).

2) Pin base image
- Replace Dockerfile base with a pinned digest per supply-chain policy.

3) Validate
- jenx validate --schema schemas/ro-crate/jen-rcp-1.0.json --manifest jen-rocp.json

4) Build and SBOM
- jenx build --strategy auto --tag jen-demo:local
- jenx sbom --image jen-demo:local --format SPDX-2.3 --out jen-sbom.spdx.json

5) Smoke run
- jenx run --image jen-demo:local --config params.toml

6) Attest
- jenx attest create --bundle-doi 10.0000/placeholder --out attestations/rerun.json

7) Submit
- jenx submit --endpoint https://jen.example.org/api --token \$TOKEN
