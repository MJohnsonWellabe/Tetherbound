# VIS-TIDEWAKE look round 18: First Shore declutter (CPU); ships ON

- Candidate: `first_shore_declutter_candidate` (drops `first_shore_driftwood_back`, `first_shore_driftwood_waterline`, `first_shore_work_cluster`) out of `sections_off` vs r18b. Both arms were recaptured after a container restart and reimport.
- `look_spec.py` rows F39#30a, F39#30b; `anchor_tiles.py --seed 1115`, 3 code-blind judges, `calibrate.py`: r 0.95, anchor RMSE 0.26.

| Row | Base | Candidate |
|---|---|---|
| F39#30a shore | 5.64 | **5.73** |
| F39#30b night/dawn/rain/approach | 5.36 | **5.45** |

- Small gain, 2 of 3 judges higher and 1 level. Ships ON by the owner's any-gain rule (`_why_first_shore_declutter_on`, asserted in `test_tidewake_look_profile.gd`; 14 tests, 0 failed).
- Stripe hunt: the golden-hour sand stripes stay with these props removed, so these props are not the caster.
- Asks: the Veilfall approach (slab fall on low-poly cliff; new art), oversaturated electric-blue night water, flat grey rain, bare dunes.
