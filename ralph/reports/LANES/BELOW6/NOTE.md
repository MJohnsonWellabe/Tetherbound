# LANE-BELOW6 NOTE (branch `tb/below6`; this file is the channel)

## State (11 Nov 2026, 20:40 UTC)
| Row | Arm | Status |
|---|---|---|
| F36#86 Voltarach (5.11) | `BELOW6-VOLTARACH` | **ready for GPU, High first** |
| F36#94 Water Mosshell ride and swim (5.81) | `NEWAPPROACH-TRAVELPOSE` on `tb/newapproach` (1833b8a9) | already on the GPU (sent by LANE-NEWAPPROACH); counted as this lane's second arm |
| F36#61 Ribbonray (5.68) | `BELOW6-RIBBONRAY` | prepared; queue when either arm above returns |
| F36#30 Abyssal Guardian (5.54), F36#88 water form (5.85) | `BELOW6-ABYSSAL` | prepared; third in line |

The three creature arms are LANE-REMAKES' work carried over unchanged (files taken from `tb/remakes` ac738b144; folders renamed REMAKES-* to BELOW6-*). All flag-off. One import of this branch serves all three (new `*_floor1*.png` textures, different species). I looked at the three CPU sheets: each shows a clear change in the named defect (gold fields to charcoal with thin cracks; magenta to navy with the tail attached in the hit; less saturated navy with a cream belly).

## For the coordinator
- **Voltarach's 5.11 was scored on the 1 Nov remake, which the owner switched off on 9 Nov.** The base capture in `BELOW6-VOLTARACH` re-baselines the native spider that ships.
- **Meshy is not available in this session: `MESHY_API_KEY` is not set** (`tools/art_pipeline/meshy.py` reads it from the environment only). Until a key is set on the environment, the rows that need a new mesh (Water Abyssal Guardian's spindly build, Ribbonray's anatomy if the grade stays under 6, F36#29 innkeeper body, and any Meshy landform or crown) are limited to scene-level work from installed families.
- **For LANE-THINGS (faint grounding):** Water Mirejaw's 5.52 is the belly-up floating faint only (crimson frills and dark blob both read FIXED 3/3), so that row has no material work left for this lane. LANE-FLOOR2 measured that the existing settle does not reach either water variant (`water_mirejaw`, `water_abyssal_guardian`); its handoff names the early returns in `creature_pose_settle.gd apply` to check first.

## Next for this lane
1. F41#1 Stormheart finale (5.78): crown and glowing core from installed pieces, with LANE-FLOOR2's flag-off mesh lightning (`FLOOR2-STORMBOLT`) as a rider.
2. F40#3 Cloudreach landmark read (5.65) and F40#1 Realm Gate Crag approach landform (5.90).
3. F41#8: `tb/item-f41-8-bodies` (5.72) goes to LANE-PLACES with their storm-light pass when they ask.
4. F39#8 stays parked (no new idea yet).
