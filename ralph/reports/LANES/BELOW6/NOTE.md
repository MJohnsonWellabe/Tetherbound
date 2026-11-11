# LANE-BELOW6 NOTE (branch `tb/below6`; this file is the channel)

## State (11 Nov 2026, 21:45 UTC)
| Row | Arm | Status |
|---|---|---|
| F36#86 Voltarach, F36#61 Ribbonray | landing | **READY TO LAND: `tb/below6-remakes-land`** (1fe7abd3, cut from origin/main 3a514ef5). Voltarach 5.15 -> 6.50, Ribbonray 5.02 -> 6.90 (GPU High, 3/3). Three flags ON with `_why_on`, Abyssal OFF, `tests/test_remakes_floor_landed.gd`, 56 tests / 8987 assertions pass. `ralph/reports/LANES/BELOW6-REMAKES-LAND/READY.md` on that branch, STATUS: land. |
| F36#30 Abyssal Guardian, F36#88 water form | `BELOW6-ABYSSAL` | **on the GPU** |
| F36#94 Water Mosshell ride and swim | `NEWAPPROACH-TRAVELPOSE` on `tb/newapproach` | **on the GPU** |
| F41#1 Stormheart finale (5.78) | `BELOW6-HEARTWOOD` | **ready for GPU, next in line** when one of the two above returns. CPU base and arm captured; sheet and ARM.md in the folder. Adds one static body on the hollow axis (see ARM.md). |
| F36#80 Thundertunnel (5.92) | `BELOW6-THUNDERTUNNEL` (`below6_floor_thundertunnel`, OFF) | grade built (cool brown-grey velvet, blue-white storm lines with emission); CPU pose capture next |
| F36#46 Fulgocobra (5.87) | `BELOW6-FULGOCOBRA` (`below6_floor_fulgocobra`, OFF) | grade built (blacks to blue-charcoal, copper plates to gold); CPU pose capture next |
| F40#3 Cloudreach landmark read (5.65) | `BELOW6-CROWNS` (LANE-MESHY's `landmark_crowns_1111`, OFF) | CPU OFF/ON capture queued after the creature captures. I expect little from the judged frames (observatory tower cut off below the dome; beacon far and small). |
| F36#52 Mirejaw hit-frame smear | none yet | to look at after the captures above (pale translucent jaw and a translucent shape by the trainer in the hit frame) |
| F40#1, F36#29, F41#8, F39#8 | none | not started / handover / parked, as before |

**Meshy:** owner, 11 Nov ("We don't have meshy credits"): no generations. None were made by this lane; credits spent: 0. New art here is Blender or installed families.

**Left on the two landed rows (judges, arm side):** Voltarach's face is one blue eye spot with no head mass, its hit barely differs from standing, some gold sheen on leg tips. Ribbonray's upright two-legged anatomy is mesh: parked without Meshy unless a pose or rig idea turns up.

The three creature arms are LANE-REMAKES' work carried over unchanged (files taken from `tb/remakes` ac738b144; folders renamed REMAKES-* to BELOW6-*). All flag-off. One import of this branch serves all three (new `*_floor1*.png` textures, different species). I looked at the three CPU sheets: each shows a clear change in the named defect (gold fields to charcoal with thin cracks; magenta to navy with the tail attached in the hit; less saturated navy with a cream belly).

## For the coordinator
- **Voltarach's 5.11 was scored on the 1 Nov remake, which the owner switched off on 9 Nov.** The base capture in `BELOW6-VOLTARACH` re-baselines the native spider that ships.
- **For LANE-THINGS (faint grounding):** Water Mirejaw's 5.52 is the belly-up floating faint only (crimson frills and dark blob both read FIXED 3/3), so that row has no material work left for this lane. LANE-FLOOR2 measured that the existing settle does not reach either water variant (`water_mirejaw`, `water_abyssal_guardian`); its handoff names the early returns in `creature_pose_settle.gd apply` to check first.

## Next for this lane
1. F41#1 Stormheart finale (5.78): crown and glowing core from installed pieces, with LANE-FLOOR2's flag-off mesh lightning (`FLOOR2-STORMBOLT`) as a rider.
2. F40#3 Cloudreach landmark read (5.65) and F40#1 Realm Gate Crag approach landform (5.90).
3. F41#8: `tb/item-f41-8-bodies` (5.72) goes to LANE-PLACES with their storm-light pass when they ask.
4. F39#8 stays parked (no new idea yet).
