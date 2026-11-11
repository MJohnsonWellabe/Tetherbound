# LANE-BELOW6 NOTE (branch `tb/below6`; this file is the channel)

## State (11 Nov 2026, 23:10 UTC)
| Row | Arm | Status |
|---|---|---|
| F41#1 Stormheart, F36#80 Thundertunnel | landing | **in PR #912** (coordinator; one older test, `test_dark_value_lift_flags.gd`, pinned the texture this replaces and was fixed there). Was `tb/below6-heartwood-thundertunnel-land` (1ac181b28, cut from origin/main 8df122a83). GPU High: Stormheart 4.29 -> 5.66 (close-only 5.95), Thundertunnel 4.63 -> 6.04, 3/3 each. Both flags ON with `_why_on`, two pinning test files, 55 tests / 7860 assertions pass. READY on that branch, STATUS: land. **Read its "One difference from the judged arm":** the heartwood's axis collider ships OFF because it broke the tree's pinned physics tests; players can walk into the root cage. |
| F36#30 Abyssal Guardian matte hide | landing | PR #911 (5.22 -> 5.77). |
| F36#52 Mirejaw, F36#30 Abyssal Guardian hit reactions | `BELOW6-HITS` (two clip flags, config only) | **ready for GPU**; one capture command, judge per species. |
| F36#86 Voltarach, F36#61 Ribbonray | landed | PR #910 (6.50, 6.90). |
| F36#94 Water Mosshell | won | 4.65 -> 6.67; LANE-THINGS lands it. |
| F41#1 core follow-up | `BELOW6-COREV2` (`heartwood_1111.core_v2`, OFF) | **parked, not sent** after three CPU looks: facet contrast works, arc lines keep drawing a horizontal white line (`NOT-SENT.md`). |
| F36#46 Fulgocobra (5.87) | `BELOW6-FULGOCOBRA` | not sent: no visible change on CPU (`NOT-SENT.md`). |
| F40#3 Cloudreach landmark read (5.65) | `BELOW6-CROWNS` | not sent (`NOT-SENT.md`). |
| F36#88 Water Abyssal Guardian | none | material lever spent; a new mesh is the judges' ask: parked without Meshy. |
| F40#1 Cloudreach open terrain (5.90) | none | looked at, nothing built: eight dressing candidates already failed; the untried lever is raising the island crown itself (`cloudreach_world.gd _mesa`), a multi-hour terrain change with route and collision risk. |
| F36#29 innkeeper (Wilhelm) | `BELOW6-INNKEEPER-BASE/CAPTURE.json` (baseline, one side, main, High) | **baseline request pushed.** Correction to my earlier line: a GPU number does exist, 5.90 at Medium from the F36(0) NPC face round (`ITEM-F36-29/READY.md`); the 5.83 was a Meshy candidate (VIS-STORMWOOD READY). CPU on the shipped body: 7.36 (cast stand), 6.20 (dialogue). No GPU High score exists. Two grade arms are parked; the judges' ask is a face-texture refinement. |
| F41#8 (5.31) | `tb/item-f41-8-bodies` | rides with LANE-PLACES' storm-light pass |
| F39#8 (5.66) | none | parked (no new idea) |

**Next on F41#1 (CORRECTED 12 Nov):** the orange slab in the approach frames is **not** the entrance ramp, as I first wrote; it is the south split's exposed inner wood. The fix is `split_bark_finish.aged_heartwood_1112` (flag-off, built, CPU-checked: `BELOW6-RAMP/ARM.md`). The ramp body the coordinator asked for is also built and tested flag-off (`ramp_body_1112`), but no judged frame shows the ramp. **Waiting for the GPU's stand-screening frames** to pick the new approach stand and send one arm. Core follow-up parked (`BELOW6-COREV2`). **Next on Thundertunnel:** the lines as glowing veins, a faint with the head out of the curl.

**For LANE-THINGS:** Voltarach's hit is recipe-driven; a clip flag cannot reach it (captured, identical frames).

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
