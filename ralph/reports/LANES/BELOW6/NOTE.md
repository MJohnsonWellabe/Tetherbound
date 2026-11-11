# LANE-BELOW6 NOTE (branch `tb/below6`; this file is the channel)

## State (11 Nov 2026, 21:10 UTC)
| Row | Arm | Status |
|---|---|---|
| F36#86 Voltarach | `REMAKES-VOLTARACH` | **WON: GPU High 5.15 -> 6.50 (+1.35, 3/3).** Landing branch `tb/below6-remakes-land` being cut (tests run once the capture below frees Godot). |
| F36#61 Ribbonray | `REMAKES-RIBBONRAY` | **WON: GPU High 5.02 -> 6.90 (+1.88, 3/3).** Same landing branch. |
| F36#30 Abyssal Guardian (5.54), F36#88 water form (5.85) | `BELOW6-ABYSSAL` | **ready for GPU, High first** (queued on the coordinator's go) |
| F36#94 Water Mosshell ride and swim (5.81) | `NEWAPPROACH-TRAVELPOSE` on `tb/newapproach` (1833b8a9) | on the GPU |
| F41#1 Stormheart finale (5.78) | `BELOW6-HEARTWOOD` (flag `stormheart_presentation.json heartwood_1111`, OFF) | built; CPU base captured, arm capturing. **Not sent.** |
| F40#3 Cloudreach landmark read (5.65) | `BELOW6-CROWNS` (LANE-MESHY's `landmark_crowns_1111`, carried over, OFF) | CPU OFF/ON capture next. From the judged frames I expect little: the observatory frame cuts the tower off below the dome, the beacon is far and small. |

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
