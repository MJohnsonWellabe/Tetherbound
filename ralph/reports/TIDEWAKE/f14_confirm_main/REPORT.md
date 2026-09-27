# F14#0 — 24-seed top-fight confirmation on main

Harness: `tests/smoke_water_named_c2c3.gd --seeds=24 --party-level=43`, the flat combat_depth arena (harness-simulated fight, so partial by the strict rule), READER/MASHER pilots, starters terrapup, ripplet and galewisp (Aquaryn: ripplet). Script: `confirm.sh`.

Data state: fight data equal to main 025a09d9 (#296 multipliers, #330 merged). The working tree carried only test-harness commits of this lane. Nerissa's process loaded its config before this branch's Break Tether Riptusk change (94d9008e), so these rows are main's Nerissa. Her post-change in-world result is in `../f14_inworld_c2/`.

Result (TABLE.md): 13 rows, 624 runs, 0 errors, 0 stalls.
- Top trainers Calder, Tess, Venn and Nerissa: reader win 1.00 in all 12 rows; masher wipe 0.29–1.00 (≥ 0.25 bar); max hit ≤ 0.282 (Calder); tells 0.80 s.
- Aquaryn (named wild): reader/masher median lead-cost ratio 0.32 (≤ 0.55), reader win 1.00, max hit 0.066, tells 1.25–1.70 s.

The C2 numbers pass on main. F14#0 still needs its closing witness by ordinary play, which is not provided here.

## Addendum (2026-09-27 10:12): Deep Watch Tidecoil on tb/tidewake 193e08f4 (main plus Tidewake harness/data)
The same harness, `--case=tidecoil`, 24 seeds × 3 starters, 144 runs, 0 errors:
- reader/masher median lead-cost ratios are 0.05 (terrapup), 0.07 (ripplet) and 0.06 (galewisp), against the ≤ 0.55 bar;
- reader win is 1.00 in all three;
- max hit is ≤ 0.055 of entry HP, and tells are 0.80 s.

C2 passes. With this addendum, every named Tidewake encounter passes C2 on current main: Calder, Tess, Venn, Nerissa, Aquaryn and Tidecoil.
