# NEAR6-TW lane (tb/near6-tw-1104): Tidewake F39 items scored 5.4–6.0, CPU quick-judged

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

## Queue

`runbook/chain.sh` (resumable): import, then r6, r27, r14, r19, r7. F39#1/#2 wait for VIS-TIDEWAKE's r2a verdict; F39#4 waits for its shiny round; F39#20 is designed from the r19 base fight frames.

## Blockers

- **F39#21 (victory hierarchy, `hud.json` `victory_focus`, OFF, unjudged): cannot be captured on CPU.** Its stands (`venn_resolve__win`/`aftermath`, `nerissa_resolve__win`) exist only in `phase2_capture_tidewake_fights.gd --verified-victory-lifecycle` runs. That mode refuses `--render-only-saves` and needs a native 1080p window, so two full trainer fights must render continuously on llvmpipe. job.json's repro also omits the flag, so r21 (ordinary render-only runs: 29 frames, fight resolved at 99 s) wrote no win frames. Better judged on the GPU queue.

- First `--import` on this container takes about 2 h on CPU.
