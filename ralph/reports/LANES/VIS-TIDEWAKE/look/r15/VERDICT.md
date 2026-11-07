# VIS-TIDEWAKE look round 15: shore surf line (CPU); ships ON

- Candidate: `shore_surf_candidate` + `shore_surf_vary_candidate` out of `sections_off` vs r15b, a fresh base with the shore dressing and standoff ON (round 14 not yet in either).
- `look_spec.py` rows F39#30a, F39#30b, F13#5; `anchor_tiles.py --seed 1113`, 3 code-blind judges, `calibrate.py`: r 0.82, anchor RMSE 0.63.

| Row | Base | Candidate |
|---|---|---|
| F39#30a shore | 5.86 | **6.19** |
| F39#30b night/dawn/rain/approach | 5.49 | **5.54** |
| F13#5 currents | 5.31 | **5.82** |

- All three judges score the candidate higher on F39#30a and F13#5. It ships ON (`_why_shore_surf_on`, asserted in `test_tidewake_look_profile.gd`).
- Judges flag a tall pale light column in one base rain frame, probably a rain-veil streak caught at the capture instant; watch for it.
- Still named: golden-hour and dawn sand stripe banding (round 16 tests calmer ripples), grey rain flattening, bare dunes, night current streaks, and the Veilfall rebuild (new art).
