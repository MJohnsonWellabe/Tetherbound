# LANE-BELOW6 NOTE (branch `tb/below6`; this file is the channel)

## 12 Nov, about 19:15 UTC: RESTORED-SEA r4 checked on CPU; ready for the GPU re-run

r4 (depth falloff 1.3 of live, waves 0.8, debris cleared) on CPU: the restored foreground is brighter than base at every stand (mean luminance S1 62 -> 88, S2 79 -> 110, S3 35 -> 36, S4 22 -> 35), and live against restored differs by 15-16 at S1/S2. `BELOW6-RESTORED-SEA/` has the r4 sheet and CAPTURE.json with S3/S4 restored as the no-loss set. GPU lane: please re-run on the current head.

Waiting on the GPU: MUSHROOMS, KNIFEEDGE (queued for judging); RESTORED-SEA r4, SWIM r4, STRONGHOLD-STAND at (0, 7130) (pre-checks). Next build: F41#13 Stormraven.


## 12 Nov, about 18:50 UTC: SWIM r4 pushed after the second pre-check hold

r3 was held (arm high above the head, torso and a boot above the water on the GPU frames; my CPU stills showed a low arm, so CPU is not a reliable check for this pose). **r4 is pushed and not CPU-captured**: the arc is gone (arms skim the surface plane), chest 0.10 m under, body nearly flat. GPU lane: please re-run the pre-check on the current head. If r4 is held too I park the pose approach.


## 12 Nov, about 18:30 UTC: reworks pushed; ready to re-run

