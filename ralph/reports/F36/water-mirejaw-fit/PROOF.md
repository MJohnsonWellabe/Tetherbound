# F36 Water Mirejaw art fit — OFF candidate, native validation pending

- Baseline `122682ad`; discovered in current F26 Tidewake Medium capture stderr.
- Runtime warns that the specified 3.55m body fits to 3.28m (8% shrink).
- Measured rest bounds: 3.6689887 × 2.7999985 × 9.6997776m; effective radius 1.1823036m.
- Borrowed Paddlenewt allowance 4.8 limits fit to 1.1701417, yielding 3.276395m.
- Full-height fit 1.2678578 needs allowance at least 5.2008381; candidate uses 5.21.
- CREATURES.md updated first; target height, collision radius, model scale and geometry unchanged.
- Water presentation adapter reads the optional allowance only when `fit_candidate.enabled=true`.
- Mirejaw candidate ships OFF; enabled candidates cannot reduce the inherited allowance.
- No current capture source/config was modified while the GPU writer was active.
- Required next: existing Water catalogue test, matched native OFF/ON scale/contact frames and neutral visual review.
- No engine validation, READY, criterion closure or default enabling claimed.
