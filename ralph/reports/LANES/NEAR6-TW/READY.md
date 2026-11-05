# NEAR6-TW lane (tb/near6-tw-1104): Tidewake F39 items scored 5.4–6.0, CPU quick-judged

## Taken (coordinator 19:25)

- **r12, F41#12, not judged, held OFF:** `puddle_candidate` renders as flat lavender sky-reflecting discs on the road. VIS-STORMWOOD's READY records the same puddles already judged as flat slabs (3/3, v1/b10), so this repeats a known failure. The remaining F41#12 asks (white-violet lightning instead of a gold decal, edge wear, form) need a road-current shader rework; not tried.
- **r14s, F41#14, worse (5.57 -> 5.26), held OFF:** tier_candidate at 1.45/1.6/1.75x. The tier read is FIXED, but the enlarged Rare cluster blooms into a flat yellow burst that 3/3 judges call an effect slab. Round 2, r14t (1.3/1.3/1.05x): not judged, because Rare's three overlapping copies still bloom into a yellow shard burst at the smaller size. r14u: Rare as one sweet (1.2x), Great a pair (1.3x), Good 1.2x. Judged: 4.49 -> 4.78 (+0.29, under 0.5; one judge calls the tier read FIXED, two PARTIAL). Held OFF, because it would also break the tier count and size ordering that `test_storm_cams_candidates` asserts. **F41#14 is parked** after two rounds under 0.5; it needs new tier art (distinct shapes), not scale.

- **F41#12** (charged road, 5.63): judging the existing unjudged `stormwood_road_current.puddle_candidate`.
- **F41#14** (candy tiers, 5.70): `pickup_grounding.tier_candidate` with larger tiers (1.45/1.6/1.75x; the arm had shrunk them, while the judges call them pinhead-sized).
- **F39#2**: parked here after two failed rounds; new art. **F39#31 and F13#5 are left to VIS-TIDEWAKE**, which has them in flight.

## Taken from VIS-STORMWOOD (coordinator 16:44)

- **F41#10 Glass Sink: the pale white wall. DONE, ON 4.84 -> 5.36:** the wall was `HollowCrownSilhouette` (stormwood_crown_overlook massif), whose 300 m visibility start sat inside its own 560 m footprint, so stands on the Crown island saw its inner cliff. One judge flags the trunk revealed at the left edge as red-brown; two read it as bark.
- (original note) on the left of every F41#10 frame. VIS-STORMWOOD's arms left it untouched and the source is unknown. This lane traces the source and tries a scene-level fix (lighting, material or fog on the real node). VIS-STORMWOOD should skip it; its material arms (obsidian, wall_grade) are not touched. The line cannot go into VIS-STORMWOOD's READY.md from here: this lane pushes only tb/near6-tw-1104.

## Handoff update (15:00 UTC)

- **Second batch (coordinator, 11:45):** F39#24 rest poses ON 5.02 -> 6.69; F39#16 live current seams ON 5.96 -> 6.54 (both in the table below, tests passing). F39#21 is blocked on CPU (victory lifecycle needs continuous rendering; see Blockers). F39#15: one no-change round. F39#3: scene lever already shipped; the remainder is new art.
- **Harness fixes this batch:** `phase2_capture_creatures.gd` authored-rest wait counts game time (CPU rest captures timed out); quick_judge matches one-off fight moments (win, aftermath) by tag.

## Handoff (12:00 UTC)

- **Ready to land (ON, judged, tested):** F39#14 swim wake 6.10 -> 6.80; F39#20 fight-ring hide 5.87 -> 6.42; F39#27 Tidewake character rim 6.03 -> 6.23; F39#1 shore sites + built feather 6.37 -> 6.44. The table below has flags, tests and commits. The touched tests and `test_texture_import_policy` pass.
- **Held OFF (code stays, inert):** F39#7 `contact_spacing.all_pairs` (worse); F39#19 `hud_subject_fade.roster_floor` (no CPU repro of the fade); F39#6 `creature_pose_settle.tidewake_scope` (worse); F39#4 `shiny_cue.overlay` (flat).
- **Parked, needing new art or a new idea:** F39#6 faint (the remake Riptusk has no recipe), F39#4 (shiny repaint on secondary regions), F39#2 (Veilfall rebuild).
- **Open candidates:** F39#7, one more round, from the trainer side: keep the trainer out of the pair's lane. F39#19 needs a GPU-side look at why the roster reads pale.
- **Harness fixes in `quick_judge.py`:** the Tidewake `water__` frame lookup, and the fight `<trainer>/<tag>-<s.ss>` frame lookup (nearest tell moment).
- **Runbook:** `runbook/chain*.sh` (step + .done markers in `.artifacts/run`), `ov_*.json` overlays. Every candidate gets a frame pre-check (diff + side-by-side) before judges are spent.

