# UIPOSES lane (UI + creature/trainer pose rows) — READY

## Final summary before the 18:00 UTC cutoff (1 Nov 2026, written ~16:40 UTC)

- **Head:** `2a151563cdd5f179eeb00200765bb134d810a01c` on `tb/vis-ui-poses`. It merges cleanly with origin/main and with tb/vis-creatures, tb/craft-r3, tb/vis-meadows, tb/vis-storm-cams, tb/vis-water-sky and tb/world-craft-icons (checked with `git merge-tree`).
- **Seven flags, all OFF on the branch, listed in `MANIFEST.json`:**
  - `readout_side_enabled`
  - `catch_card` (with `calm_seal`)
  - `lane_role_flags.uiposes_riptusk_side_faint_prone_rest`
  - `victory_focus`
  - `hang_pose.body`
  - `satchel_focus`
- **Items covered:** P2-001, P2-028, P2-029, P2-058, P2-061, P2-103, P2-111, P2-114, P2-117, P2-119.
- **Criteria closed: zero.** These are game changes awaiting GPU verdicts. No CPU scores are claimed.
- **Shared-file touches:** small, flag-gated hunks in `playground_hud.gd`, `combat_hud.gd`, `capture_reticle.gd`, `tab_backpack.gd`, `trainer_model.gd`, `orb.gd`, `creature_pose_candidates.gd` and `trainer_reward_delivery.gd`. Config is only new keys: hud.json `victory_focus`/`catch_card`, menu.json `satchel_focus`, `fly_traversal.json` `hang_pose.body`, `capture_readout_visual.json` side keys, and `f36_pose_candidates.json` `lane_role_flags` at the end of the file.
- **After the cutoff:** available for one fix round on returned items.

Branch `tb/vis-ui-poses`. Coordinator update (1 Nov): no single-candidate READY lines; every candidate is listed in `MANIFEST.json` for the 18:00 UTC batch (tb/vis-batch1, all flags ON). Each flag is OFF on this branch and only touches its own keys.

## Group 9: P2-004 exploration HUD, pad path (6.45 to 6.75)

- **Flag:** `hud.json:quiet_empty_slots.enabled`.
- **Change:** on the pad, an unassigned quick slot keeps its binding glyph, so all five bindings stay visible (hard rule). The glyph is drawn at 28 px and 0.4 alpha, so only assigned slots read bright. This is the judges' "replace the placeholder white hotbar glyphs".
- **CPU Meadows pad HUD:** the three empty slots show small muted d-pad glyphs; the two filled slots are unchanged.
- **Smoke:** `smoke_hud_presentation_lifecycle` PASS (70 checks).

## Group 8: P2-071 surface swimming trainer (5.20)

- **Flag:** `human_swim_visual.json:uiposes_stroke_candidates`.
- **Change:** applies the Tidewake lane's never-judged close-1024 `swim_candidate` and `swim_stroke_candidate` swim-pose keys on their own:
  - chest 0.14 m under the surface;
  - an 84° flat body with the head lifted to breathe;
  - a forward crawl reach under the surface.

  The rest of the Tidewake look profile's unjudged sections stay off.
- **CPU Tidewake swim frames** (entry, surface_west, surface_mid): the trainer lies flat and half-submerged, legs trailing under the surface, instead of upright with arms raised.
- **Fix during the work:** a variable clash in `trainer_model.gd` was caught by the test before any push.

## Group 7: P2-048 Cloudreach map region label (5.87)

- **Flag:** `menu.json:map_region_header.enabled`.
- **Change:** a "You are here: <region>" line under the realm title on the map tab, in the warm accent. It wraps instead of truncating, and reads the map state's own current region (`tab_map.gd here_text`). This addresses the old cut-off-after-LOWER defect and the newer "no region label at all on a fogged map" note.
- **Checks:** unit test only. A Cloudreach UI CPU boot was not run, for time and disk.

## Group 6: P2-065 beaten trainer bearing (6.12)

- **Flag:** `npc_post_stances.json:beaten_trainer_stance.enabled`.
- **Change:** once a beaten trainer's defeat reaction hands off to the stand-down, they keep a bowed head and rounded back (+X on Spine/neck/Head, measured in an isolated grunt render).
- **CPU Meadows grunt fight:** the after-frames show the grunt hunched rather than upright, but small in frame.

## Group 5: P2-069 flight landing (5.88, catalogued in all four biomes)

- **Flag:** `fly_traversal.json` `landing_presentation.wing_fold_enabled`, plus Galecrest's `landing_fold_offsets`.
- **Change:** during the 0.85 s landing presentation, Galecrest's wings fold along its body, blended in with the settle.
  - Only the landing visual changes, and it hides when the presentation ends.
  - Galecrest's idle everywhere else is unchanged; it is on the owner's style bar.
- **Offsets:** measured in an isolated render.
- **CPU Meadows landed frame:** a compact folded silhouette beside the trainer, no longer the wings-up flight shape.

## Group 4: P2-050 villager post stances (5.88)

- **Flag:** `data/config/npc_post_stances.json:enabled`, new.
- **Stances:** Oskar folds his arms, Halda clasps her hands at the waist, and Lark (courier) holds one hand up at the satchel strap.
- **How it works:** `scripts/characters/post_stance.gd` is a `SkeletonModifier3D` that layers bone offsets over the playing idle, so breathing still shows. `village_npcs.gd` attaches it only to the named posts.
- **Bone signs:** measured on the rig in an isolated render. Hands-on-hips was tried and dropped: the forearms flared out on this rig.
- **CPU dialogue frames:** Oskar and Halda both read as their stance, with no clipping. Lark was not captured.

## Group 3: P2-108 Aquaryn mounted swim (4.97)

