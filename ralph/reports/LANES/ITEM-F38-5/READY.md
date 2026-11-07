STATUS: land
BRANCH: tb/item-f38-5  HEAD: see `git log origin/tb/item-f38-5 -1` (the READY commit; the flag commit is the one before it)

Lane LANE-MS (Meadows). Row F38#5 (P2-017 normal creature scale, grow only). Board 6.19 (GPU 5.16 in item-scores).

All scores are CPU (llvmpipe, Compatibility), from quick_judge with three code-blind judges, anchors pinned, mapped with calibrate.py. Verdicts are in `ralph/reports/LANES/LANE-MS/qj/`.

| Round | Arm | Base -> cand (mapped) | Judges |
|---|---|---|---|
| r1 `F38-5-40dd78cf633f-11071816` | `creatures_f36_taller_than_trainer_4` (bramblebun x1.3, duskhush x1.15) | **6.59 -> 7.37 (+0.78)** | 3/3 prefer; defect PRESENT -> FIXED/PARTIAL |
| r2 `F38-5-6a59b14720f3-11071825` | new `creatures_f36_taller_than_trainer_5` (pipwing x1.15, brooktail x1.15), over r1 ON | **7.14 -> 7.40 (+0.26)** | 3/3 prefer |

The r2 base maps higher than r1's candidate because each batch maps differently. Best: CPU 7.40.

- **Flags turned ON:**
  - `data/config/creature_scale_flags.json:flags.creatures_f36_taller_than_trainer_4.enabled` (r1, 6.59 -> 7.37, `_why_on`).
  - `data/config/creature_scale_flags.json:flags.creatures_f36_taller_than_trainer_5.enabled` (r2, 7.14 -> 7.40, `_why_on`; new grow-only batch).
- **Rules checked:**
  - Every factor is ≥ 1.0 (grow only).
  - None of these four species has an evolution line, so the evolution-order check is not affected.
  - No creature is shrunk.
- **Tests flipped:** in `tests/test_creature_grass_and_height_candidates.gd`, `test_height_batch_4_ships_off_and_only_grows` became `..._ships_on_...`, and I added `test_height_batch_5_ships_on_and_only_grows`.
  - Ran test_creature_grass_and_height_candidates and test_remake_owner1101_finish: **9 tests, 369 assertions, 0 failed**.
- **Files touched:** `data/config/creature_scale_flags.json`, that test, and the qj verdicts.
- **Flags left OFF in this file (not mine to judge here):** `remake_owner1101_body_line` and `remake_owner1101_judged_short`. The second would grow Terrapup past the owner's 3.20 m decision.
- **Judges' remaining asks:**
  - The creatures are pale and low-contrast against the bright trees, and need rim light. That lives in creature coat or material files, which are not this lane's files.
  - A big foreground bush sits in the scale camera. The camera is a fixed stand; no reframing.
  - The quadruped otter and the hare body still read near trainer head height (ears and back line).
- **Next idea:** rim and value separation on the Meadows creatures (creature_coat_flags owner). The row is at 7.40 CPU and needs only +0.10 for the bar. Ask: put this row in the 8 Nov GPU re-judge.
- **Smoke note:** brooktail is a starter, and it is 1.15x taller now. On landing, the coordinator may want one `tests/smoke_arena_contain.gd` run. I did not run it here (RD-36); no test references these flags.