Owner rule (4 Nov): any judged CPU gain ships ON; only flat or worse stays OFF. Yardstick: `tools/visual_judge/quick_judge.py` (JUDGE_PROMPT verbatim, 3+ anchor pairs, 3 fresh code-blind judges, calibrate.py), with VIS-TIDEWAKE's `water__` frame-lookup patch applied locally (`runbook/` uses it; not committed here to avoid a conflict with tb/vis-tidewake-1104).

## Landing-ready flags

| Flag | Row | CPU base -> cand | Test | Commit |
|---|---|---|---|---|
| `water_character_rim.json` `enabled` (Tidewake named NPC/trainer rim + front fill) | F39#27 | CPU 6.03 -> 6.23 (3/3 judges higher; anchor RMSE 0.79 caveat) | `tests/test_near6_tw_judged_on.gd` (+ `test_creature_rim`, `test_texture_import_policy`: 7 tests, 0 failed) | this commit |
| `human_water_contact_visual.json` `wake_trail.enabled` (longer, spreading trail rings) | F39#14 | CPU 6.10 -> 6.80 (3/3 judges higher, RMSE 0.52) | `test_near6_tw_judged_on.gd::test_swim_wake_trail_ships_on`; `test_human_water_contact_visual.gd` idle step now runs past the configured lifetime (13 tests, 0 failed) | this commit |
| `water_dune_cover.json` `shore_ecology_candidate.shipped_sites` += welcome_bay, horizon_headland, east_beach; `water_ground_cover.json` `built_feather_enabled` | F39#1 | CPU 6.37 -> 6.44 (2 judges higher, 1 equal; RMSE 0.41) | `test_water_dune_cover.gd::test_shipped_shore_site_places_while_the_candidate_stays_off` now lists the judged sites; unjudged islands still never place (15 tests, 0 failed) | this commit |
| `water_resource_models.json` `fight_ring_hide.enabled` (+ `pickups`): Tidewake gather nodes and world pickups stand aside inside a fight ring | F39#20 | CPU 5.87 -> 6.42 (3/3 judges higher, PRESENT -> FIXED 3/3) | `test_near6_tw_judged_on.gd::test_fight_ring_hide_ships_on` (+ `test_fight_ring_occluders`: 16 tests, 0 failed) | this commit |
| `water_creature_rest_visual.json` `prone_rest.enabled`: Riptusk and Torrentoad rest upright, settled belly-down | F39#24 | CPU 5.02 -> 6.69 (3/3 judges higher, PRESENT -> FIXED 3/3) | `test_near6_tw_judged_on.gd::test_prone_rest_ships_on` (+ `test_creature_rest_pose`, `test_companion_presence`, `test_texture_import_policy`: 54 tests, 0 failed); capture fix `phase2_capture_creatures.gd` (the authored-rest wait counts game time) | 2bab77374 |
| `tidewake_look.json` `current_flow` live seams 0.3 -> 0.1, caps 0.45, flecks 0.16; seam_wander 9, seam_gap 0.65 (`_why_near6_live_seams`) | F39#16 | CPU 5.96 -> 6.54 (3/3 judges higher, guide-lane defect FIXED 3/3; 2 judges note the current now reads faint) | `test_near6_tw_judged_on.gd::test_live_current_seams_ship_softened` (+ current-flow, look-profile, cause tests: 27 tests, 0 failed) | this commit |
| `stormwood_crown_overlook.json` `massif.near_hide_1104.enabled` (Crown silhouette begins at 470 m, beyond its 560 m footprint; was 300 m) | F41#10 | CPU 4.84 -> 5.36 (3/3 judges higher; the pale left wall was the silhouette seen from inside; RMSE 0.64) | `test_near6_tw_judged_on.gd::test_crown_massif_near_hide_ships_on` (+ crown_overlook, hero_landmarks, stormwood_look: 27 tests, 0 failed) | this commit |