- **Flag:** `data/config/water_mount_presentation.json:enabled`, new file.
- **When on, the mounted Aquaryn:**
  - sits 0.9 m deeper while swimming. Its 5 m body had about 4 m above the surface; the seated rider stays at least 0.2 m above sea level, which the test checks at the deepest bob;
  - bobs ±0.12 m over 1.8 s;
  - stops casting mesh shadows, and its blob contact shadow is hidden. Both are restored exactly on leaving the water.
- **Code:** `water_mount_presentation.gd`, called from `water_mounted_swim.gd`.
- **CPU capture (first pass):** the deeper sit and the swim pose read. The seabed blob was still visible, so the blob is now hidden too.
- **Not mine:** frame 05 shows the existing ally camera fade turning the mount see-through.

## Group 2 (rolling batches, coordinator 1 Nov): P2-095 / P2-096 craft round 4

- **Built on:** tb/world-craft-icons, merged into this branch.
- **Flags:** `craft_presentation.json` `readable_r3` + `rendered_item_icons` + `readable_r4`. All three must be ON; `readable_r4` is new.
- **Judges' asks after 7.36, and what each became:**
  - Controller face-button glyphs in a footer: a footer bar with the Craft and Leave pad prompts.
  - 5+ visible rows: 92 px compact rows, 6 visible, one cost line each.
  - Higher-contrast Missing tags: filled Ready/Missing chips (SUCCESS/DANGER fill, dark text).
  - Higher-contrast button: the Missing materials button sits on a deep fill with a DANGER border and a light-orange label.
- **CPU pad capture:** all four changes visible; no clipping. The sixth row's cost line ends in an ellipsis; the full list stays in the detail column.
- **Test:** `tests/test_uiposes_craft_r4.gd`. `test_craft_rendered_icons` and the craft tests pass.

## Candidates in the batch (CPU sanity capture done for each unless noted; no CPU scores claimed)

| Flag (default OFF) | Items | What changes | CPU check |
|---|---|---|---|
| `data/config/capture_readout_visual.json:readout_side_enabled` | P2-058, P2-114, P2-117 | Catch percentage + caption sit beside the ring on the existing plate (flips left near the edge), number +6 px; the target body is clear | Meadows + Tidewake catch: readout beside ring, no clipping |
| `data/config/hud.json:catch_card.enabled` (existing, never GPU-judged; tuned) | P2-061, P2-117 | One framed outcome card (52 px headline + traits); on success the fight cards, action bar and roster step back **on the card's first frame** (they stayed up for the verdict frame before) | Meadows + Tidewake 08/09: one card, HUD cleared |
| `data/creatures/f36_pose_candidates.json:lane_role_flags.uiposes_riptusk_side_faint_prone_rest.enabled` | P2-028, P2-029 | Riptusk (land + Water): faint rolls onto its side with head dropped (posed-vertex grounded); new prone rest (legs folded, head low, no roll) replaces the belly-up roll | Tidewake creatures: faint reads as down, rest as settled |
| `data/config/hud.json:victory_focus.enabled` | P2-103, P2-111 | While a Moment banner is up, quickbar/legend/roster/creature card/prompt step back; named-trainer acknowledgements become the victory Moment receipt instead of the quickbar message strip | Unit + HUD lifecycle smoke only (fight captures too long on CPU) |
| `data/config/menu.json:satchel_focus.enabled` | P2-001 | Satchel: focused item icon on its own lit round plate, item name in the warm heading accent at 36 px, description in TEXT_PRIMARY at the 27 px reading floor | Meadows UI (pad): visible, no clipping |
| `hud.json:catch_card.calm_seal` (rides `catch_card.enabled`) | P2-061 | Sealed orb emission and halo calmed so it reads as the gold orb, not a white blob, under the result card | Meadows 09: gold orb with band visible |
| `data/config/fly_traversal.json:hang_pose.body.enabled` | P2-119 | Carried trainer's legs trail back with bent knees (one further), torso leans into flight; arms still aim at the grip | Meadows flight: no clipping, legs no longer a straight ladder hang |

Head at writing: d500bf979a2c135f1a567f60fa788282c8bcb59d. Tests: `tests/test_capture_readout_side.gd`, `test_uiposes_riptusk_pose_flag.gd`, `test_uiposes_victory_focus.gd`, `test_uiposes_fly_hang_body.gd` (all pass), plus `test_trainer_reward_delivery`, `test_human_swim_visual`, `smoke_hud_presentation_lifecycle` (pass).

## Parked / not built

- **P2-015 (Terrapup/Veridian faint):** a generic side-lie roll was built and removed: on current main their baked faint clips already lie on their side (CPU frame), and the roll stood them back up. **Pre-existing capture defect:** `phase2_capture_creatures.gd --only=terrapup --poses=resting` fails on main ("authored rest did not complete before capture"), so the GPU set is missing `meadows__terrapup__resting`.
- **Cloudreach catch (P2-117/P2-118) on CPU:** \`phase2_capture_catch.gd --biome=cloudreach\` fails "could not enter combat" (the known CR-CANDY fixture: the candy pickup wins the interact). Take the candy first, as the GPU queue notes say.
- **victory_focus (P2-103/P2-111):** the CPU Hollows capture timed out at fight t=40 s (40 min limit) before the win frame, so this flag has unit-test and HUD-smoke evidence only.
- **P2-016:** failed on GPU twice (TECHNICAL §8.1); parked until a new idea.
- **P2-004, P2-001, P2-007, P2-031:** many judged rounds already (hud_lean OFF at 6.41 < 6.71); no new idea that clears +0.5 today.
- **P2-081/082/084 (dialogue staging), P2-091 (arena crystal slab), P2-108/P2-105/P2-071 (traversal poses), P2-095/096 (craft-r3 queued):** other lanes or not UI-fixable here.
