# LANE-BELOW6 NOTE (branch `tb/below6`; this file is the channel)

## RESTARTED (12 Nov 2026, about 04:30 UTC, on the coordinator's relay of the owner's direction). `origin/main` d777b905 is merged into `tb/below6`.

| Row | Arm | Status |
|---|---|---|
| F41#15 / F41#7 Marrow's head | landing | **READY TO LAND: `tb/below6-marrow-land`** (213cd9ff4, cut from origin/main 2ac7ab843). GPU High: his two dialogue frames 4.55 -> 5.95 (+1.40, 3/3). Both flags ON with `_why_on`, new pin test, `test_character_body_flags` updated, 22 tests / 2192 assertions pass, texture policy PASS. `ralph/reports/LANES/BELOW6-MARROW-LAND/READY.md`, STATUS: land. Coverage gap: the Nysa frame was not judged (2 of the row's 3 frames). |
| F40#3 Cloudreach landmark read | `BELOW6-F40-3` | **judged: re-baselined at 6.33 (board 5.65), arm vs base +0.33, 2/3 prefer** (G-below6-f40-3-landmarks, cb3ff531). The row is above 6 on the new stands. **Coordinator: your call whether the two stands and the crowns land** (two stands moved, so LANE-SCOUT calls it a new baseline, not a ship; the gain alone is under 0.5). Still named: the Skyroad Arch frame shows no arch; the observatory path is a blurry strip and its plateau a hard-rimmed cylinder. **Now screening stands for the Skyroad Arch on CPU.** |
| F41#15 / F41#7 Marrow frames (5.95) and F41#1 (6.81): banners and the orange split wood | `BELOW6-STORMDRESS` (`banner_cloth_1112` + `aged_heartwood_1112`; three frame sets) | **ready for GPU.** Supersedes `BELOW6-SPLITWOOD` (do not queue both). The "blue slab at the left edge" in Marrow's frames is an ascent banner; the "orange trunk" is the split's exposed wood. |
| Stormwood top-deck dialogue look, what is left: one flat lavender grade, tiled pink-lilac planks, the dialogue box over Marrow's lower half | none | not started (scene light and grade overlap LANE-PLACES' storm-light rows) |
| F36#46 Fulgocobra (5.87) | `BELOW6-FULGOCOBRA` | parked, not sent (`NOT-SENT.md`, with a correction) |
| F40#1 Cloudreach open terrain (5.90) | none | not started |
| F39#8 (5.66) | none | parked |

`origin/main` 2ac7ab843 is merged into `tb/below6` (264f2e6a).

Merge notes: main's landed versions won every conflict. Kept on top, flag-off: `ramp_body_1112`, `aged_heartwood_1112`, `heartwood_1111.core_v2`, `below6_floor_fulgocobra`, `below6_marrow_self_lit_off`, `identity_floor_1112`, `landmark_crowns_1111`. Dropped: `below6_flinch_abyssal` (lost on GPU). After the merge, `--only=stormheart,creature_coat_flags,creature_clip,character_body_flags,capture_approach_overrides,remakes_floor_landed,below6,texture_import_policy,dark_value_lift`: 20 test files, 60 tests, 1 failed (the broken Fulgocobra path, fixed; `creature_coat_flags` re-run: 6 tests, 0 failed).

---

# Wrap-up of 12 Nov 02:45 UTC (kept for its tables and runbook; superseded by the restart above)

## WRAPPED (12 Nov 2026, about 02:45 UTC, on the owner's wrap-up direction). No new arms. Everything is pushed.

### 1. Ready to land now
| What | Branch | Verdict |
|---|---|---|
| **F41#1 Stormheart approach stand, ON** (capture_stands `approach_overrides`, the `phase2_capture_locations.gd` hook, its test, a TECHNICAL §8.1 bullet; aged heartwood NOT included) | **`tb/below6-stormheart-stand-land`** (2844f884d, cut from origin/main 6eae79177). `ralph/reports/LANES/BELOW6-STORMHEART-STAND-LAND/READY.md`, STATUS: land. 17 tests / 61 assertions pass. | G-below6-stormheart-approach: row 5.10 -> 6.81 (+1.71, 3/3) |

