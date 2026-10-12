# F14#1 re-measure: Veilfall top trainers after the tuning batch and reader fixes (tb/ev-systems-a)
Command: `godot --headless --path . --fixed-fps 60 --script tests/smoke_water_named_c2c3.gd -- --seeds=24 --case=water_trainer_<venn|nerissa> --starter=<s> --party-level=32 --json=<out>`
- Commit d83f2d3b7, 20:23–21:13 CT Sun 11 Oct 2026. It contains the coordinator tuning batch (94df51854, 9f4140536) and reader fix 1032b96d3.
- Party: the retained five at L32 (Veilfall entry). Bare gear, flat collider. Rows are in `rows.txt`.
- Bar (top trainer, COMBAT §7): reader win ≥.75; masher lead-faint 1.00; reader party cost ≤.55× masher's.

| Fight | Starter | Reader win | Masher lead-faint | Party cost reader / masher | Ratio | Verdict |
|---|---|---|---|---|---|---|
| Venn | terrapup | 1.00 | 1.00 | 0.092 / 0.789 | 0.12 | PASS |
| Venn | ripplet | 1.00 | 1.00 | 0.249 / 0.743 | 0.34 | PASS |
| Venn | galewisp | 1.00 | 1.00 | 0.257 / 0.670 | 0.38 | PASS |
| Nerissa | terrapup | 1.00 | 1.00 | 0.370 / 1.000 | 0.37 | PASS |
| Nerissa | ripplet | 1.00 | 1.00 | 0.360 / 1.000 | 0.36 | PASS |
| Nerissa | galewisp | 1.00 | 1.00 | 0.424 / 0.988 | 0.43 | PASS |

- Before: Venn's ratios were 0.68–0.73, a FAIL (F14#1 evidence), because the generic charger rows overrode riptusk's 0.25 face lock.
- C3 measured half: worst hit 0.306 (Nerissa against the Galewisp masher); tells 0.90–1.20 s.
- Masher win against Nerissa is 0.00 / 0.08 / 0.50, so each starter's Tidewake chapter masher-loss is ≥0.50 from Nerissa alone. Before, Galewisp's was 0.12.
- Fennel, Morra and Evi (veilfall_trainer) passed on the earlier reader and are queued for re-measure on the current reader.

EV F14#1 PASS d83f2d3b7 Venn and Nerissa pass the top-trainer bar on all three starters at L32 (ratios 0.12–0.43); Fennel/Morra/Evi re-measure queued
