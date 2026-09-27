# F14#0 — 24-seed top-fight confirmation on main

Harness: `tests/smoke_water_named_c2c3.gd --seeds=24 --party-level=43`, the flat combat_depth arena (harness-simulated fight, so partial by the strict rule), READER/MASHER pilots, starters terrapup, ripplet and galewisp (Aquaryn: ripplet). Script: `confirm.sh`.

Data state: fight data equal to main 025a09d9 (#296 multipliers, #330 merged). The working tree carried only test-harness commits of this lane. Nerissa's process loaded its config before this branch's Break Tether Riptusk change (94d9008e), so these rows are main's Nerissa. Her post-change in-world result is in `../f14_inworld_c2/`.

Result (TABLE.md): 13 rows, 624 runs, 0 errors, 0 stalls.
- Top trainers Calder, Tess, Venn and Nerissa: reader win 1.00 in all 12 rows; masher wipe 0.29–1.00 (≥ 0.25 bar); max hit ≤ 0.244; tells 0.80 s.
- Aquaryn (named wild): reader/masher median lead-cost ratio 0.32 (≤ 0.55), reader win 1.00, max hit 0.066, tells 1.25–1.70 s.

The C2 numbers pass on main. F14#0 still needs its closing witness by ordinary play, which is not provided here.
