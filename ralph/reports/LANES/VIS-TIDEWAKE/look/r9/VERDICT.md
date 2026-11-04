# VIS-TIDEWAKE look rounds 9-10: rain trio ships ON; current bands stay OFF (CPU)

- r9: `rain_fog_candidate` + `rain_grade_candidate` + `rain_veil_candidate` (all unjudged until now) vs r8b, the same tree with the rain sections off.
- r10: `current_bands_candidate` vs r8c (night ON in both).
- One packet with 4 rows; `look_spec.py`, `anchor_tiles.py --seed 1109`, 3 code-blind judges in one message, `calibrate.py`: r 0.69, anchor RMSE 0.58. The fit is weaker than in recent rounds, but every judge moves in the same direction on every row.

| Row | Base | Candidate |
|---|---|---|
| F39#30a shore (rain) | 6.09 | **6.29** |
| F39#30b night/dawn/rain/approach (rain) | 5.81 | **6.04** |
| F39#31 Veilfall (rain) | 5.29 | **5.56** |
| F13#5 currents (bands) | 5.95 | 5.59 |

- Rain ships ON (`_why_rain_on`, asserted in `test_tidewake_look_profile.gd`): judges now see rain streaks and a cool overcast. One judge per row still finds the far rain fog eating the Veilfall in the distant rain frame.
- Current bands stay OFF. Judges prefer the shipped short curved crescents, and the long bands read as guide lanes again. The night current frame still shows long streaks in both arms.
- Asks: the Veilfall as a tiered, green mountain with several falls, mist and an arch (new art; round 11 tests the installed cascade tiers and cladding); dress the empty dune midground; boats and planks float like slabs.
