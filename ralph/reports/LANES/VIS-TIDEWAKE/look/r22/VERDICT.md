# VIS-TIDEWAKE look round 22: higher low sun (CPU); ships ON

- Candidate: `ov_r22.json` (`lighting_candidate` golden sun pitch -8 -> -12 deg, dawn -5 -> -9 deg) vs p1b (same tree). The terrain shadows that make the First Shore sand stripes (look/probes) get shorter.
- `look_spec.py` rows F39#30a, F39#30b; `anchor_tiles.py --seed 1118`, 3 code-blind judges, `calibrate.py`: r 0.83, anchor RMSE 0.78.

| Row | Base | Candidate |
|---|---|---|
| F39#30a shore | 5.98 | **6.18** |
| F39#30b night/dawn/rain/approach | 5.59 | **5.75** |

- All three judges score the candidate higher on both rows. Ships ON (`_why_low_sun_pitch`, `test_tidewake_look_profile.gd::test_low_sun_pitch_ships_with_its_score`; 15 tests, 0 failed).
- Caveat: the base side's beach creatures spawned as grey lumps in two frames, which the judges marked down; part of the gap may be that.
- The golden stripes are shorter but still named. Remaining asks: bone-white night dunes, grey rain wash, the Veilfall approach (new art).