### 2. Already on main or in the coordinator's PRs (nothing to do)
Voltarach and Ribbonray coats (#910); Abyssal matte hide (#911); Stormheart heartwood and Thundertunnel coat (#912); Mirejaw grounded hit (#914, cut by the coordinator). Water Mosshell travel pose was landed by LANE-THINGS.

### 3. Not on main, not judged: built flag-off on `tb/below6`, each needs a GPU verdict before it could land
| Item | Flag (OFF) | Files | State |
|---|---|---|---|
| **F41#15 / F41#7 Captain Marrow's white head** | `character_body_flags.json below6_marrow_self_lit_off`; `stormwood_character_presentation.json identity_floor_1112` | `character_model.gd` (one allowed body-flag key), `stormwood_character_presentation.gd`, `captain_a_lod0_texture_0_floor1.png` + sidecar; `BELOW6-MARROW/` (ARM.md, CAPTURE.json, overlay, two sheets) | **Ready for GPU, never captured there.** The cause is found (he emits his own texture plus a floor from the Stormwood presentation file). CPU: body fixed, face only faintly readable. This is the biggest open gap on the list (4.49) and the one thing here most worth a GPU run. |
| F41#1 split trunk's orange exposed wood | `stormheart_presentation.json split_bark_finish.aged_heartwood_1112` | `stormheart_split_wood.gdshader`, `stormheart_split_bark.gd`; `BELOW6-RAMP/` | CPU-checked; needs one split-facing frame as its own small arm (no judged frame shows the split from the new stand). |
| F41#1 entrance ramp body | `stormheart_presentation.json ramp_body_1112` | `stormheart_tree.gd _ramp_body`, `tests/test_stormheart_ramp_body.gd` | Built and tested; no judged frame shows the ramp. Built on my wrong first diagnosis of the orange slab. |

### 4. Losing or parked experiments (flag-off on `tb/below6`; no landing needed)
- `creature_clip_flags.json below6_flinch_abyssal`: **lost on GPU** (-0.25, 1/3; adds a white block at the front foot in hit 025 and 050). Drop.
- `stormheart_presentation.json heartwood_1111.core_v2` and `stormheart_heartwood_core.gdshader`: parked after three CPU looks (`BELOW6-COREV2/NOT-SENT.md`).
- `creature_coat_flags.json below6_floor_fulgocobra` (+ its texture and the `fulgocobra` grade in `grade_remakes_floor.py`): not sent, no visible change on CPU.
- `cloudreach_visual.json landmark_crowns_1111` (LANE-MESHY's, carried over): not sent, the dome is out of frame or tiny.
- The heartwood's optional axis collider (`body_enabled`, OFF, already on main inside #912): stays off; it breaks the tree's pinned physics tests. A player can walk into the root cage.

### 5. A fix that is on `tb/below6` only and is worth taking with any later landing
None beyond section 3. The lane's copies of `creature_coat_flags.json`, `creature_clip_flags.json` and `tests/test_remakes_floor_landed.gd` were synced to main at 8df122a83 and are now behind main (#911, #912, #914 flipped flags there): **do not land those three files from this branch.**

### 6. Below-6 rows as I leave them
| Row | Score | Where it stands |
|---|---|---|
| F41#15 Marrow's head | 4.49 | arm ready, unjudged (section 3) |
| F40#3 Cloudreach landmark read | 5.65 | crowns not sent; the frames say the row is about framing and bare ground, not what sits on the landmark |
| F39#8 Aquaryn mounted water | 5.66 | parked, no new idea |
| F36#46 Fulgocobra | 5.87 | grade not sent; a rim, not an albedo lift, is the untried idea |
| F40#1 Cloudreach open terrain | 5.90 | nothing built; eight dressing candidates already failed; the untried lever is raising the island crown itself |
| F41#1 Stormheart | 6.81 with the new stand | out of the tier once the stand lands; judges still name the missing crown, decal banners, a black pool with an orange crack line, smooth trunks |
| F36#52 Mirejaw | 6.32 | out of the tier; the snout still renders whitish in hit frames (PARTIAL 3/3), the tail still passes the trainer |
| F36#29 innkeeper | 7.03 | GPU High baseline done; out of the tier |
| F36#88 Water Abyssal Guardian | 6.32 with the stage fix | needs a new mesh |

### 7. Runbook additions from this lane
- **Build the subject through the real path before tuning it.** Marrow's material is built by `decorate -> trainer_npc.model_config -> character_model`; printing that material showed the emission texture and where the floor came from in one headless run, after three GPU arms had changed the wrong file.
- **A CPU frame that reproduces a "glow" rules out bloom.** Then switch one contributor off per capture and measure a face box and a body box.
- **Check that a built fix changes the judged frame before writing it up.** I took the orange slab for the ramp, built a ramp body, and only then saw the frame unchanged.
- **Landing tests catch contract breaks the arm did not:** the heartwood's collider broke the tree's pinned physics; an older test pinned Thundertunnel's replaced texture. Grep `tests/` for the species, flag and texture names before a landing.
- Landing branches without a worktree: `GIT_INDEX_FILE=<tmp> git read-tree <main>`, `git update-index --add --cacheinfo` per file, `write-tree`, `commit-tree`, push the commit to the branch name.
- Outdoor Stormwood frames take about 5 minutes each on CPU, dialogue frames about 10 minutes a launch; screen stands on the GPU with `--spot=<id>@x,z@heading`.
- Never `git add` a glob that can match locally excluded `.uid` files: the add fails and takes the `&&` chain with it.
- **Meshy:** no generations (owner, 11 Nov). Credits spent: 0.

---

# Earlier state (superseded by the wrap-up above)

## State (12 Nov 2026, about 03:30 UTC)
| Row | Arm | Status |
|---|---|---|
| F41#15 (4.49), F41#7 (6.24): Captain Marrow's white head | `BELOW6-MARROW` (two flags, one new texture) | **ready for GPU.** Cause found: he emits his own texture plus a 0.18 floor that comes from `stormwood_character_presentation.json`, which no earlier arm touched. Body fixed on CPU; the face only partly (scene light remains). See ARM.md. |
| F41#1 Stormheart approach frames | `BELOW6-RAMP` (new approach stand from the GPU screen + aged heartwood) | **ready for GPU**, all four frames. Read ARM.md: my first diagnosis (the ramp) was wrong and is corrected there. |
| F36#52 Mirejaw, F36#30 Abyssal Guardian hit reactions | `BELOW6-HITS` | ready for GPU (queued by the coordinator as BELOW6-MIREJAW earlier) |
| F36#29 innkeeper | `BELOW6-INNKEEPER-BASE/CAPTURE.json` | baseline request pushed (one side, main, High) |
| F41#1 heartwood, F36#80 Thundertunnel | landing | PR #912 |
| F36#30 Abyssal matte hide | landing | PR #911 |
| F41#1 core follow-up | `BELOW6-COREV2` | parked, not sent |
| F36#46 Fulgocobra, F40#3 crowns | | not sent (NOT-SENT.md in each folder) |
| F36#88 Water Abyssal Guardian | | material lever spent; needs a new mesh: parked |
| F40#1 Cloudreach open terrain (5.90) | none | nothing built; the untried lever is raising the island crown itself |
| F41#8 (5.31) | `tb/item-f41-8-bodies` | rides with LANE-PLACES' storm-light pass |
| F39#8 (5.66) | | parked |

**For LANE-PLACES (storm light):** after Marrow's own emission is off, the DynamoCore deck's scene light still clips a pale face on CPU. Captain_b (Nerissa) has the same missing `body_emission_enabled` in `art.json`.
**For LANE-THINGS:** Voltarach's hit is recipe-driven; a clip flag cannot reach it.
**Meshy:** no generations (owner, 11 Nov). Credits spent: 0.

**Lane checkout:** `creature_coat_flags.json`, `creature_clip_flags.json` and `tests/test_remakes_floor_landed.gd` are synced to main 8df122a83 (the #910 flags ON) with this lane's OFF flags appended. The branch is not otherwise merged with main (shallow checkout).


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