## Arms built (all OFF, commit 6cd7f370)

| Row | Item | Flag (default OFF) | Change |
|---|---|---|---|
| F39#6 | P2-028 faint | `data/creatures/f36_pose_candidates.json` `lane_role_flags.uiposes_riptusk_side_faint_prone_rest.enabled` (UIPOSES arm, never judged) | Riptusk faint rolls onto its side, head dropped |
| F39#14 | P2-072 swim contact | `human_water_contact_visual.json` `wake_trail.enabled` | Longer-lived trail rings (12, 2.4 s) that spread to 2.3x as they fade: a widening wake |
| F39#27 | P2-057 named characters | `water_character_rim.json` `enabled` | Tidewake named NPC and trainer bodies wear the existing character rim overlay, warm sand tone, plus a soft front fill (new shader uniform `fill_energy`, default 0 so Stormwood is unchanged) |
| F39#7 | P2-089 fight composition | `combat.json` `contact_spacing.all_pairs.enabled` | Every ally/foe pair uses the hollows_alpha fix (render-box support, 14 m/s swept correction); clearance and reach unchanged |
| F39#19 | P2-088 roster contrast | `combat.json` `hud_subject_fade.roster_floor.enabled` | The fight roster holder never fades below alpha 0.9 |

## Verdicts

- **r6, F39#6, flat (5.29 -> 5.29), held OFF:** `uiposes_riptusk_side_faint_prone_rest` cannot reach the shipped Riptusk. It now renders the owner1101 remake, which has no F36 recipe, so A and B were pixel-identical (3/3 judges). The new arm is `creature_pose_settle.json` `tidewake_scope` (CAUSE-POSES settle, scoped to ripplet, riptusk and aquaryn, with the roster master still OFF). It is queued as r6b.

- **r7, F39#7, worse (6.19 -> 5.42), held OFF:** with `contact_spacing.all_pairs` on, all three judges saw Ripplet pressed into Cannonback and the trainer against Ripplet's tail; the base kept clear sand. Round 1 of 2 on this item.
- **r19, F39#19, not judged (no visible change):** `roster_floor` changed nothing on CPU. The roster region differs by a mean of 0.2–1.2 per pixel, because the subject fade never takes the roster down in these three stands. The arm stays OFF. The pale roster the GPU judges describe needs another cause.
- **Harness fix (quick_judge `find_frame`):** fight tools write `<trainer>/<tag>-<sss.ss>.png` for `..__fight__<trainer>__<tag>-<sss_ss>` ids, and tell moments drift from run to run. Lookup now takes the same tag nearest in time (within 1 s). Without it, every Venn fight round failed with "no frame pair".

- **r6b, F39#6, worse on pre-check, held OFF, item PARKED:** the `tidewake_scope` settle leaves Ripplet and Aquaryn standing and Riptusk floating upright at the faint-end moment (`qj/r6b/`). This was round 2 on the item.

- **r20, F39#20, no visible change, not judged:** hiding gather nodes left the frames identical. The judges' "small blue creature-like figure" is the `great_candy` world pickup (blue figure plus highlight ring), 9 m from Venn's fight centre, and it is not a harvest node. The arm now also covers pickups (`fight_ring_hide.pickups`, `item_cache_pickup.gd set_fight_hidden`). Re-queued as r20b.
- **F39#4:** the new `shiny_cue.overlay` (a pale-gold rim overlay on shiny bodies, OFF) is queued as r4.

- **r4 / r4b, F39#4, flat, held OFF, item PARKED:** in r4 the default `shiny_cue.overlay` was too faint to read at the stand on pre-check, so it was not judged. In r4b (energy 1.6, power 1.5, fill 0.2) A and B scored equal for all three judges (`qj/r4b/`). The judges' lever is the shiny repaint itself: Aquaryn's whole-body violet should become a hue shift on secondary regions (shell, bands, plates) over the species pattern. That is a texture repaint, beyond a scene flag.
- **r20b, F39#20: shipped ON (see table).**

