Title: ERA Julia Template (Pilot)
Structure:
- jen-rocp.json: JEN bundle profile skeleton
- params.toml: primary config
- Project.toml/Manifest.toml: environment
- scripts/train.jl: minimal run producing raw artifacts
- scripts/viz.jl: dummy figure regeneration

Usage:
- Update jen-rocp.json fields (title, contributors, licenses, DOIs)
- Pin base environment via Manifest.toml (generate with Pkg.resolve())
- jenx validate; jenx build; jenx run; jenx sbom; jenx attest create
