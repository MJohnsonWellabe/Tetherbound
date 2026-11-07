# VIS-TIDEWAKE look round 14: golden sky + shore water (CPU); ships ON

- Candidate: `golden_sky_candidate` + `shore_water_candidate` out of `sections_off` vs r12b.
- `look_spec.py` rows F39#30a, F39#30b, F13#5; `anchor_tiles.py --seed 1112`, 3 code-blind judges, `calibrate.py`: r 0.87, anchor RMSE 0.42.

| Row | Base | Candidate |
|---|---|---|
| F39#30a shore | 6.02 | 6.02 |
| F39#30b night/dawn/rain/approach | 5.65 | 5.65 |
| F13#5 currents | 5.69 | **5.87** |

- F13#5 gains (2 of 3 judges higher; they read the base's curved bands as guide arcs). The shore rows are scored identically: the golden-hour frame change is not visible to the judges. Ships ON by the owner's any-gain rule (`_why_golden_shore_water_on`, asserted in `test_tidewake_look_profile.gd`).
- Asks: striped dark sand ripple banding at golden hour and dawn; night sand reads as snow; bare dunes with no groves; the Veilfall rebuild (new art).
