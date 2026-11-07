# VIS-TIDEWAKE look rounds 12-13: fall standoff and shore dressing ship ON (CPU)

- Base r12b: shipped tree (night + rain ON).
- r12: `water_veilfall_falls_visual.json` `geometry.standoff_m` 0.8 -> 3.0. A crop of the near frame showed the judges' "black bird" on the fall sheet is a dark rock ridge cutting through the sheet; at 3.0 m it is gone.
- r13: `lesson_clusters_candidate` + `dune_grass_candidate` + `stones_candidate` + `waterline_declutter_candidate` out of `sections_off`.
- One packet with 5 rows; `look_spec.py`, `anchor_tiles.py --seed 1111`, 3 code-blind judges in one message, `calibrate.py`: r 0.79, anchor RMSE 0.72.

| Row | Base | Candidate |
|---|---|---|
| F39#30a shore (r13) | 6.19 | **6.43** |
| F39#30b night/dawn/rain/approach (r13) | 5.71 | **5.88** |
| F13#5 currents (r13) | 5.81 | **5.85** |
| F39#30b (r12 standoff) | 5.75 | **5.85** |
| F39#31 Veilfall (r12 standoff) | 5.40 | 5.40 |

- Both arms gain and ship ON (`_why_shore_dressing_on`, `_why_standoff_3m`; asserted in `test_tidewake_look_profile.gd`, and the `test_tidewake_cause.gd` dunes test now expects the dressing in play).
- Judges single out the base side's evenly scattered pebbles as generator output. The candidate groups the stones and clears the floating markers.
- Still named: a tiered, green Veilfall (new art); a dark finned shape on the fall sheet in some views; oversized pale driftwood logs in the current frames; the night current streaks; striped sand ripple shading.
