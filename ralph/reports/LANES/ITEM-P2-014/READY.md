STATUS: parked
BRANCH: tb/item-p2-014  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, row 1 of the 8 Nov brief: Meadows cliffs (P2-014, F38#24), `data/config/meadows_hero_pieces.json` `cliffs` / `cliffs_wd`. Coordinator decision 8 Nov: park, no judge round, no noise floor.

## Record before today
- CPU 25 Oct (art1024): 4.89 -> 5.93 (+1.04) at band2_stone_and_root_1.
- GPU 25 Oct MH (`ralph/reports/GPU-PASS/F38-0/MH-meadows-heroes-ace3dd7e20/VERDICT.md`): 5.75 -> 6.15 (+0.40) at both presets; "small and far away".

## Visibility check (today's main 3bf4ec80, CPU Low/Compatibility, quick_judge capture)
Sheets: `_sheet_visibility_matrix.jpg` (band2_stone_and_root_1 day clear approach / gameplay / detail: LIVE | cliffs | cliffs_wd) and `_sheet_visibility_catalogue.jpg` (F38#24 Warrens stands: LIVE | cliffs_wd). Stand job for the matrix stand: `qj_job.json` (`QJ_JOB=` for quick_judge).
- **cliffs_wd is invisible:** 0.9-1.4% of pixels change on the matrix stand and 1.6-5.8% on the F38#24 Warrens stands, the same order as capture noise (the stronghold frames, which no cliff reaches, changed 7-25%). The 247 m live hill shell (`burrow_warrens.json bank.hill_shell`) now swallows cliff_a and the corner; only a sliver of cliff_a shows at a left edge.
- **The visible piece is cliff_b,** the one cliffs_wd drops: a grey stratified outcrop left of the Burrow mouth in the approach, gameplay and detail views. That is what the 25 Oct GPU +0.40 saw.

## Placement check (headless probe of the three modules, not committed)
All three are visual only (no collider) and stand on walkable ground:
- cliff_b protrudes above walkable terrain or Bank in 107 of 136 2 m cells, up to 18 m;
- cliff_a 43 of 90, up to 12 m; cliff_corner 30 of 37, up to 9 m.
A player walks straight through a 15 m rock. cliff_b lies where the live shell already overhangs walkable meadow without collision.
The cliffs_wd rationale (cliff_b "straddles the walking route" at walk_03) referred to the walk_03 stand, which is a seeded random off-route spot inside the solid Bank hill (row 7), not a real route.

## Flags
- ON: none. OFF: `cliffs`, `cliffs_wd`, unchanged.
- Carried to row 7 (Warrens, coordinator 8 Nov): cliff_b **with a collider** may be part of the Warrens composition from reachable stands, only with route/spawn and wild-cluster spacing checks.

## Tests
- No config or code changed; no test applies.
