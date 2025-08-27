Title: ERA Python Template (Pilot)
Structure:
- jen-rocp.json: JEN bundle profile skeleton
- params.toml: primary config
- Dockerfile: pinned-base image (replace TODO with digest)
- scripts/train.py: minimal run producing raw artifacts
- scripts/viz.py: dummy figure regeneration

Usage:
- Update jen-rocp.json fields (title, contributors, licenses, DOIs)
- Pin Docker base image by digest
- jenx validate; jenx build; jenx run; jenx sbom; jenx attest create
