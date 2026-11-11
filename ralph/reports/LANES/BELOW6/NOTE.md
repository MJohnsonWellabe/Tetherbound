# LANE-BELOW6 NOTE (branch `tb/below6`; this file is the channel)

## State (11 Nov 2026, 22:35 UTC)
| Row | Arm | Status |
|---|---|---|
| F36#30 Abyssal Guardian | landing | **READY TO LAND: `tb/below6-abyssal-land`** (66017e943, cut from origin/main 8df122a83). GPU High 5.22 -> 5.77 (+0.55, 3/3); water form level. One flag ON with `_why_on`, pinning test updated, 21 tests / 3919 assertions pass. `ralph/reports/LANES/BELOW6-ABYSSAL-LAND/READY.md` on that branch, STATUS: land. |
| F36#86 Voltarach, F36#61 Ribbonray | landed | PR #910 (6.50 and 6.90). Out of the below-6 tier. |
| F36#94 Water Mosshell | won | 4.65 -> 6.67; LANE-THINGS lands it. |
| F41#1 Stormheart finale (5.78) | `BELOW6-HEARTWOOD` | **on the GPU** |
| F36#80 Thundertunnel (5.92) | `BELOW6-THUNDERTUNNEL` | **on the GPU** |
| F36#52 Mirejaw (5.28) | `BELOW6-MIREJAW` (`creature_clip_flags.json below6_mirejaw_hit`, OFF, config only) | **ready for GPU** (Abyssal returned, two in flight). CPU base and arm captured: the hit becomes a readable flinch, no pale gaping jaw, no grey tail blade. |
| F36#46 Fulgocobra (5.87) | `BELOW6-FULGOCOBRA` | **not sent**: no visible change on CPU (`NOT-SENT.md`). |
| F40#3 Cloudreach landmark read (5.65) | `BELOW6-CROWNS` | **not sent**: the dome is out of frame at the observatory and small at the beacon (`NOT-SENT.md`, with what the frames suggest instead). |
| F36#88 Water Abyssal Guardian | none | material lever spent (level on GPU). Leaves the tier at 6.32 once the stage fix lands; the judges' remaining ask (a scaled sea serpent) is a new mesh: parked without Meshy. |
| F40#1 Cloudreach open terrain (5.90) | none | **looked at, nothing built.** CPU base frames captured (six, today's tree): flat lawn, a same-size cobble pad under the trainer, the brown rim skirt across the Realm Gate Crag approach. Eight dressing candidates for this row are already OFF or flat in `cloudreach_f40_items.json` (groves, clumps, sage grass, stone ground, strata terrace, strata landform...), so another prop at the stands repeats a failed approach. The untried lever is the island crown itself (`cloudreach_world.gd _mesa` / the carved crown): a real rise with collision along the gate approach. That is a multi-hour terrain change with route and collision risk; I have not started it and will only do so after the arms in flight return. |
| F36#29 innkeeper (Wilhelm) | none | **needs a GPU baseline, not new art.** The ledger's 5.83 was the score of an old Meshy candidate, not the body that ships (VIS-STORMWOOD READY, 5 Nov). The live innkeeper scored 6.20 on dialogue frames (`VIS-STORMWOOD/qj/qj_inn`) and 7.36 on the F36(0) close stand (`ITEM-F36-29/qj/noise-r0`), both CPU. Two grade arms were flat or worse and are parked. Coordinator: please add the F36(0) innkeeper stand to a GPU High baseline; if it lands at 6 or above the row is not in this tier. |
| F36#30 Abyssal flinch | `BELOW6-FLINCH` (`below6_flinch_abyssal`, OFF) | captured, **held as a rider** (my estimate +0.2 to +0.4): the hit becomes a grounded bowed crouch. **For LANE-THINGS: Voltarach's hit is recipe-driven; the clip-flag route is a no-op for it.** |
| F41#8 (5.31) | `tb/item-f41-8-bodies` | rides with LANE-PLACES' storm-light pass |
| F39#8 (5.66) | none | parked (no new idea) |

**Lane checkout:** `creature_coat_flags.json`, `creature_clip_flags.json` and `tests/test_remakes_floor_landed.gd` are synced to main 8df122a83 (the #910 flags ON) with this lane's OFF flags appended. The branch is not otherwise merged with main (shallow checkout).

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