- **SWIM r3 (F39#5):** pushed, CPU-checked (`BELOW6-SWIM/`). Head, shoulders and upper back at the waterline, one arm low and forward. Ready for the GPU pre-check again.
- **STRONGHOLD-STAND (F38#20):** the block now uses **(0, 7130)**. Every stand from z 7210 up crops the keep's top or sits in the trees; at 7130 the whole keep stands against the sky at the end of the road. Ready for the GPU pre-check again.
- **RESTORED-SEA r4 (F39#17):** pushed, **not yet checked on CPU** (the GPU lane offered a 10-minute re-run of all four stands, which is faster than my 22-minute CPU pass). r1-r3 all lowered values that darken low-sun water; r4 widens the shallow colour instead (depth falloff 1.3 of live, waves 0.8, alpha unchanged, debris cleared). Hold it at the pre-check if S4's foreground is darker than base.
- MUSHROOMS and KNIFEEDGE: still no verdict on tb/item-scout-1108.
- New row taken: F41#13 Stormraven (5.97): eyes and lightning-line feather edges; next build.


## 12 Nov, 16:45 UTC: three arms being reworked; do not judge them until the next NOTE entry

- **RESTORED-SEA (F39#17): SPLIT** (G-below6-restored-sea: S1/S2 row 6.21 -> 6.88, 3/3; S3/S4 6.61 -> 6.17, 0/3: the sunset foreground goes near-black and the day turquoise thins). Cause: I set an absolute depth falloff of 2.2 against a live profile of 16 or more, which shrinks the shallow colour to rings. r2/r3 keep the live colours and scale falloff and waves from the live values (`water_scale`); r3 (falloff 0.8 of live) is capturing on CPU now.
- **SWIM (F39#5): held by the GPU pre-check** (the body floats on the GPU's transparent water and the raised arm reads as a wave). r3 is pushed: chest 0.07 m under the surface, flatter body, narrower arms, the recovering arm low. CPU recapture queued.
- **STRONGHOLD-STAND (F38#20): held by the GPU pre-check** (the keep's top is cropped at z 7405). Screening z 7385, 7365 and (-18, 7350) on CPU now; I will move the block to the first one with sky above the battlements.
- MUSHROOMS and KNIFEEDGE: still no verdict.


## 12 Nov, about 18:00 UTC: BELOW6-RESTORED-SEA ready (F39#17, my top row); queue order

- **F39#17 current restoration (5.50): arm built and proven on CPU.** `ralph/reports/LANES/BELOW6-RESTORED-SEA/`. Flag `water_current_flow_visual.json restored_sea_1112` (OFF). While `water_currents_restored` is set the sea takes a restored look (calmer surface, clearer shallows showing the shoals) and the drifting debris leaves the lanes; it reads the existing replicated fact, nothing else changes. Live against restored at one camera: mean difference 2.4 -> 10.0 on CPU.
- **Coordinator, my queue order once a slot frees (MUSHROOMS and KNIFEEDGE still hold both):** 1. BELOW6-RESTORED-SEA (F39#17, 5.50), 2. BELOW6-SWIM (F39#5, 5.64), 3. BELOW6-STRONGHOLD-STAND (F38#20, needs your stand review). If you would rather swap one of these ahead of MUSHROOMS (a 6-7 row now), do.
- Parked on my side: F40#1 (terraces not sent), F41#8 character side, Fulgocobra, F39#8.


## 12 Nov, about 16:40 UTC: F38#20 stand proposal; two arms ready behind the queue

- **F38#20 stronghold (5.72): stand proposal for your review, coordinator.** `ralph/reports/LANES/BELOW6-STRONGHOLD-STAND/PROPOSAL.md`. The Band 5 approach stand is 590 m from the keep, so the row's two approach frames show a speck (a black cut-out at night). A switched-off candidate stand 130 m from the gate shows the keep, towers, gate ramp and lit windows. `approach_override_for` now reads any enabled `candidates_*` block. The courtyard frame is untouched.
- **Ready and waiting for a slot, in this order:** BELOW6-SWIM (F39#5), then the stronghold stand if you approve it.
- **In flight:** MUSHROOMS, KNIFEEDGE. No verdicts yet.


## 12 Nov, about 15:45 UTC: BELOW6-SWIM ready; waiting for a GPU slot

- **F39#5 swimmer (5.64): arm built and proven on CPU.** `ralph/reports/LANES/BELOW6-SWIM/` (ARM.md, CAPTURE.json, overlay.json, sheet). Flag `human_swim_visual.json surface_crawl_1112` (OFF). Cause: the active stroke candidates sink the chest 0.14 m under the surface with the arms below the body. The arm puts the chest at the surface and lifts the recovering arm out of the water.
- **Coordinator:** MUSHROOMS and KNIFEEDGE still hold my two slots. Queue BELOW6-SWIM as soon as one of them comes back (or now, if you would rather swap it ahead of MUSHROOMS, which is a 6-7 row).
- Next on CPU: F38#20 stronghold (5.72).


## 12 Nov, about 14:40 UTC: F40#1 terraces not sent; five new below-6 rows taken

- **F40#1:** `BELOW6-TERRACES/NOT-SENT.md`. Low terraces from the world's own `_mesa` builder (flag `terrace_mesas_1112`, OFF) went three CPU rounds and end as plain pale-grey drums without strata; I expect level or worse, so it is not queued. Parked on my side until there is a new idea (terrace geometry inside `_mesa`).
- **New rows from G-rescore-stale-tier2 (coordinator, 13:21):** F39#5 swimmer pose (5.64), F38#20 stronghold (5.72), F38#12 harvest rewards (5.89), F40#15 (5.89; the strips are FIXED on its own frames, the rest is the cobble wall and lawn), F41#18 (left to LANE-THINGS' STORMUNIFORM). Next for me, worst-first: F39#5, then F38#20.
- **In flight:** MUSHROOMS, KNIFEEDGE (2 of 2). No verdicts yet.
- A capture of mine died after one frame at about 13:45 with no error in its log; the rerun completed. If the GPU machine or another lane saw a kill at that time, it was not a script error.


## 12 Nov, about 12:55 UTC: owner directions taken (below-6 only; no 0.5 threshold)

- **My rows now:** F41#8 (5.80), F36#46 Fulgocobra (5.87), F40#1 (5.90, back from LANE-PLACES), F39#8 (parked). F38#6, #12 and #14 are LANE-THINGS'.
- **Hesk portrait:** main (c73dcc80) already carries the `plates_by_profile` fix and its test, so no landing is needed. Ignore `tb/below6-hesk-portrait` and `tb/below6-hesk-portrait-2` (the second differs from main only by its READY file; I cut it before checking). Both can be deleted.
- **In flight:** MUSHROOMS and KNIFEEDGE (2 of 2). I will cut a landing for each one that ships.
- **Not shipped under the new rule either:** NAMEDFACES was level (row 5.57 -> 5.57, dialogue +0.04 with 1/3 preferring), so it does not pass the ship rule.

**For LANE-THINGS (F38#6, #12, #14; CPU looks on main, 12 Nov):**
- F38#14: main shows no magenta. The ring is a thin teal circle and the authored capture orb is already on (`camfx.json catch_orb`). In frames 02-05 the orb is small against the creatures and the "broke free / So close" banner sits on every frame, including orb-in-flight and strike. `phase2_capture_catch.gd` only accepts an output under `res://ralph/reports/VISUAL/phase2/<biome>/`.
- F38#6 / F38#12: the Meshy props already differ in silhouette (wrapped candy, potion in a basket, sack on cloth, orb basket, travel pack). The weak one is the `attack_tonic` harvest: a small teal bottle with a glow, about a quarter of the candy's size. `item_identity_props.json` (OFF) lists one authored prop per item family.
- I built nothing on these rows.


## 12 Nov, 12:20 UTC: merged main b3dc2139; overlap with LANE-THINGS on the pickup rows

- `tb/below6` has main b3dc2139 merged (conflicts were the coordinator's own cuts of F40#3 and STORMDECK; main's side taken; 69 lane tests pass).
- MUSHROOMS and KNIFEEDGE: no verdict yet.
- **Overlap, coordinator please decide:** G-things-toys-ui shows LANE-THINGS already working F38#6 (Meadows pickups, tone-down lost -0.84: "small blobs that are hard to identify"), F40#16 (mushroom tone-down level at 5.76) and the catch card (F40#13 shipped). So F38#6, F38#12 and F38#14 look like LANE-THINGS' ground; I will not build on them unless you say so. My MUSHROOMS arm is a different idea from their tone-down (new silhouettes per type, not a smaller cap), but their result is a warning for it: if the judges call the Speed patch too small, the next step is a larger patch (`height_scale` up), not parking.
- With both GPU slots in use and those rows in question, I have nothing else assigned that I can build without duplicating another lane.


## 12 Nov, about 11:10 UTC: F38#14 catch effect, CPU look on main

The recorded defect ("dominant saturated magenta ground ring and flat bright orb") is not what main shows now. In the five catch frames (02 orb in flight to 05 orb shakes) the ring is a thin teal circle and there is no magenta anywhere. What I see instead: the orb is a small grey puff that is hard to find against the creatures, and the "Bramblebun broke free / So close" banner sits at the top of every frame, including the orb-in-flight and strike frames it does not belong to (the F40#13 stale-message item, or the capture's staging). I am waiting for the coordinator's GPU re-score text before building anything here: without the judges' current words a change would be a guess.


## 12 Nov, about 10:45 UTC: BELOW6-KNIFEEDGE sent (GPU slots 2 of 2: MUSHROOMS, KNIFEEDGE)

- **F40#15 black strip: cause found and fixed behind a flag.** It is the end face of the route shoulder `BrokenCausewayMainCliffShoulders/Ridge000`, hanging from a straight line between the row's two outer vertices and so standing up to 0.8 m above the pad crown as a zero-thickness black wall. `cloudreach_visual.json landmass.end_face_follows_row_1112` (OFF) makes every shoulder end face follow its row; render only, collider unchanged. On CPU the strip is gone in the day bridge frame. Folder: `ralph/reports/LANES/BELOW6-KNIFEEDGE/`.
- Coordinator: this and BELOW6-MUSHROOMS can be judged as one Cloudreach batch as you suggested. The two overlays touch different files.
- Also seen in the same frame, not touched: the anchor pylon behind the trainer reads as a white pencil with a gold cone (`CloudreachChapter/lower_west/tether_pylon`).
- Next while these wait: F38#14 catch effect (CPU look first).


## 12 Nov, about 10:10 UTC: new rows taken; BELOW6-MUSHROOMS sent (GPU slot 1 of 2)

Coordinator's new rows (09:14): F40#15, F40#17, F38#14, F38#6, F38#12. Stormursa is not recoloured.

- **F40#17 and F40#15 on main:** both placement defects were already fixed by NEAR6-CR (`rim_pickup_in_view`, `rim_pickup_cluster` ON; F40#15 FIXED 2 of 3). The 8-9 Nov GPU write-up (F-cloudreach) says what now holds F40#16/#17 is "oversized and toy-saturated" caps, and for F40#15 a dark straight strip in the F40#8 bridge frames (next for me).
- **BELOW6-MUSHROOMS is ready for the GPU queue**: `ralph/reports/LANES/BELOW6-MUSHROOMS/`. Flag `mushroom_pickup_variants.json natural_cluster_1112` (OFF): each mushroom find becomes a small patch of installed mushrooms in a muted colour (Speed slate blue, Stamina ochre, Wild rust-orange shelf fungus). Frames: F40#16 (two inventory frames) and F40#17 (two High Perches rim frames). Shared presentation, so Meadows and Stormwood mushroom finds change too.
- Next: the F40#15 dark strip in the bridge frames (probe `tools/probe_p2049_dark_strips.gd`), then F38#14 catch effect.


## 12 Nov, 09:15 UTC: F41#8 character side is parked; I need a row

- **BELOW6-NAMEDFACES: LEVEL** (G-below6-namedfaces, 244c8064): row 5.57 both sides, dialogue 6.39 -> 6.43. The judges cannot see the tint at these distances. `named_tint_1112` stays OFF.
- With the posts (-0.49) that is two character-side attempts on F41#8 without a gain, so the character side is **parked**. What the judges name first on this row is not mine: the Stormwood ground and grade (crushed black posterised patches, flat lavender sky: LANE-PLACES) and pink bears. Bryn's and Hesk's face textures ("blown out", "blotchy and posterised") would need texture work on the installed bodies; no idea yet that I expect to gain 0.5 on a row where the figures are tiny.
- Still good to land: `tb/below6-hesk-portrait` (ride-along data fix).
- **Coordinator: both my assigned rows are parked (F41#8 character side, F36#46 Fulgocobra). GPU slots used: 0 of 2. Please assign the next below-6 row.** One candidate if nobody owns it: the "pink / salmon bears" the judges name on F41#8 and F41#15. Stormursa is an owner style-bar creature, so I will not recolour it without your say; I can first measure whether the salmon is the coat or the storm grade.
- **Measured (09:20):** it is the coat. Stormursa's live albedo has mean hue 353-12 (red-brown, saturation 0.38-0.39, value 0.35-0.52), so under the lavender storm light it reads salmon. A programmatic hue move to about 25-30 (plain brown bear) with the saturation eased would keep species, silhouette and markings and move it off the red side. It is an owner style-bar creature, so this waits for your word.


## 12 Nov, 08:52 UTC: F41#15 is out of the below-6 tier

G-things-stormpost (tb/item-scout-1108 b3ff7d0d): LANE-THINGS' creature clearance with the stormdeck dressing takes F41#15 5.13 -> 6.97 (+1.84, 3/3). It covers the three STORMDECK flags, so `tb/below6-stormdeck-ride` does not need to ride on its own; the coordinator can drop that branch once the stormpost landing carries the flags. Remaining on the row (tier 7 work): Marrow's hair and the left-edge player bloom to white. If BELOW6-NAMEDFACES wins, `named_tint_1112` can take a `marrow` entry for his hair.


## 12 Nov, 08:45 UTC: landing branch for the Hesk portrait fix

`tb/below6-hesk-portrait` (d7ad322b7, cut from main a4ad0486): the `plates_by_profile` data fix and its test only, READY `STATUS: ride-along`. Batch it with any Stormwood landing. BELOW6-NAMEDFACES is still waiting for its verdict.


## 12 Nov, about 08:30 UTC: named posts dropped; BELOW6-NAMEDFACES sent (GPU slot 1 of 2)

- **Named posts: DO NOT SHIP** (G-below6-namedposts: F41#8 row 5.92 -> 5.43, dialogue 6.38 -> 5.65, 0/3). `named_posts_1112` stays OFF; parked.
- **BELOW6-NAMEDFACES is ready for the GPU queue**: `ralph/reports/LANES/BELOW6-NAMEDFACES/` (ARM.md, CAPTURE.json, overlay.json, CPU sheet). Flag `stormwood_character_presentation.json named_tint_1112` (OFF): Maud, Hesk and Bryn's body albedo is multiplied by a neutral grey so their faces stop clipping to white. On CPU the emission floor and the rim were both ruled out first (no change); with the tint, near-white pixels in the dialogue crops fall by a third to a half and features read.
- **Direct data fix riding along (both sides):** Hesk's dialogue portrait was the dark-haired boy (`villager_male`) because his new alpha_tracker body had no plate. `plates_by_profile` now maps alpha_tracker to the installed `sorrel.png` and lost_traveler to `tobin.png`. Bryn's lines already resolved to his own plate. Coordinator: this fix can land with anything; tests `test_stormwood_distinct_body_portraits.gd`.
- Not mine, named by the judges on F41#8: repeated background sentinels and tan-vest figures (new art), salmon bears and cobalt wolves, hard black path patches, the player's own bloom.


## 12 Nov, about 07:10 UTC: F41#8 arm sent (GPU slot 1 of 2)

**BELOW6-NAMEDPOSTS** is ready for the GPU queue: `ralph/reports/LANES/BELOW6-NAMEDPOSTS/` (ARM.md, CAPTURE.json, overlay.json, CPU sheet). Flag `stormwood_character_presentation.json named_posts_1112` (OFF). One installed storm-lantern post beside Elder Maud, Rodkeeper Hesk and Warden-elect Bryn; on CPU the black road around them becomes a warm pool and their legs separate from the ground. Character side only; the road is untouched. No new assets, 0 Meshy credits.

Nothing else of mine is waiting on the GPU. STORMDECK flags and code are unchanged for LANE-THINGS. Fulgocobra stays parked (no new idea yet).


## RESTARTED (12 Nov 2026, about 04:30 UTC, on the coordinator's relay of the owner's direction). `origin/main` d777b905 is merged into `tb/below6`.

| Row | Arm | Status |
|---|---|---|
| F41#15 / F41#7 Marrow's head | landed | PR #918 (4.55 -> 5.95 on his two frames). |
| F40#3 Cloudreach landmark read | landing | in PR #919 (the coordinator's own cut, same content as `tb/below6-f40-3-land` ca60c3d10, which needs no PR). **Evidence for #919, flags ON, lane checkout with main 3b7d04b5 merged:** `--only=capture_approach_overrides,cloudreach_landmark_crowns,cloudreach_old_wind_observatory_presentation,cloudreach_windscar_beacon_site,cloudreach_friendly_palette,cloudreach_production_integration,cloudreach_counterweight_seal,realm_shell_transition_guard,capture_stand`: 10 test files, 41 tests, 614 assertions, 0 failed. |
| Stormheart banners and split wood | `BELOW6-STORMDRESS` | **judged RIDE-ALONG** (Marrow frames +0.48, split frame +0.47, F41#1 row +0.10; all under 0.5, nothing loses). The aged wood rendered rose-mauve on GPU (hue 332); **retuned and measured** (CPU slab hue 35, saturation 0.39; details at the end of its ARM.md). Check the GPU pixel hue before it rides with the next Stormwood landing. |
| Stormheart dressing (warm deck wood, cloth banners, aged split wood) | ride-along landing | **judged RIDE-ALONG** (G-below6-stormdeck: F41#15 row 4.62 -> 5.10, +0.48, 3/3; split frame +0.40, 3/3; no pink, nothing loses). **Ready-made: `tb/below6-stormdeck-ride`** (cut from main 3b7d04b5; three flags ON with `_why_on`, pin test, 40 tests / 5094 assertions pass). READY there says STATUS: ride-along: batch it with LANE-THINGS' Nysa creature clearance, do not land alone. It carries two unjudged flag-off candidates inside `stormheart_tree.gd` (ramp body, core shader), named in its READY. |
| What is left on those frames after it: the flat lavender grade and sky, the dialogue box over Marrow's lower half | none | not started (the grade overlaps LANE-PLACES' storm-light rows) |
| F36#46 Fulgocobra (5.87) | `BELOW6-FULGOCOBRA` | parked, not sent (`NOT-SENT.md`, with a correction) |
| F40#1 Cloudreach open terrain (5.90) | moved to LANE-PLACES (coordinator, 12 Nov) | findings handed over below ("For LANE-PLACES (F40#1 ...)") |
| F39#8 (5.66) | none | parked |

`origin/main` 3b7d04b5 (#918) is merged into `tb/below6`. One merge commit (fa2766d3, never pushed alone) carried conflict markers in two config files; the next commit took main's versions, and every `data/config` JSON parses.

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

**For LANE-PLACES (F40#1 moved to you, 12 Nov):** everything I found is in `ralph/reports/LANES/BELOW6-F40-1/` on `tb/below6`: `NOT-SENT.md` (the bank-UV hypothesis: built, captured, no pixel changed, removed; what the brown band at the Realm Gate Crag approach really is: the island's side wall seen by a camera past the rim, player at (-8.2, 150.1, -152.6), camera at (-9.9, 153.0, -157.4)); `_sheet_cpu_bank_uv_no_change.jpg`; `_sheet_cpu_pad_on_vs_off.jpg` (the row's three frames with the stone trail on and off); `overlay_pad_off.json` and the `candidates_off` switch in `cloudreach_f40_items.json` / `cloudreach_settlement_life.gd items_config` (default unchanged), which lets an overlay skip a candidate that ships ON. Six base frames of the row on today's tree are in my scratch only; the capture command is in the NOTE's earlier sections.
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
