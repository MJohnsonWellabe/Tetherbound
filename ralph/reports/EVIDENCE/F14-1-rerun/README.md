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
- Fennel, Morra and Evi (veilfall_trainer bar: reader lead ≤.55× masher's, reader win ≥.9) on b241114c5, 22:38–23:22 CT. That commit's game code is the same as d83f2d3b7's apart from the guardian-only face lock. All PASS:

| Fight | Reader / masher lead cost (terrapup, ripplet, galewisp) |
|---|---|
| Fennel | 0.000/1.000, 0.000/1.000, 0.291/0.919 |
| Morra | 0.000/1.000, 0.000/1.000, 0.265/1.000 |
| Evi | 0.000/1.000, 0.000/1.000, 0.300/1.000 |

  Reader win 1.00 everywhere; worst hit 0.156.
- The Abyssal Guardian has no fight. BOSSES §4.12 says it is not a combat boss, and water_veilfall.gd builds it as a captive with no collision. The 08 ending piece covers its ceremony.

EV F14#1 PASS d83f2d3b7 every Veilfall fight passes C2 on all three starters at L32 on the current reader (Venn/Nerissa top bar 0.12–0.43; Fennel/Morra/Evi reader ≤0.30 vs masher ≥0.92)
