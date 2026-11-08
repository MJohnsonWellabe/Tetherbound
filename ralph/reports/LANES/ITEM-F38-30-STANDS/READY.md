STATUS: land
BRANCH: tb/item-f38-30-stands  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, rows F38#30 / F38#24 (Burrow Warrens), 8 Nov 2026. Coordinator decision: land the capture-stand rule alone, as a tool fix with **no score claim**; the art arm is parked; no live-base judge round (the GPU re-judge scores the fixed stands). (`tb/item-f38-30` is LANE-MS's earlier branch; this is a new one.)

## The stand rule (its own commit e8e42a0c)
- `data/config/capture_stands.json` `inside_collision_reseat` (ON) and `tools/phase2_capture_locations.gd` (`_inside_collision_reseat`, static `inside_collision_reseat`). The routes, matrix and other location tools extend it.
- Proof of "inside solid collision": a down ray from 200 m hits a collider above the stand AND all 8 horizontal rays at 1 m (80 m long) hit a collider. Only then the stand is re-seated on the topmost collision surface at the same xz, if it is walkable (the production player's floor limit), with the same heading and camera rig; otherwise the stand is rejected and the existing loop tries the next offset/lateral. A stand with an open side or nothing overhead is never moved.
- Manifests record `inside_collision_reseat` on a re-seated frame, and `rejected_stand_candidates` entries with stage `inside_collision`. TECHNICAL §8.1 has one new line.

## Re-seats seen so far
- **Warrens walk_03** (`meadows__band2_stone_and_root__04__the_burrow_warrens__walk_03_day`): the old stand (-352.5, 2635.8), player y 1.52 with the Bank surface ~19.7 m overhead, and 4 further candidates were all inside the Bank with an unwalkable top (normal y 0.26-0.29, a ~74° flank), so all were rejected. A 5th candidate failed the existing capsule preflight. The loop settled at (-347.6, 2630.8), y 1.77, which has no collider overhead: reachable meadow.
- Warrens walk_02: unchanged (rule did not fire).
- Sheet: `_sheet_stands.jpg` (old walk_03, new walk_03, walk_02, route).

## What the new walk_03 shows (a real defect now)
The visual-only hill shell (`burrow_warrens.json bank.hill_shell`, ~247 m) overhangs reachable meadow beyond the ~145 m Bank collision, so from the reachable stand a player looks up into the shell's culled underside and the chamber shells.

## Parked art arm (a): shell collider, not shipped, code dropped
A two-sided trimesh collider from the shell's own triangles (65,278 triangles; the warrens-space clip_box removes none, so the entrance stays open) was built and probed, then removed. Footprint probe with it on (521 samples: every config coordinate within 150 m of the site in `bands/*/*.json`, `terrain_playground.json` routes densified at 2 m and debug spots, spawn clusters sampled on their radius, plus live CharacterBody3D/Area3D/pickup nodes):
- Road/route points: 0 of 332 under the shell.
- **Would be buried under solid hill (exterior content):**
  - burrowback wild cluster centred (-372, 2605), r ~10, in front of the mouth: all 9 samples; live `Wild_burrowback_3_1` at (-367.7, 2.1, 2611.1), shell 10.4 m overhead.
  - wild cluster 2049 around (-427, 2590), r ~14: 7 of 9 samples; live `Wild_burrowback_2049_1..3`.
  - wild cluster centred (-316, 2650): centre, shell 0.7 m overhead.
  - pickups `BandPickup_b2_mushroom_ironwood` (-374, 2592) and `BandPickup_b2_candy_ironwood_stand` (-350, 2654).
  - harvest node at (-342.2, 2645).
  - one band2 props-cluster prop at (-351, 2611.8).
  - (Interior chamber creatures and the guardian are under it too, as expected inside the dungeon.)
- Players today walk under the visual shell to reach these, so a shell collider would bury them. Nothing was moved.

**Next idea (scopes the next attempt):** a hill built on the Bank height field (visual = collision) that leaves the exterior ring (the burrowback clusters, the two pickups, the harvest node and the prop) uncovered.

Already tried on this item, all parked: shell skirt (VIS-MEADOWS 4 Nov), smaller shell x1.2 / x1.45 (LANE-MS), Bank unhidden (LANE-MS), buried_stand_guard (twice), shell collider (this lane, not clean). Meshy alternative `meadows_burrow_mound` (archive) is a 40 x 41 x 14 m concept with its own tunnel mouth: not a fit for the ~145 m Bank.

## Pre-ready check (main 3bf4ec80 merged)
- `git grep` over tests/ for `phase2_capture_locations`, `phase2_capture_routes`, `capture_stands`, `buried_stand_guard`, `burrow_warrens.json`.
- `run_tests.gd --only=` each of test_catalogue_capture_stand (6 tests, 0 failed), test_meadows_cause_flags (6, 0 failed), test_capture_jobs_args (5, 0 failed; its "Parse JSON failed" log line is pre-existing on main, an intentional bad-JSON case), test_burrow_warrens_visual_identity (9, 0 failed), test_warrens_hill_shell_r2 (2, 0 failed), test_warrens_shell_seat_f38_30 (1, 0 failed).
- `burrow_warrens.json` is unchanged on this branch (the collider was dropped), so the Warrens gameplay smokes do not apply.
- JSON parse: `capture_stands.json`.
- Capture proof: `phase2_capture_routes.gd` Warrens walk_02 + walk_03 on this branch (frames local, sheet committed).

## Files touched
`tools/phase2_capture_locations.gd`, `data/config/capture_stands.json`, `docs/TECHNICAL.md` (one §8.1 line), `ralph/reports/LANES/ITEM-F38-30-STANDS/**`.
