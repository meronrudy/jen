Title: Tolerance Policies (Pilot Defaults)
Status: Draft

Defaults (override per article where justified)
- Scalars: relative error <= 1%.
- Arrays/curves: normalized MAE <= 1% of dynamic range or SSIM >= 0.98.
- Spike trains: event alignment window <= 2 ms; aggregate rate drift <= 2%.

Determinism
- Seeds required; if nondeterministic, declare bounded variance expectations.

Storage
- Tolerance profile stored in bundle and referenced by attestation.
