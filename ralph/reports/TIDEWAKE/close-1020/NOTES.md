# Tidewake lane close, 20 Oct kickoff (tb/tidewake)

CPU renders only: Mesa llvmpipe, `--rendering-driver opengl3` (Low/Compatibility), 1920x1080, xvfb.
Bar: three code-blind judges, Bar A; CPU mean >= 6.7 is met as "CPU-provisional" (owner, 17 Oct); GPU pass must confirm 7.5.

## F13#5 round 1 (docks + currents)

- Control: production (all look candidates OFF), `capture_tidewake_f13_5.gd --only=docks,currents`.
- Candidate: same command plus `--tidewake-look-candidate` (process-local; production `tidewake_look.json` stays `enabled:false`).
- Batched candidate content (one round, per kickoff "batch every change"):
  - Existing OFF look profile (lighting/sky/water/materials, Reedhaven workplace, Sluice winch).
  - NEW `dock_village`: each mandatory dock gains two installed Medieval-kit cottages (slate-blue roofs, recipe colliders) on dry level ground, plus a fish stall/shelter, nets rack, buckets, rope, benches, a blue banner and a lit torch. Footprint guard: skipped unless all nine samples are dry (>=0.8 m) and step <=1.1 m.
  - NEW `current_flow` overlay: beige dashed lane rims off, thinner chevrons, plain driftwood log replaces the oversized hollow `log_large` (read as a placeholder box in the control swim frame).
- Control defects seen before judging (lane self-read, not a verdict): docks are small piers on empty sand; current lanes look like painted road markings; hollow log box in the First Shore shallows.
