# F14#0 top trainer fights against the option-(c) bar (main 1e0ddd39)

The bar is COMBAT §7, BOSSES §9 and ACCEPTANCE C2, from the owner's F04#7 option (c). Per top fight and starter, at 24 seeds:
- reader win ≥ 0.75;
- the masher loses its lead in every run;
- the reader's median party HP cost ≤ 0.55× the masher's.

At chapter level, a masher must lose at least one named trainer fight in ≥ 25% of playthroughs.

**Harness:** `tests/smoke_water_named_c2c3.gd --seeds=24 --case=<tess|calder|venn> --party-level=43`. It runs the flat combat_depth arena with harness READER/MASHER pilots and a granted L43 five, all disclosed. The raw data is in `G_*.json` and the summaries are in `RUN_*.txt`.

| Fight | Starter | Reader win | Masher lead-faint | Reader / masher median party cost | Result |
|---|---|---|---|---|---|
| Tess | terrapup / ripplet / galewisp | 1.00 / 1.00 / 1.00 | 1.00 / 1.00 / 1.00 | 0.03 / 0.00 / 0.00 | PASS |
| Calder | terrapup / ripplet / galewisp | 1.00 / 1.00 / 1.00 | 1.00 / 1.00 / 1.00 | 0.00 / 0.00 / 0.00 | PASS |
| Venn, as first measured (`RUN_venn.txt`) | terrapup / ripplet / galewisp | 0.33 / 0.46 / 0.50 | 1.00 | 1.00 / 1.00 / 0.89 | **FAIL** |
| Venn, with `face_lock_fraction` 0.25 (`RUN_venn_face_lock_025.txt`) | terrapup / ripplet / galewisp | 1.00 / 1.00 / 1.00 | 1.00 / 1.00 / 1.00 | 0.03 / 0.01 / 0.19 | PASS |

**Venn's cause and fix.**
- dbe43195 gave Venn's Riptusk the 7 m travelling CHARGER lane with a 0.8 s tell.
- With the default half-tell heading lock, a walking READER had 0.4 s to leave the lane.
- Locking the heading at 0.25 of the tell is the Stormwood F10#2 fix for 0.8 s lane CHARGERs. It uses the whitelisted per-member key, with `_why_face_lock_f14_0` in `water_characters.json`.
- BOSSES keeps the 0.8 s tell.

**Chapter level.** Masher win rates per starter are Tess 0.00 / 0.00 / 0.00, Venn 0.00, Calder 0.00 / 0.04 / 0.00, and Nerissa 0.00 in-world. So 1 − Π(masher win) = 1.00 for every starter, above the 25% bar.
- The observed six-fight playthrough rate is also 1.00: the masher never beats Tess or Venn.

**Named wilds.** Aquaryn and Tidecoil stay on STATE's named-wild ruling, where the ratio and reader win pass (`../aquaryn_c2_3starters/`, `../../../f14_confirm_main/`).
