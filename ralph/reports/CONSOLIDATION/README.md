# Branch consolidation, 23 Oct 2026: where to start

Owner, 23 Oct 2026: "Get the branches that have stuff that aren't on main consolidated and onto main. That stuff doesn't have to be turned on. You can just flag it. ... make sure the next workers would know where to start with it."

Every lane branch is now on main, or preserved on `tb/archive-2026-10-23`. Main was then slimmed (owner, 23 Oct: "get rid of anything we don't need and aren't going to continue working on"): candidates that no config wires into the game were removed. The lanes are stopped. The open rows, their scores and their order live on the board (`ralph/reports/COORDINATOR/dashboard/criteria.json`) and in STATE, not here. This page says where each lane's unfinished work sits and how to pick it up.

## How to pick up a lane

1. Read STATE §0, then the lane's resume note in the table below. Each note ends with its best candidate, the judges' asks and the next step.
2. The candidate is already on main and flagged OFF. Turn it on only in a judged round (`tools/visual_judge/`, standard prompt, anchors, `calibrate.py`). Done is a mapped Bar A mean of 7.5 or above (CPU-provisional 6.7 until a GPU pass). Record the score in the config's `_why`.
3. If the note names a file that is not on main, restore it from the archive (below).

| Lane | Resume note on main | What waits there |
|---|---|---|
| Creatures (F36#0/#1, F29#3) | `ralph/reports/CREATURES/close-1022/note.md` | On main: the installed-retex candidates that `data/creatures/f36_pose_candidates.json` wires in (Abyssal Guardian, Aeriex, Ripplet, Veridian), all OFF, and the ON Meadowhart pilot. Removed when main was slimmed (restore from the archive): the Terrapup, Bramblebun and Riverdrake naturalistic pilots, and the regen, multiview and saddle candidates. The owner's style bar is Galecrest, Tanglevolt, Stormcapra and Stormursa (`docs/reference/owner-creature-style-bar.png`); new work brings other creatures to that bar. |
| Meshy creature batch | the same note, plus `ralph/reports/CREATURES/close-1020/note.md` | Archive only: the retex rounds r6 to r9 for Voltarach, Mirejaw, Terrapup and Bramblebun, and regen B for Cannonback and Bramblebun. |
| Shared art (P2-017, P2-018, P2-030, P2-033, P2-055, P2-060) | `ralph/reports/SHARED-ART/close-1020/NOTE.md` | `data/config/item_identity_props.json` (P2-033 item props), `data/config/npc_role_accessories.json` (P2-055 NPC silhouettes), and the Meshy capture orb (`data/config/catch_kit.json`: copy `_orb_model_candidate` into `orb_model`). All three are OFF. |
| Look / Meadows / Crossing Hall (F17#6, F38) | `ralph/reports/LOOK/close-1022/NOTE.md`, `ralph/reports/RECAP-MEADOWS/close-1020/NOTE.md` | Archive only: the Hall r9 nave posts at x = ±5.0 (main keeps ±3.3), and the Meadows summit, backdrop and slope-tile Meshy props. |
| Cloudreach (F08#3, F40) | `ralph/reports/CLOUDREACH/close-1022/NOTES.md`, `ralph/reports/RECAP-CLOUDREACH/close-1020/NOTE.md` | P2-021 sky-island spires r5 (6.37 vs 5.19, parked). F08#3 was reopened by the GPU pass. The aviary and stilt-house Meshy props are archive only. |
| Camera / Fights (F10#2, F22#4) | `ralph/reports/CAMERA/close-1020/NOTE.md`, `ralph/reports/FIGHTS/close-1022/NOTE.md` | Nerissa side-channel sweeps (`data/config/water_nerissa_channels.json`, OFF, `tests/test_water_nerissa_channels.gd`) and Veyra wind-lane readability (`data/config/cloudreach_veyra_readability.json`, OFF). |
| Stormwood (F41) | `ralph/reports/STORMWOOD/close-1022/notes.md` | The r12 config snapshot. `stormwood_surge.json` sky phases stay OFF because they break the surge design tests; the note lists the asks. |
| Tidewake (F39) | `ralph/reports/TIDEWAKE/close-1022/NOTES.md`, `ralph/reports/RECAP-TIDEWAKE/close-1020/NOTE.md` | Shoal reshape OFF (gameplay terrain) and the Veilfall entrance gate. The terrace steps are archive only. |
| UI | `ralph/reports/UI/close-1022/NOTE.md` | Nothing pending beyond the note. |
| GPU pass | `ralph/reports/GPU-PASS/NOTE.md`, `LANDABLE.txt` | GPU verdicts: F08#3, F22#4, F36#0 and the F10#2/F04#6/F29#3 reopenings. |
| Net fixes | `ralph/reports/NETFIX/close-1022/NOTE.md` | #1, the trainer-round completion wedge, is still open; its diagnostics are on main. The boss_rewards HP cap is in the archive. |

The surface-finish candidate `data/config/creature_surface_finish_1022_candidate.json` and the shader's `base_value_gamma` and `base_saturation_scale` uniforms are on main. At their defaults (1.0) they change nothing.

## What stayed off main, and how to get it

Only these are off main:
- raw Meshy outputs, candidates and evidence images that no config, test or tool references (~1.3 GB from the branches, ~0.7 GB more removed from main when it was slimmed; the slim-main commit lists what went);
- preview thumbnails;
- per-frame captures;
- live changes that main deliberately left out: creature size growth, the stylised Fulgocobra and Galecrest remakes (the owner stopped stylised remakes), the Crossing Hall r9 post move, and older copies of code that main has newer versions of.

Branch-only work is on `tb/archive-2026-10-23`. Files removed from main stay in main's history: `git log --diff-filter=D --oneline -- <path>` finds the deleting commit, then `git show <commit>^:<path>` restores it. That branch is one commit whose parents are main (1) followed by every branch tip:
2 tb/camera, 3 tb/cloudreach, 4 tb/creatures, 5 tb/creatures-land, 6 tb/creatures-land2, 7 tb/gpu-pass, 8 tb/look, 9 tb/look-land, 10 tb/meshy-batch, 11 tb/meshy-props, 12 tb/netfix, 13 tb/netfix-land, 14 tb/recap-cloudreach, 15 tb/recap-meadows, 16 tb/recap-tidewake, 17 tb/shared-art, 18 tb/stormwood, 19 tb/stormwood-land2, 20 tb/ui-land.

```
git fetch origin tb/archive-2026-10-23
git show origin/tb/archive-2026-10-23^4:<path> > <path>        # one file from tb/creatures
git log --oneline origin/tb/archive-2026-10-23^4 -- <path>    # that file's history on the lane
```

A file restored from the archive starts flagged OFF. It follows the same reference, scale-check, provenance and judging rules as any new asset.