- **r2, F39#2, worse (6.41 -> 5.73), held OFF, item PARKED:** a larger Meshy Veilfall (`hero_landmarks_1101.veilfall` on, 1150 m across, less fog, whiter falls). All three judges read its falls as flat, hard-edged white slabs with pasted green patches, which is worse than the shipping grey crag. This is the second failed round on this arm (VIS-TIDEWAKE r2a was flat). The judges' fix is new art: a tiered, tree-dressed Veilfall with soft, misty falls.

- **r16, F39#16, no visible change, not judged:** the arm edited the current's `restored` state, but the stands show the `live` state, so the long seams were untouched (mean pixel difference 4). r16b targets `current_flow.state_shader.live` (seams 0.3 -> 0.1, more caps and flecks) and the seam wander and gaps.

- **r15, F39#15, no visible change, not judged:** `rest_shoal_dressing_vary` (OFF) varies each shoal's dressing, but at the three route stands the props are too small to change the read (mean diff 4.6–6.8, mostly water motion). The judges' "near-identical tan discs with white rims" are the shoal terrain and its shore-foam ring. That needs per-shoal terrain lobes or a foam-ring change, and the shoals' recovery safety is tied to their heightfield. Round 1 of 2; next idea: per-shoal shape lobes (`shape.major/minor_extension_m`, bearing) with the safe radius checked by test.
- **F39#3 (named destinations):** the scene lever already ships (`destination_landmarks` + s3–s5, GPU TW1 5.35 -> 6.68). The remaining asks are new art or per-landmark dressing: scale the jetty derrick, cliff-and-falls far islands. Not attempted.

## Queue

`runbook/chain.sh` (resumable): import, then r6, r27, r14, r19, r7. F39#1/#2 wait for VIS-TIDEWAKE's r2a verdict; F39#4 waits for its shiny round; F39#20 is designed from the r19 base fight frames.

## Blockers

- **New-art assignment (coordinator 16:18: Blender work on F39#3 and F39#2) is on hold for the owner.** (1) Installing portable Blender 4.2 (downloading and running an external binary) was denied by this session's permission policy. (2) CLAUDE.md says "Claude lanes may do scene-level art from installed asset families; new meshes and Meshy work stay with Codex (owner, 2026-09-27)", and no newer owner line clearly lifts that for Claude lanes. I have not worked around either. Both need an owner decision: allow the Blender install, and confirm Claude lanes may author new meshes, or route F39#3/F39#2 art to a Codex lane.

- **F39#21 (victory hierarchy, `hud.json` `victory_focus`, OFF, unjudged): cannot be captured on CPU.** Its stands (`venn_resolve__win`/`aftermath`, `nerissa_resolve__win`) exist only in `phase2_capture_tidewake_fights.gd --verified-victory-lifecycle` runs. That mode refuses `--render-only-saves` and needs a native 1080p window, so two full trainer fights must render continuously on llvmpipe. job.json's repro also omits the flag, so r21 (ordinary render-only runs: 29 frames, fight resolved at 99 s) wrote no win frames. Better judged on the GPU queue.

- First `--import` on this container takes about 2 h on CPU.

**5 Nov ~00:55 UTC rounds (no judging, pixel pre-check only):**
- r5g, F41#5 (Stormwood grass, bush and far-cover tints desaturated, `stormwood_ground_finish`): almost no visible change (mean diff 1.6-2.9). The teal ground is the terrain texture, not these tints. Not judged, stays OFF. Handed back to VIS-STORMWOOD (coordinator, 00:15).
- r2f, F39#2 (`water_veilfall.silhouette.far_relief` ON): no visible change. In the P2-010 frames the spire is the near rock composition, inside the 1100 m far handoff, so far-only relief never draws. Not judged, stays OFF.
- Harness note: do not wrap `quick_judge.py run` in `flock godot.lock`. The tool takes that lock itself, so the run deadlocks with no Godot process (2 h lost).
