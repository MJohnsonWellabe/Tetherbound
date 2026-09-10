# Water terrain material pass

Water now uses finer grass, shore and rock texture scale, a less yellow grass tint,
and the existing Terrain3D rotation/shift detiling controls. This changes runtime
materials only; terrain heights, collision, vegetation counts and progression are
unchanged.

Evidence on `codex/broad-visual-pass-0910`, parent `6a1ca77c`:

- Baseline: `shots/catalogue/water/broad-baseline-0910-full/`, 48 day/night frames.
- Candidate: `shots/catalogue/water/broad-material-candidate01/`, 16 matched
  day/night frames across First Shore, Reedhaven, Veilfall and Gull Rest. Native
  NVIDIA Compatibility capture exited 0 with no script errors (84 seconds).
- Fresh blind First Shore judge weakly preferred the candidate, principally its
  smaller cliff pattern. Reedhaven judge found no meaningful location preference.
  Both retain Bar A no, Bar B genre yes, commercial-quality no. This is a modest
  material improvement, not habitat or domain acceptance.
- `tests/smoke_water_opening_continuous.gd` passed first run, exit 0, no script
  errors: arrival, Pell dialogue, physical lesson and 64.487 m swimming. No
  post-arrival fixture writes. Run receipt:
  `.artifacts/broad-visual-0910/runs/material01-water-opening-first/result.json`.
  This is bounded chapter-entry validation, not a full campaign clear.

Ground-cover layering, built-destination composition and night trainer legibility
remain open. The older generated Gull Rest texture was separately judged and held;
that verdict is not evidence about this material pass.
