# CREATURES-RALPH: running status

## VISUAL LANE (new session, 3 Nov ~00:45 UTC): setup done, batch plan and ETA for the 89 items

**Setup (measured):** fresh disk allowance (about 13 GB free). Godot 4.7-stable at `/usr/local/bin/godot`; the **full** headless import of the whole project is running (no `.gdignore` trimming), so biome, landmark, HUD and fight items can now be captured here. Portable **Blender 4.2.3 LTS** runs from scratch (`blender --version` OK), so new meshes are built here; no Meshy, no GPU.

**Yardstick:** every score below is CPU Low/Compatibility, tools/visual_judge (JUDGE_PROMPT, `anchor_tiles.py --pairs 3`, three code-blind judges, `calibrate.py`), baseline (current branch = main + PR #803 content) and candidate in the same run. Done = mapped Bar A ≥ 6.0 CPU, recorded as "CPU <base> -> <cand>".

**Batch U (the 12 unscored, one capture set per biome; one Godot at a time):**
| Set | Tool (TECHNICAL §8.1 form) | Covers | ETA (UTC) |
|---|---|---|---|
| U1 Meadows | `capture_f38_matrix.gd --f38-preset=Low --f38-baseline --times=day,night --subset=<6 sites>` | F38#0, F38#41 (+ re-score F38#24 mountains, #22 mill, #23 relay yard, #20 stronghold, #30 Warrens) | 03:30 |
| U2 Tidewake | `capture_tidewake_f13_5.gd --camera-set=F39-look.json --preset=Low` + `phase2_capture_tidewake_fights.gd --trainer=water_trainer_venn` | F39#30, F39#32, F39#21 (victory panel) (+ F39#31 Veilfall, F13#5, F39#1/#2/#15) | 05:30 |
| U3 Cloudreach | `capture_cloudreach_f40_matrix.gd --piece=N` (day/night/weather pieces of 3 stands, `--ground-cover-cache`) + `phase2_capture_catch.gd --biome=cloudreach` (candy taken first) | F40#0, F40#19, F40#21, F40#18 (+ F40#1/#2/#4/#11) | 08:00 |
| U4 Stormwood | `capture_stormwood_f10_matrix.gd --phases=calm,break` + `capture_named_fights_f10_6.gd` | F41#22, F41#24 (+ F41#1 Stormheart, #5, #17, #10) | 09:30 |
| U5 Named fights | `capture_named_fight.gd` Warden and Riverwatch; Venn/Stormwood reused from U2/U4 | F22#4 (visual half; C2/C3 smokes are hours each, reuse the recorded 6/6, 22/24, 15/18, 48/54 and rerun only Riverwatch) | 10:30 |

Judging runs in parallel with the next capture (judges are agents, not Godot). Unscored items get their own score as each set lands.

**Then worst first (fix batches):** F39#31 Veilfall 3.35, F13#5 3.61, F41#18 uniforms 3.91 (material/rank markers, scene-level), F41#8 named silhouettes 4.03 (Blender outfit variants on installed cast), F41#1 Stormheart 4.41, F38#24 mountains 4.42 (Blender continuous ridge backdrop), F39#12 bed and F39#13 workbench (Meshy props from 31 Oct are already ON; re-baseline first, the old scores may predate them). New Blender meshes keep a drafted reference, a 1.80 m trainer scale check and provenance, flag-OFF until judged.

**Progress (3 Nov ~01:00 UTC):**
- **Landed on this branch (ready for the coordinator):**
  - `a3825550` **F41#13**: `creatures_ralph_stormraven_charge` ON, Stormraven **CPU 5.26 -> 6.72** (r25, three judges, calibrated); test `test_remake_owner1101_finish.gd` JUDGED_ON entry "6.72", 5 tests / 347 assertions pass. Fulgocobra stays OFF (5.83 -> 5.92, flat), so F41#13 is half met: Fulgocobra needs a vein mask on its gold bands.
  - `d98884fc` **F39#12 arm (OFF)**: a Blender-built raised woven nest bed (`meshy_camp_props.json bed.nest_candidate`), answering the GPU WD2 judges' "reads as a fire pit; path: a raised nest or cushion with bedding". Provenance, drafted reference and 1.80 m scale check in `assets/props/vl-1103/nest_bed/`.
  - `355cc9d0` import UID normalisation for 58 remake textures (no references to the old UIDs).
- **Found:** 53 flag-OFF arms in `data/config` cite P2 items on this list and were waiting on a GPU that is now off. They cover 45 items. Each biome is captured twice in one CPU run (baseline, then the same launches with that biome's arms ON as a temporary overlay, reverted after), and each item is judged A/B on its own frames. The launch list comes from `VISUAL/item-scores/job.json` (each frame's repro command, `--subset`s merged per boot).
- **Running now:** Stormwood baseline (10 boots, 16 items incl. F41#18 and F41#8), then Stormwood candidate (rim, role accessories, dialogue lens, fight fade, Crown Arch, Glass Sink x2, road puddles, harvest round 2, candy tiers). Tidewake (14 boots, 23 items, 12 arms incl. Veilfall x2, the nest, victory focus) is queued behind it. ETA: Stormwood scores ~06:00, Tidewake ~10:00 UTC; Meadows and Cloudreach follow.
- **Stand note (F41#1):** the Stormheart `approach` stand renders from inside the hollow trunk (wooden ceiling, banners), which is why the item reads as "a dark ring". It is a stand defect rather than the tree; I record it in the verdict and do not move the camera to change a score.

**Queue update (3 Nov ~01:45 UTC, one Godot at a time, flock-serialised):** Stormwood items (running) → Tidewake items (import first; arms incl. the nest and the new workbench `a1defe43`) → Tidewake look (`capture_tidewake_f13_5.gd`, F39-look 11 views + T2-current 4 views, base and Veilfall/current/shore arms: F39#30, F39#31, F39#32, F13#5) → **unscored set** (Meadows `capture_f38_matrix` 4 sites day for F38#0/#41; Cloudreach `capture_cloudreach_f40_matrix` pieces 3/51/83/91 for F40#0/#19/#21; `capture_stormwood_f10_matrix` calm+break for F41#22/#24; Riverwatch named fight for F22#4; Stormwood fights base/candidate for F41#3/#16/#21) → Meadows items → Cloudreach items. The matrix rows asking for ≥200 frames get a CPU subset score, stated as a subset; a full 200-frame CPU recapture takes about 40 h for Cloudreach alone.
- New OFF arm `a1defe43` **F39#13**: a Blender-built 2.6 m plank workbench with a 2.15 m tool board (hammer, saw, tongs, rope coil), vise and lantern post (`meshy_camp_props.json workbench.vl_candidate`); provenance and scale check in `assets/props/vl-1103/camp_workbench/`.
- New OFF arm `11a1916d` **F41#13 Fulgocobra**: gold-band charge emission (`creatures_ralph_fulgocobra_goldvein`), to be captured with `capture_f36_poses.gd`.

**URGENT for the coordinator (4 Nov ~07:40 UTC): batch-6 rim ERROR fix is `fe9d2120` on tb/creatures-ralph** (`scripts/world/creature_rim.gd` + `tests/test_creature_rim.gd` only; send_message to your session is refused, so this is the channel).
- Reproduced here with the rim ON: `smoke_net_f48_cut_key` failed "pre-restart guest log has no ERROR:" (32x `Parameter "material" is null`); `smoke_backpack_equipment` (the Stormwood shard step) logged 94 of them, 0 with the rim OFF.
- Your keep-alive hypothesis (a) did not hold: a never-freed static material still gave 88. The errors fire when the world is freed while a creature body's meshes still wear the overlay.
- Fix: `dress_body()` connects `tree_exiting -> undress(body)` and `tree_entered -> dress_body(body)`, so a body sheds the rim before teardown and is re-dressed if it returns while the rim is on. `creature_body.gd` is untouched.
- Verified: backpack smoke 0 ERRORs (26/26); `test_creature_rim` 4 tests / 29 assertions, 0 failed (new exit/re-entry test). Net f48_cut_key, f18_fixture_teaching and f20_ending plus the overlay tests are running here; results will be appended below.

**v1/b24 (4 Nov ~00:05 UTC 5 Nov): Cindercub value lift (6.52 -> 7.38) and the existing Voltarach/Brooktail dark lift (Voltarach 5.28 -> 6.04, Brooktail 6.18 -> 6.28) ship ON.**
- **Flags:** `creatures_ralph_cindercub_value_lift`, plus `remake_owner1101_dark_lift` (CAUSE-REMAKES, 1 Nov, never judged until this round).
- **Tests:** `test_remake_owner1101_finish` moves `remake_owner1101_dark_lift` from its held-OFF list into `JUDGED_ON`; `test_dark_value_lift_flags` adds Cindercub.
- **Tally:** value lifts on dark creatures at the stage camera are now eight for eight.

**v1/b23 (4 Nov ~23:05 UTC): stage value lifts ship ON for Tuskroot (6.57 -> 7.16), Thundertunnel (5.64 -> 5.78) and Stormbrush (6.31 -> 6.42).** Three flags `creatures_ralph_{tuskroot,thundertunnel,stormbrush}_value_lift`, judged in one batch (calibrate r 0.92); Ashtusk shares Tuskroot's coat. Test: `tests/test_dark_value_lift_flags.gd`. The value lift is now five for five on dark creatures at the stage camera.

**v1/b22 (4 Nov ~21:50 UTC): Nightburrow value lift ships ON.** F36#56 CPU 6.01 -> 7.06 (+1.05; raw 5.8/6.1/5.8 -> 6.5/6.6/6.6; r 0.99). `creature_coat_flags.json` `creatures_ralph_nightburrow_value_lift` lifts the live partial-plates albedo (midtone gamma 0.78, saturation x1.12) and keeps its glow map. `test_nightburrow_partial_plates_flag` is updated for the lift (no assertion dropped: plates still resolve with the lift OFF). The value lift is now two for two on dark creatures at the stage camera (Mosshock +0.92, Nightburrow +1.05). It was flat at the field camera (Terrapup), where the creature is too small.

**qj terralift-f38-1 (4 Nov ~21:00 UTC): Terrapup value lift is flat on F38#1 and stays OFF.** All three judges scored both sides the same (raw 6.0/5.4/6.0); at the field camera the fainted Terrapup is too small for an albedo lift to register. Judges' F38#1 lever is now contact shadows and settling the bodies into the grass (a ground-contact pass), not coat value. `creatures_ralph_terrapup_value_lift` stays OFF.

**v1/b21 (4 Nov ~20:10 UTC): Mosshock value lift ships ON.** F36#54 CPU 5.63 -> 6.55 (+0.92; raw 5.4/5.6/5.3 -> 6.0/6.1/5.9; defect PRESENT -> PARTIAL; r 0.91). `creature_coat_flags.json` `creatures_ralph_mosshock_value_lift` is a value-lifted albedo (midtone gamma 0.78, saturation x1.12); only the albedo changes, since the `remake_owner1101_glow_read` coat is OFF. Test: `tests/test_mosshock_value_lift_flag.gd`. Mosshock is now above 6.0.

**qj verheaddown-f38-1 (4 Nov ~19:30 UTC): Veridian faint head-down ships ON.**
- **Result:** F38#1 creature collapse and rest, CPU 6.21 -> 6.30 (+0.09; raw 5.7/5.8/5.9 -> 5.8/5.9/5.9; no judge lower; calibrate r 0.93).
- **Base vs flag:** the base rose from 5.91 because of the capture fix that lets fainted stills finish their clip, not this flag. F38#1 is now above 6.0.
- **What it is:** flag `creatures_ralph_veridian_faint_headdown`, a copy of the live nat1024 GLB with its faint clip's neck tipped 40 deg and head 30 deg toward the body (`lateral_recoil.py`).
- **Tests:** new `tests/test_veridian_faint_headdown_flag.gd`; the flag is out of HELD.
- **Judges' remaining asks:** a contact shadow and value lift for the dark Terrapup on dark grass, and a more limp, settled Veridian.

**F38#1 follow-up (4 Nov ~19:05 UTC): the splayed Veridian is its faint end pose; the rest arm is not measurable on F38#1, so it stays OFF.**
- **Which frame:** F38#1's catalogue frames are Terrapup fainted, Terrapup resting and Veridian FAINTED. The "semi-upright, splayed" Veridian the judges flag is its faint, not its rest.
- **Rest arm:** `creatures_visual.json` `rest_faint_settled` (OFF, `test_rest_faint_settled`) starts a faint-clip rest at the clip's settled end. It is correct game-side, but it touches none of F38#1's judged frames (Terrapup rests via the roll path), so its A/B round was identical and not judged. It stays OFF for a future rest item.
- **Capture fix:** "fainted" stills now wait, in game time, for the faint clip to finish (commit "fainted stills wait for the faint clip to finish"; TECHNICAL 8.1).
- **Veridian's faint still reads as a leap:** with the full clip played, its END pose is side-lying with legs straight out and antlers up. F38#1's remaining lever is new faint art for Veridian (or a faint-clip pose edit), not a capture or scene change.

**qj rim075-f38-1 (4 Nov ~18:40 UTC): F38#1 re-based at CPU 5.91 on the fixed capture; creature rim at 0.75 is flat, so 1.0 stays.**
- **Re-base:** raw 5.8/5.6/5.6 on both sides; defect PARTIAL.
- **What the frames show now:** Terrapup's fainted and resting frames lie down (the resting frame was missing before), and Veridian's faint lies flat.
- **Judges' remaining defects:** the fainted Terrapup is a dark smudge against dark grass, and Veridian at the resting moment still reads semi-upright or splayed.
- **Next levers (creatures, per the coordinator's new scope):** a value lift for dark coats in the Meadows, and Veridian's rest pose. NEAR6-MS now owns the UI rows, including F38#19.

**qj shinyplates2-f39-4 (4 Nov ~18:00 UTC): shiny remake textures ship ON.**
- **Result:** F39#4 shiny creature finish, CPU 5.61 -> 6.76 (+1.15; raw 5.4/5.6/5.6 -> 6.3/6.3/6.4; defect PRESENT -> PARTIAL; calibrate r 0.98). All three judges say the violet-magenta whole-body tint is gone and the shell and plate pattern survives.
- **Cause:** the Tidewake remakes had no shiny texture of their own, so the shiny swap fell back to the OLD mesh's extracted shiny (different UVs) and wired it into emission as well. On top of that, the shiny surface finish hue-rotated the whole body.
- **What changed:**
  - `creatures_visual.json` `shiny_remake_textures` maps each live remake albedo to its own repaint (`tools/art_pipeline/shiny_secondary_shift.py`: only the warm secondary band moves, to gold on Aquaryn's fins and jade on Cannonback's and Riptusk's plates).
  - Each glow map maps to itself.
  - A four-line hook in `creature_body._texture_for` reads the map.
  - `creature_surface_finish.apply` stands down for a shiny already wearing one of these repaints.
- **Tests:** `test_shiny_remake_textures` (5/48); `test_shiny`, `test_phase2_shiny_finish`, `test_realm_look_overlay` and texture policy pass.
- **Judges' next lever:** shiny as an accent over each species' own albedo, and keep Aquaryn's pale cyan apart from the water.

**qj headdown-f39-6 (4 Nov ~16:50 UTC): Aquaryn faint head-down ships ON.**
- **Result:** F39#6 creature faint state, CPU 6.05 -> 6.24 (+0.19; raw 5.6/6.2/5.4 -> 5.6/6.6/5.5; calibrate r 0.86). Two judges see Aquaryn lie lower and more horizontal; one ties.
- **What it is:** flag `creatures_ralph_aquaryn_faint_headdown`, a copy of the live r9 GLB with its faint clip's neck tipped down 35 deg and head 25 deg (`lateral_recoil.py --spec=neck:x:35,head:x:25 --peak=0.5 --release=1.0`). Same textures and clips.
- **Tests:** new `tests/test_aquaryn_faint_headdown_flag.gd`.
- **`test_creature_model_flags` change:** `test_every_owner_remake_ships_on_and_is_the_live_model` now checks each species against its LAST enabled flag (flags merge in order). A later flag must be a variant from the same remake folder. Before, it compared every flag, which fails as soon as one ON arm refines an ON remake. No assertion was dropped.

**qj settle-f39-6 (4 Nov ~16:10 UTC): F39#6 re-based on the fixed capture, and NEAR6-TW's settle arm stays OFF (worse).**
- **Re-base:** F39#6 creature faint state is CPU 5.86 on real faint frames (was 5.29 on the old capture). That +0.57 is a measurement fix (the capture tool now waits for the model before `play_faint`), not a game change.
- **Base frames:** Ripplet and Riptusk lie on their sides; all three judges call the defect PARTIAL.
- **Candidate:** `creature_pose_settle.tidewake_scope` 5.86 -> 5.11; it stands Ripplet up and floats Riptusk. Its third failure on this item, so it stays OFF.
- **Remaining defect:** only Aquaryn still holds its head and chest up at faint end. Its own faint clip is the next lever.
- **Also:** the F38#19 HUD frame now waits past the opening fade (`job.json`); the settled frame shows the real exploration HUD, including the "Get up" prompt and action legend. Every earlier F38#19 score was on a dimmed frame. A legend-fade candidate would change onboarding hints, which is a design call, so it is parked.

**Coordinator, batch 16 `smoke_stormwood_spawn_slicing` (4 Nov ~15:05 UTC): not the lateral hit arm.** I ran the smoke locally on this branch, alternating the arm ON and OFF; worst main-thread gap per run:
- **ON:** 7691 (the first Stormwood boot after a long Meadows capture, a cold cache), then 1730, 1884 and 1789 ms.
- **OFF:** 1861 and 1682 ms.
- **Read:** warm runs sit at about 1.7-1.9 s whichever way the flag is set, so the 2000 ms limit has under 0.3 s of headroom on its own. The arm only swaps Burrowback/Nightburrow's model (the same mesh, imported .scn and extracted textures), and the band spawn tables place those species in the Meadows bands. Your 2006 ms reads as that existing thin margin, not a load-time cost.
- **No warm/cache change made.**

**v1/b20 (4 Nov ~15:00 UTC): Mosshock and Sparkit lateral hit arms are worse and stay OFF (in HELD).** F36#54 5.95 -> 5.79; F36#70 6.20 -> 5.75. Sparkit maps at 6.20 as shipped. Mosshock needs new art: its face and elemental trait do not read at stage distance, and its faint is a "rock-like lump". Verdict in `v1/b20/`.

**qj lathit4-f38-2 (4 Nov ~14:00 UTC): Burrowback/Nightburrow lateral hit ships ON.**
- **Result:** F38#2 creature hurt and movement poses, CPU 6.18 -> 6.40 (+0.22; raw 6.1/5.8/5.6 -> 6.4/6.0/5.6; defect PRESENT -> PARTIAL for two of three judges; calibration r 0.95).
- **What it is:** flag `creatures_ralph_burrowback_lateral_hit`, a copy of the live nat1024 GLB.
  - Its hit clip gets a sideways lean and head toss (`tools/art_pipeline/lateral_recoil.py`: spine 24, neck yaw 38, head roll 24).
  - Its peak is then held to the clip end (`hold_clip.py`, as shipped for Terrapup).
  - The copy uses the live extracted textures, so the Nightburrow repaint and coat flags still resolve.
- **Test:** `tests/test_burrowback_lateral_hit_flag.gd`.
- **Harness fix found on the way (commit "Creature pose capture: wait for the art model"):** `phase2_capture_creatures.gd` posed creatures before their model existed, so "hurt", "fainted" and "resting" stills were idle. The base rise (5.81 -> 6.18) comes from that fix, not from a game change.
- **F38#1 needs a fresh base on the fixed tool.** Its "fainted bodies upright or floating" defect is likely the same capture bug. The stills also land after a 0.54 s hit under CPU frame deltas; recorded in TECHNICAL 8.1.

**Coordinator, rim fix verification and the batch-8 f20 question (4 Nov ~09:50 UTC):** all of these ran locally on `fe9d2120`, which is the same creature-rim code as tb/land-batch-9.
- With the rim ON, every one passed and none logged a `Parameter "material" is null` error:
  - `smoke_net_f48_cut_key`
  - `smoke_net_f18_fixture_teaching`
  - `smoke_net_f20_ending`
  - `smoke_backpack_equipment` (26/26)
  - `smoke_vfx_lifecycle` (9/9)
  - `test_creature_rim` (4/29)
  - `test_combat_vfx`, `test_tell_aura_overlap`, `test_meadows_cause_flags` and texture policy
- **f20 with the rim OFF:** `smoke_net_f20_ending` also passes (rc 0).
- **Grandpa failure looks intermittent, not the rim.** f20 passes both ways here, so the batch-8 "natural Grandpa completion receives durable personal acknowledgement" failure looks intermittent. That check is a 30 s wait for `homecoming_seen` after the dialogue, and nothing in it touches creature materials.
- **Re-dress doesn't pile up.** `dress_body` connects `tree_exiting`/`tree_entered` once per body: the `is_connected` guard is keyed on the bound callable.
- **Harness note:** `tools/net/run_net_smoke.sh` leaves a `tail -f <run>/SUMMARY.md` running. Under an outer `flock`, that tail inherits the lock and blocks the next run, which cost 78 min here. Kill it after each run.

**qj rim10-f38-1-2 (4 Nov ~06:30 UTC): stronger creature rim ships ON.** `creature_rim.json` enabled, energy 0.55 -> 1.0, power 2.6 -> 1.8 (Meadows looks only). F38#1 collapse and rest CPU 5.53 -> 5.84 (+0.31; all three judges scored the rimmed side higher and named the outline separating the body from the grass); F38#2 hurt and movement 5.84 -> 5.81 (flat). This round's anchor fit is weak (r 0.65, RMSE 0.64), but the raw scores agree (5.5/5.7/5.5 -> 5.8/5.9/5.9). One frame is missing (Terrapup resting). `test_creature_rim.gd` now asserts ON with "5.84"; creature rim, Meadows cause flags, combat VFX, tell-aura overlap, VFX lifecycle smoke and texture policy all pass. The judges' next lever for F38#1/#2 is new art: distinct hurt/move keys and side-down faint and rest poses that settle on the ground.

**qj rimr2-f41-18 (4 Nov ~05:10 UTC): Stormwood rim r2 is flat-to-worse and stays OFF.** F41#18 CPU 5.10 (r1 as shipped) -> 4.98 with r2 (energy 1.15, power 1.7); raw 5.5/6/5.7 vs 5.5/5.8/5.7, defect PARTIAL on both. All three judges say the uniform now separates from the ground but has no rank or individual markers at this camera distance, so more rim light does not help. The next lever is an insignia or bright accent on the uniform (scene or new art); report in `qj/rimr2-f41-18/VERDICT.md`.

**v1/b19 (4 Nov ~04:45 UTC): the retuned storm-light set still gains and stays ON (live on main).** F41#5 5.04 -> 5.63; F41#2 5.39 -> 5.46; F41#19 5.42 -> 5.46. Base was captured with the set OFF, same run. The CI retune cost most of the F41#2 phase lift (b16 +0.74). The next lever is a per-phase grade inside the phase rules, which is for the Stormwood region lane.

**LANDING-READY (4 Nov ~04:30 UTC): F36#56 Nightburrow partial plates ON, CPU 6.37 -> 6.67 (v1/b18; three judges, slope 1.51, r 0.96, RMSE 0.40).** `creature_coat_flags.json` `creatures_ralph_nightburrow_partial_plates`: plates kept only on the spine and shoulders, the rest repainted as the coat's fur, moss and its glow removed. Texture only, anatomy-masked by `tools/art_pipeline/nightburrow_partial_plates.py`. Tests: `test_nightburrow_partial_plates_flag.gd` (asserts ON, "6.67", resolves ON to the arm and OFF to the shipped coat) 2/32; `test_creature_coat_flags.gd` 6/627. The creature rim (F38#1/#2/#26) is flat at the world camera (5.46 / 5.96 / 6.06 -> 6.11) and stays OFF.

**LANDING-READY (4 Nov ~04:20 UTC): Terrapup hold-peak hit react, F38#2 (stage) CPU 6.37 -> 6.79 (v1/b15).** The live `creature_terrapup_owner1101.glb` hit clip now holds its peak recoil to the clip end (`tools/art_pipeline/hold_clip.py`), so the hurt-end frame no longer snaps back to idle. The score is recorded in `creature_model_flags.json` `remake_owner1101_terrapup._why`. Test: `test_remake_owner1101_finish.gd::test_terrapup_hit_holds_its_peak_with_its_score` asserts the score and that hit-end equals mid-clip; the file passes 6/353, and `test_texture_import_policy` passes 2/1591.

**v1/b17 (4 Nov ~02:45 UTC): Meadows Blender ridge F38#24 is worse, 4.19 -> 3.44, and stays OFF.** The ridge reads as a pale smeared wall right behind the meadow, while the shipped rings read as soft blue distance. The row's main blocker is in the two Warrens frames: a camera-occluding bank-shell mass and floating dark slab undersides. That is for the Meadows region lane (`tb/vis-meadows-1104`). A further, lower, darker, layered ridge r2 is the next attempt.

**FOR #808 (4 Nov ~03:15 UTC): the storm-light set is fixed. Every named test passes with it ON, so it can go back ON.** The CI suite 4 failures had two causes.
- **(1) Real phase-rule breaks in the `storm_sky_1101` overlay**, now retuned (`_why_rules`):
  - Calm had a sheet glow (Calm has no lightning), now 0.
  - Break ambient 0.72 exceeded Building 0.70, now 0.66, so Break keeps the darkest ground.
  - Storm phases had deck rims, which are reserved for the aftermath, now 0.
  - Calm contrast 0.45 is now 0.40, so the aftermath deck stays more defined.
  - Break sun 0.38 is now 0.27, so the aftermath key stays over 2.5x Break. The shipped value is 0.22.
  - Calm no longer overrides the deck colour, so it darkens and saturates Calm > Building > Break.
  - `soft_rain_1101` drops: 2000 near + 1700 far + 800 curtain = 4500, inside the Break budget.
- **(2) Tests that assumed the storm-free config:** `test_stormwood_surge_presentation.gd` `_config()` now reads the effective config (`stormwood_surge_rules.with_presentation_candidates`), the same merge the surge runs. No assertion changed.
- **Local results, all 0 failed:**
  - `test_stormwood_surge_presentation` 53 tests / 730 assertions
  - `test_stormwood_restored_sky` 2/39
  - `test_cause_stormwood_candidates` 10/68
  - `test_storm_cams_candidates` 15/54
- **Effect on the judged look:** the retune trims some of the lift that was judged (v1/b16: F41#5 5.84, F41#2 5.80), so a re-judge of the retuned set is queued.

**FOR #808 (4 Nov ~03:00 UTC): hud_lean fixed, so `smoke_objective_hint_card` passes with hud_lean ON and OFF.**
- **Cause:** lean `objective_width` 460 moved the objective block's left edge into the centre gutter. The objective hint card measures its width off that edge, so it narrowed, wrapped and ran 10 px into the bottom dock.
- **Fix, config:** lean `objective_width` returns to 348 (`hud.json` `_why_r4`). The r3 eyebrow row (46) stays.
- **Fix, test:** the plate check now reads the HUD's live eyebrow row (`_objective_eyebrow_row()`) instead of the constant.
- **Local result, `smoke_objective_hint_card`, PASS:**
  - lean ON: 28 hints fit, tallest card 281 px in band 168-533, 84 px spare; 2-line plate 176 px.
  - lean OFF: the same, with a 166 px plate.
- **To land:** take the next head and keep hud_lean ON as #808 had it.

**FOR #808 (4 Nov ~00:45 UTC): take this branch's head; it fixes two test failures that the storm-light-ON commit `43f47541` causes.** In `tests/test_cause_stormwood_candidates.gd`, `test_storm_sky_on_...` and `test_soft_rain_on_...` failed. Both build their candidate from the shipped config, which now has BOTH candidates ON, so "the sky candidate leaves rain alone" and "the rain candidate leaves phases alone" each saw the other flag applied. The fix: the helper `_surge_with` turns every candidate OFF first, then turns on only the named ones. No assertion is changed. Re-run: `test_cause_stormwood_candidates.gd` **10 tests, 68 assertions, 0 failed**.

**Owner rule, 4 Nov (via the coordinator): every judged improvement ships ON, even below 6.0. Only flat or worse stays OFF.** Applying it to this lane's held items:
- **F38#2 / Terrapup hold-peak hit react (v1/b15: stage 6.37 -> 6.79):** ships as the held-peak `creature_terrapup_owner1101.glb`. The swap waits for the in-flight rim capture to finish, so its base and candidate keep the same model. The Nightburrow hold was flat and stays OFF.
- **Already ON by the coordinator in #808:** `hud_lean` (5.30 -> 5.64) and Stormwood rim r1 (5.58 -> 5.98).
- **Next to judge:** rim r2 (Stormwood region lane), the Meadows ridge F38#24, the creature rim F38#1/#2/#26, and Nightburrow partial plates (being built).

**Scope (coordinator, 4 Nov ~00:30 UTC):** the coordinator archived all three sessions I started at 00:25. The region items belong to its `tb/vis-*-1104` lanes, and I will not start sessions without asking the coordinator first.

This lane covers creatures and poses, UI/HUD and in-flight arms:
- **Fulgocobra 6.52:** landing-ready.
- **Storm-light set:** its tests run once the Tidewake overlay reverts.
- **Rim, ridge and Tidewake recapture:** the creature rim (F38#1/#2/#26), the F38#24 ridge judging and the Tidewake recapture, whose verdicts go to the Tidewake region lane.
- **Roster rows with a judge-named fix:** F36#56 Nightburrow (partial plates), F36#70 Sparkit, F36#54 Mosshock, F39#24 Torrentoad.
- **HUD:** F38#19.

Each READY item is pushed as it passes.

**Queue fault found and fixed (3 Nov ~23:30 UTC).**
- **What happened:** the Tidewake items candidate (`tw_cand`, 22:52) failed its overlay because the camp bed and workbench were already ON. Its partial overlay was left applied. The Tidewake look capture (`twl_base`, 22:52-23:16) then ran with that overlay, so twl is discarded and will be rerun cleanly.
- **Fixes:**
  - Every overlay list now drops flags that are already ON. That covers camp props, map paint, house textiles, capture readout and the storm-light set.
  - `chain.sh` now holds a scene lock from overlay to revert.
  - `run_group.sh` base launches take the same lock, so no capture runs while another job's overlay is applied.
- **Caveat:** before the fix, the candidate overlays could overlap other jobs' base launches. The overlays only touch their own biome's configs plus HUD and catch flags, and every verdict above compares rows whose frames those flags do not reach.

**v1/b16 (3 Nov ~23:20 UTC), `43f47541`: Stormwood storm-light set ON vs a fresh base.** `stormwood_surge` storm_sky_1101 + soft_rain_1101, `stormwood_ground_finish` moss_variation_1101 + value_lift_candidate. **F41#5 4.84 -> 5.84, F41#2 5.06 -> 5.80**, F41#19 5.32 -> 5.45, F41#4 5.54 -> 5.58, F41#1 4.88 -> 4.71 (noise). **F41#17 Crown Arch is 6.45 as shipped** (6.80 with the set). Fit: slope 1.31, r 0.93, RMSE 0.31. These are floor-raising gains, and F41#5/#2 are still under 6.0. The tests now assert ON with "5.84" (`test_cause_stormwood_candidates.gd`, `test_storm_cams_candidates.gd`). Their run is queued behind the rim tests, so **do not land `43f47541` until READY records it passing.** v1/b15 hold-peak: Terrapup stage 6.37 -> 6.79 (+0.42, under 0.5) and Nightburrow flat, so the GLBs are not kept and pose work is parked.

**New OFF arm `4e606ff6` (3 Nov ~22:25 UTC): creature rim (`creature_rim.json`) for F38#1/#2/#26.** It reuses the Stormwood character rim overlay on each Meadows creature body, applied in `creature_body.gd` after every model build, so creatures built by the capture tool get it too. Tell auras, boss auras and body glows take the overlay slot from the rim and hand it back. With the flag OFF no mesh wears the rim, so those paths are unchanged. `test_creature_rim.gd` passed 3/19 in the subagent's run. Tests: `test_creature_rim` 3/19, `test_combat_vfx` 14/72, `test_enemy_pattern_telegraph` 6/6923, `test_f22_riverwatch_presentation` 3/16, `test_stormwood_strike_countdown` 5/22, `test_tell_aura_overlap` 3/12, all 0 failed. `test_storm_cams_candidates` failed only `test_water_npc_placement_ships_off`, because the Tidewake capture overlay had that flag ON in the working tree; a clean re-run is queued. The flag stays OFF until they pass and the arm is judged. Its capture (fresh base vs rim ON) is queued.

**v1/b14 (3 Nov ~22:15 UTC): pose recipe in the Meadows world frames, exact tie.** F38#1 5.35, F38#2 5.58, F38#26 5.77 on both sides (r 0.97, RMSE 0.32). The GLBs are not kept, and after two rounds without a gain (b7, b14) the recipe is parked. The next lever for these rows is creature rim light and value separation from the tree band, not more animation. F39#6 had no frames in either run.

**Stormwood baseline caveat (3 Nov ~21:20 UTC, v1/b13):** most of `sw_base` was captured 00:43-03:33 UTC, before the Blender Crown Arch and other branch changes. The resumable queue kept those launches. So b10, b11 and b13 compare candidates captured in the afternoon and evening with an early-morning base. No flag was turned ON from them. b13 (storm sky and rain, moss variation, value lift) shows +0.1 to +0.65 on F41#2/#4/#5/#19, all still under 6.0. A fresh base (`swb_base`) is queued before any decision. Clean re-run so far: `test_storm_cams_candidates.gd` **15 tests, 52 assertions, 0 failed**; `test_remake_owner1101_finish.gd` **5 tests, 347 assertions, 0 failed** (Fulgocobra OFF). Fulgocobra is back ON in `bb95db78`; its ON run passed: `test_remake_owner1101_finish.gd` **5 tests, 351 assertions, 0 failed** (asserts ON and "6.52"). `bb95db78` is landing-ready.

**PUSHED WITH TESTS PENDING (3 Nov ~20:00 UTC, coordinator: push hourly):** the capture queue's Stormwood storm-light overlay (`stormwood_ground_finish` value lift, `stormwood_surge`) has been in the working tree since ~17:40. `test_storm_cams_candidates.gd` ran with it applied: 14/15 passed, and `test_stormwood_value_lift_ships_off_and_lifts_when_on` failed because the overlay turns that arm ON (the committed file has it OFF). Not yet re-run clean: `test_storm_cams_candidates.gd`, `test_remake_owner1101_finish.gd`, `test_meadows_ridge_vl.gd` (the subagent ran it: 3/15 pass), and `test_texture_import_policy.gd` (needs the ridge texture reimport). Held OFF until they pass: **Fulgocobra gold vein (judged 6.52; flag OFF, its JUDGED_ON entry removed)**. Already OFF: rim r2, Meadows ridge. The re-run starts automatically when the overlay reverts.

**LANDING-READY GAIN (3 Nov ~17:55 UTC), `a5b28e0f`: F41#13 both halves now ON.** `creatures_ralph_fulgocobra_goldvein` ON: Fulgocobra **CPU 6.06 -> 6.52 mapped** (v1/b12; three judges, linear slope 1.26, r 0.91, RMSE 0.35, confirming batch). Stormraven `creatures_ralph_stormraven_charge` stays ON at 6.72. Test: `test_remake_owner1101_finish.gd` JUDGED_ON "6.52" (run queued with the clean retest). F38#19 `hud_lean` 5.30 -> 5.64 stays OFF: the judges blame the dim interior grade and the camera inside the loft ceiling, not the HUD.
- New OFF arms: `01a0f479` Stormwood rim r2 (F41#18, energy 1.15 / power 1.7); `15788371` **F38#24 Blender Meadows ridge ring** (`meadows_ridge_vl.json`: one continuous 360 deg ridge that replaces the procedural FarRanges/Foothills rings when ON; 43k tris; reference, 1.80 m scale check and provenance in `assets/props/vl-1103/meadows_ridge/`; `test_meadows_ridge_vl.gd` 3/15). Both are queued for capture.

**LANDING-READY GAINS (3 Nov ~17:25 UTC), `a8918db7` (v1/b9; three judges, linear slope 1.06, r 0.79, RMSE 0.74, confirming batch):**
- **F39#12 camp creature bed: CPU 5.86 -> 7.02 mapped.** `meshy_camp_props.json` `bed.nest_candidate` ON (Blender r2 straw nest; "reads as a pet bed in all three frames").
- **F39#13 camp workbench: CPU 6.03 -> 6.56 mapped.** `workbench.vl_candidate` ON (Blender r2 bench turned to face the camp).
- Test: `tests/test_camp_props_vl.gd` (both ON with "7.02"/"6.56", r2 models imported, both seat a model) **3 tests, 10 assertions, 0 failed**. Caveat: the base is b6's camp_base capture (same stands and seed, earlier run).

**Stormwood, remaining items (v1/b10 and b11, 3 Nov ~17:25 UTC):** at or above 6.0 as shipped, no change needed: **F41#11 portraits 6.90**, **F41#12 charged road 6.08**, **F41#14 candy tiers 6.13**. Held: F41#9 5.87 -> 6.00 (within noise; harvest round 2 alone next), F41#18 5.58 -> 5.98 (rim; a stronger rim next), F41#10 Glass Sink 4.45 -> 4.92 (needs a Blender basin). Unchanged or worse: F41#8 5.52, F41#19 5.58. F41#20 is not trusted (the base frame rendered black; recapture). F41#7 and F41#15 have no frames in either run. The road-puddle arm stays OFF: all judges flag it as flat lavender slabs, and it costs F41#8/#12/#14.

**LANDING-READY GAIN (3 Nov ~16:40 UTC), `1c80c758`: F38#4 map at or above 6.0 CPU.** `map_paint.json` ON (hillshade, canopy groves from the baked tree layers, painterly grain): **CPU 5.90 -> 6.30 mapped** (v1/b8; three judges, linear slope 1.11, r 0.66, RMSE 0.62, confirming batch, no warnings). All 3/3 judges preferred the painted side. Local, this head: `test_map_baker.gd` **8 tests, 18 assertions, 0 failed** (asserts ON and "6.30"); `test_texture_import_policy.gd` **2 tests, 1591 assertions, 0 failed**.

**v1/b7 stage poses (3 Nov ~15:50 UTC): no gain, GLBs not kept; F36#56 Nightburrow scores 6.11 as shipped.** The pose recipe (ground-clip settle, hit hop x0.3, hit spine/root amplify x1.8) on Terrapup and Burrowback/Nightburrow: F38#2 stage 6.50 -> 6.47; **F36#56 6.11 -> 6.11**. All three judges: hurt-end frames still read idle, and the faint frames are grounded (PARTIAL 3/3). The shipped Nightburrow maps 6.11 here, up from 5.66 in an earlier batch (caveat: anchor RMSE 0.80 > 0.75). The real levers are a distinct hurt-end keyframe and side-collapse faint, and fewer plates on Nightburrow ("full-body overgrowth" 3/3). `v1/b7/VERDICT.md`.

**LANDING-READY GAINS (3 Nov ~14:40 UTC), `1f19f24b` (v1/b5; three judges, linear slope 1.57, r 0.90, RMSE 0.50, confirming batch):**
- **F39#23 catch-chance contrast: CPU 6.02 -> 6.91 mapped, at or above 6.0.** `capture_readout_visual.json` `readout_side_enabled` + `contrast_r2` ON. The readout moves beside the ring onto a near-opaque plate, with a 32 px primary-colour caption. Defect FIXED 3/3.
- **F38#19 exploration HUD: CPU 5.23 -> 5.92 mapped (+0.69).** `house_textiles.json` ON: the loft bed comforter changes from plum-maroon (flagged as oxblood by all three judges) to sea-teal. 0.08 short of 6.0; `hud_lean` (+0.21 in v1/ui1a) is the next lever.
- Local, this head: `test_capture_readout_side.gd` 6/12, `test_house_textiles.gd` 3/7, `test_texture_import_policy.gd` 2/1589, `test_map_baker.gd` 7/16; all 0 failed.
- New OFF arm `461c4c94` + `3af001e6`, **F38#4 map paint** (`map_paint.json`): hillshade, canopy from the baked tree layers, painterly grain. OFF leaves the bake byte-identical (test_map_baker passes); a scratch bake takes about 7 s. Its F38#4 capture is queued.

**LANDING-READY GAIN (3 Nov ~12:10 UTC), `e9cdee30`: F39#9 at or above 6.0 CPU.** `hud.json message_clears_prompt` ON: Tidewake catch frames **CPU 6.14 -> 6.75 mapped** with this flag alone (v1/ui1c; three judges, linear slope 1.51, r 0.81, RMSE 0.69, confirming batch). Catches still complete with it; the full UI arm set broke catch completion 3/3, so the rest of that set stays OFF. Local: `test_storm_cams_candidates.gd` **14 tests, 48 assertions, 0 failed** (asserts ON and "6.75"). Also scored as shipped, no change needed: **F38#9 menu shell 6.08** (v1/ui1a), **F40#14 Cloudreach map label 6.29** (v1/ui1c).

**PR #805 `smoke_stormwood_spawn_slicing` (CI 2070 ms > 2000 ms): measured here, and the r2 arch is not the cause (3 Nov ~12:05 UTC).**
- **Code:** the smoke builds the host realm shell with `simulation_only = true` (line 45). In that mode `stormwood_arch_runtime.gd` returns right after the footing collider (line 114), before the slab, `ArchPresentation` and `CROWN_HERO.apply`, so no arch model (r1 or r2) and no arch texture is loaded during the measured boot.
- **Measured** on this 4-core container, `godot --headless --path . --script tests/smoke_stormwood_spawn_slicing.gd`, two runs per state, nothing else running (Godot lock held):

| State | run 1 | run 2 |
|---|---|---|
| r2 ON (PR #805) | 2357 ms | 3152 ms |
| r2 OFF, r1 ON | 2459 ms | 2177 ms |
| Blender arch fully OFF (main's state) | 2356 ms | 2129 ms |

- Every state, main's included, goes over 2000 ms here: the shell-boot gap is close to the limit on a 4-core runner, and the run-to-run spread (2.1-3.2 s) is wider than any difference between the states. CI's 2070 ms is the same near-limit gap, not an asset regression.
- **Not changed:** the limit and the smoke are untouched, and nothing on this branch alters the shell boot path. The fix belongs to whoever owns the encounter-director wild-spawn slicing (`wild_spawn_slice_ms`) or the sliced world build. A CI rerun of the shard should pass when it lands under the limit.

**LANDING-READY GAIN (3 Nov ~10:30 UTC): F41#17 Crown Arch at or above 6.0 CPU.** `crown_arch_vl.json` `r2_candidate` ON: **CPU r1 5.37 -> r2 6.19 mapped** (v1/arch2; three judges, linear slope 0.98, r 0.65, RMSE 0.64, confirming batch). The item went from the shipped Meshy pillar at 3.91 (v1/arch1) to 6.19. Local, this head: `test_hero_landmarks_1101.gd` **8 tests, 75 assertions, 0 failed** (asserts r2 ON and "6.19"); `test_texture_import_policy.gd` **2 tests, 1589 assertions, 0 failed**; `texture_import_policy.py --check` PASS. New OFF arm `0979aba4`: loft bed comforter retint (`house_textiles.json`; judges flag the plum-maroon comforter as reserved oxblood), `test_house_textiles.gd` 3/6 pass, `grandpa_house.gd` --check-only clean.

**PR #804 CI fixes (3 Nov ~08:45 UTC): both are fixed at `e8ba5211` or later; take this file's commit as the head.**
1. `tests/test_hero_landmarks_1101.gd`: `test_crown_arch_off_leaves_the_landed_arch_settings` is restored to its own job (the OFF assertion `HERO.crown_arch_overlay(landed) == landed`, plus the shipped-settings assertion against `HERO.crown_arch_vl_overlay(landed)`); the vl/r2 checks live only in `test_crown_arch_vl_ships_on_with_its_score_and_declares_only_model_keys`. Local: **8 tests, 74 assertions, 0 failed**.
2. Texture policy: the four `crown_arch_r2_arch_*.png.import` sidecars (and every vl-1103 and Fulgocobra goldvein sidecar) are mode 2 after `--apply` and a full headless import; `texture_import_policy.py --check` over the whole tree: **PASS, 1453 sidecars**. `test_texture_import_policy.gd`: **2 tests, 1589 assertions, 0 failed** (local, this head).
- From now on, before every push I run `test_texture_import_policy` and the unit tests for every test file I touched.

**LANDING-READY GAIN (3 Nov ~07:45 UTC), `b36b6105`:** **F41#17 Crown Arch CPU 3.91 -> 5.92 mapped (+2.01)**, `data/config/crown_arch_vl.json` ON (Blender four-legged crowned arch; three judges, linear slope 1.51, r 0.96, RMSE 0.24, confirming batch; `v1/arch1/VERDICT.md`). Test: `tests/test_hero_landmarks_1101.gd` (`test_crown_arch_vl_ships_on_with_its_score_and_declares_only_model_keys` asserts ON and "5.92"; the shipped-settings assertion now expects the judged arch). The r1 OFF version passed 8 tests / 57 assertions; the ON version's run is queued after the r2 import. 0.08 under 6.0; r2 (`r2_candidate`, OFF: dark slate, broken mossy flagstones over the slab) is captured next.

**Judged (3 Nov ~04:40 UTC), `v1/sw1/VERDICT.md`:** first CPU scores of the current branch, Stormwood arms ON vs OFF (linear fit, slope 1.38, r 0.87, RMSE 0.42, confirming batch):
| Row | Item | CPU base -> arms ON | Decision |
|---|---|---|---|
| F41#4 | named destinations | 5.25 -> 5.21 | arms stay OFF |
| F41#2 | Surge phases | 5.02 -> 4.93 | arms stay OFF |
| F41#5 | forest ground | 4.75 -> 4.70 | arms stay OFF |
| F41#17 | Crown Arch | 4.70 -> 4.56 | `hero_landmarks_1101.crown_arch` stays OFF |
| F41#1 | Stormheart | 4.52 -> 4.33 | arms stay OFF |
- No Stormwood arm gains; `stormwood_road_current.puddle_candidate` draws "flat lavender decal discs" in every frame (all three judges). All three ask for new art for the Crown Arch and the Stormheart.
- **New OFF arm `7ede7c5e` F41#17:** a Blender four-legged crowned arch (`data/config/crown_arch_vl.json`; an arch faces every approach, so the stand reads it as an arch whatever the yaw). Its test and its CPU capture are queued after the Tidewake import.

**Reprioritised per the coordinator (3 Nov ~04:45 UTC):** after the Stormwood step the queue runs, in order:
- **UI step:** the Meadows, Tidewake and Cloudreach UI and catch launches (F38#4/#7/#9/#13/#19/#33, F39#9/#23, F40#14/#18), with every UI arm ON as the candidate. The arms: `hud.json` quiet_empty_slots, hud_lean, catch_card, message_clears_prompt and victory_focus; `menu.json` satchel_focus and shell_board; `catching.json framed_camera.r2`; `camfx.json catch_orb`; `catch_kit.json`.
- **Pose step:** F38#1/#2/#26 and F39#6 in the Meadows/Tidewake creature frames, plus F36#56 Nightburrow on the neutral stage. The r23/r24 recipe is applied to the live remake GLBs of Terrapup, Bramblebun, Pipwing, Burrowback (= Nightburrow's model), Aquaryn r9 and Ripplet: `ground_clip.py --settle` on rest and faint, hit hop ×0.3. Terrapup and Burrowback also get their hit-react spine and root amplified ×1.8 for F38#2 "hurt frames keep the idle silhouette". A GLB is kept only where its row gains.
- **Then:** Fulgocobra, Tidewake, the unscored set, Meadows and Cloudreach.

**Not reachable here, stated now:** `capture_f39_tidewake_matrix.gd`, `capture_f41_stormwood_catalog.gd`, `capture_stormwood_look.gd` refuse CPU; I use the CPU tools above for those matrices (the same stands where they overlap) and say so in each verdict.

Branch `tb/creatures-ralph`. Capture and judging run in this container on CPU (coordinator, 2 Nov): import works with a partial import set (untracked temporary `.gdignore` files), and `capture_f36_poses.gd` renders on llvmpipe. Disk is about 300 MB free, so each set is imported, captured and dropped in turn.




## HANDOFF (3 Nov ~00:20 UTC): this session stops; the visual lane moves to session_01GPgpLTSwTp4iBviA53GNuS on this branch

**State:**
- Batch 1 (F39#11, F39#24 Riptusk, F36#58 Pebbik, F36#54 Mosshock) is committed and in PR #803. The r23 and r24 evidence is on this branch.
- Everything is pushed, and the tree is clean.

**Half-done:**
- **F41#13 electric finish (r25).**
  - `creatures_ralph_electric_charge` is committed OFF. It lights the Fulgocobra and Stormraven glow maps at energy 2.6 over a matte body.
  - The CPU A/B capture is done; the sheet is `r25/_sheet_r25.jpg` and the `key.json` and `spec.json` are committed.
  - The three judges were mid-run when this session stopped, so it has **no score**. Re-capture A (main) and B (flag ON) with `capture_f36_poses.gd -- --species=fulgocobra,stormraven --whole-body --context`, then judge.
  - **Judged after the stop (all 3 judges, calibrated; `r25/VERDICT.md`):**
    - Stormraven: 5.26 → **6.72** (+1.46).
    - Fulgocobra: 5.83 → 5.92 (flat).
    - The flag stays OFF. Next: split it into a Stormraven-only flag, turned ON with 6.72 in `_why` and in `JUDGED_ON`, and give Fulgocobra a vein mask on its gold bands.
  - The judges also flag Stormraven's raised wing as a flat "card" in hit and faint. That is a mesh or skin issue.
- **F39#4 shiny finish:** scoped, not started. The remakes ship no shiny textures, so a shiny remake falls back to a flat tint (the "near-uniform hot magenta"). It needs shiny colourways for the remakes.

**Not started; they need a full import (a fresh disk):**
- F38#1, F38#2 and F38#26 (Meadows creature collapse, hurt and ground contact) are captured with `tools/capture_f38_fight.gd` in the real yard.
- F39#6 is the same, in Tidewake.
- Every biome, landmark and settlement item.

**Shelved and flag-OFF, the coordinator's call:**
- Mangrove Monitor r21 (GLB and olive ON, already in PR #803 or later);
- the Skyrill and Tuskroot rim arms (OFF);
- Tuskroot ×1.1 (OFF);
- Abyssal Guardian r22 (GLB);
- the water_mangrove_monitor probe (not committed).

**What worked (the runbook, CPU, this container):**
- **Import one species at a time.** Temporary `.gdignore`s via a keepset; drop each species' `.godot/imported` after its capture.
- **Capture:** `capture_f36_poses.gd -- --species=X --whole-body --context [--roles=hit,faint,rest]`. `--roles` is new and covers the rest-pose items.
- **Rig fixes with `tools/art_pipeline`:**
  - `ground_clip.py` (`--percentile`, `--settle`, `--hop`): ground or settle last, after any limb amplify;
  - `amplify_clip.py` for hit ease and faint droop;
  - `relax_stretched_weights.py` for stretched skin;
  - a z −80° upper-limb fold for flipper or leg props.
- **Coats:**
  - `grade_regions.py`, with `detail_only`, `sat_scale`, `hue_shift` and regions;
  - coat flags take `albedo`, `roughness`, `specular`, `emission` and `rim` (rim renders on Forward+ only, never on Compatibility).
- **Judging:**
  - `anchor_tiles.py --pairs 3 --include craft`, copy `docs/reference`, then the JUDGE_PROMPT text block;
  - three general-purpose judges, then `calibrate.py`.
- **What did not work:**
  - value-ramp or matte coats on Aquaryn (two failures);
  - a roster grounded-hit clip flag (invisible at the stage camera);
  - lightening Tuskroot's hide (GPU regression).


## NEW ASSIGNMENT (owner via coordinator, 2 Nov ~22:35 UTC): the 89 visual items to ≥ 6.0 CPU mapped. First batch plan and constraints

**What this container can and cannot do (measured, not assumed):**
- **Blender is not installed here.** About 310 MB of disk is free (the allowance is spent), too little to install Blender or a `bpy` wheel, so I cannot build new meshes in this container.
  - A Blender-capable session with more disk is needed for every "new art" item: P2-014 mountains, P2-037 Stormheart tree, P2-055 and P2-056 character silhouettes, the P2-115 bed and P2-116 workbench props, and so on.
- **Biome, landmark and settlement items need a full project import.**
  - This covers the F38–F41 matrices, Veilfall, the destinations, mill, relay yard, stronghold, terrain, clouds and the Glass Sink.
  - Earlier in this session the full import did not fit this container's disk. I import one creature folder at a time with temporary `.gdignore`s.
  - Those items need a session with a normal disk allowance. I cannot score them honestly here.
- **What fits here:** creature pose and material items that `capture_f36_poses.gd` stages on the neutral stage, imported one species at a time.

**Batch 1 (started 2 Nov ~22:40 UTC; ETA about 3 h for scores; CPU baseline and candidate in the same run, three judges, anchors, calibrated):**
- **Pose items:** F36#70 Sparkit (5.41), F36#56 Nightburrow (5.66), F36#54 Mosshock (5.85), F36#58 Pebbik (5.88).
- **Roll-onto-back rests:** F39#24 (Riptusk and Torrentoad).
- **Riverdrake:** F39#11 crouch and recoil ground contact (unscored).
- **Rig recipe:** the r18–r22 recipe (hit hop ×0.3, folded limbs, faint settled after the leg tuck, weights relaxed) has already lifted Sirenseal (+1.48), Mangrove Monitor (+0.77) and Abyssal Guardian (+0.41) on CPU.
- **Shelved per the coordinator:** the r21 and r22 work and the water-variant probe. Their files are on the branch and not landed by me.

**Batch 1a results (r23, `cae748e1d`):**
- **F39#11** Riverdrake ground contact (unscored before): CPU 6.32 → 6.42. **At or above 6.0.** The GLB rest is settled and the hit hop is ×0.3.
- **F39#24** rest poses: Riptusk CPU 5.72 → 6.07 (kept, GLB) and Torrentoad 5.81 → 5.84 (a tie, not kept). The item stays under 6 until Torrentoad gets new art (the gaunt upright stance).
- These are GLB edits on live remakes, with their scores recorded in each remake flag's `_why`. Evidence is in `r23/`.

**Batch 1b results (r24):**
- **F36#58** Pebbik poses: CPU 5.98 → 6.07. **At or above 6.0.** GLB rest settled, hit hop ×0.3.
- **F36#54** Mosshock poses: 5.74 → 5.98 (kept, 0.02 short).
- **F36#70** Sparkit poses: 5.56, a tie, not kept. It needs new art (legs, coat).
- Evidence is in `r24/`.

**Batch 2, if disk allows:** the shared creature-stage items F38#1, F38#2 and F38#26 (Meadows collapse, hurt poses, ground contact), F39#6 (faint state), and F41#13 (Fulgocobra and Stormraven electric finish, a coat-flag arm).

## PR #799: both CI failures fixed on this branch (2 Nov ~15:40 UTC). Bring in head `f89846eb5` or later.

1. **`test_every_runtime_3d_texture_uses_vram_compression`:** fixed in `f89846eb5`.
   - The 33 sidecars are on mode 2, via `texture_import_policy.py --apply` and a headless reimport.
   - `--check` PASS (1434). `test_texture_import_policy.gd` passes locally.
2. **`test_judged_creature_coat_flags_ship_on_with_their_scores`:** fixed in `7a5951fbf`.
   - A judged coat must grade a `candidate_owner1101/` texture, or the exact live albedo of a remake's current model (r9 or r10). It never grades an installed model.
   - The same exact-live-albedo rule backs the "keys the remake's live albedo" check at `test_enabled_coat_flags_apply_every_key`.
   - `test_remake_owner1101_finish.gd`: every test passes locally except `apply_every_key` for species outside this container's partial import set (textures not imported here; CI imports all).

## ANSWER FOR THE CREATURE LANDING PR (2 Nov ~14:15 UTC)

- **Landing-ready head:** `7c7de66c9`, which is `9b1e168f6` plus a clean merge of origin/main (#798), or any later head of this branch.
- **Nothing must not land.** Every OFF flag changes nothing while off: tuskroot_brown, aquaryn_r9_scales, the grounded-hit roster flag, and the unkept r14/r15 coats.
- **Coordinator messages:** my replies to the coordinator's session are refused (`elevated_session_untrusted_device`), so this file is the reply.
- **GPU cr1102c** (tree 9b1e168f6 vs main1102b): **Staticub 6.43 → 7.98** (+1.55, above 7.5) and **Skyrill 5.97 → 7.43** (+1.46). Both are GPU-confirmed.
  - **Skyrill next step:** rim light and value separation.
  - **`SCORES.md`:** it does not exist, and the live-doc rule bars new status files, so the GPU records live in this file.

## BLOCKED: needs the coordinator (2 Nov, ~03:00 UTC)

- **The r9 Meshy models (Aquaryn, Duskhush, Mangrove Monitor) cannot be rigged in this container.**
  - The rig recipes (`prepare_remake_quadruped.py`, `rig_bird.py`) need Blender.
  - Blender is not installed, and only about 270 MB of disk is free, too little for Blender or a `bpy` wheel.
  - Please rig them where Blender exists (quadruped recipe for Aquaryn and Mangrove Monitor at the installed heights, `rig_bird` for Duskhush) and push the rigged GLBs to `candidate_r9/models/`. Or give this lane a session with more disk.
  - Once the rigged GLBs are on this branch, I run `arc_emission`, the weight relax and the CPU judge against the shipped remakes, then point the flag in the same commit.
- My cross-session messages to the coordinator are refused (`elevated_session_untrusted_device`), so this file is the channel.
- **Wake-ups.** I did not arm `send_later` wake-ups on a peer session's request alone. The user has to ask for those.

## r9 Meshy models (2 Nov ~10:00 UTC): all three wired to r9, waiting for the GPU (see QUEUE.md)

- **Duskhush** (r12): 4.61 → 6.30.
- **Aquaryn** (r13): 4.44 → 6.54.
- **Mangrove Monitor** (r13): 5.02 → 5.69.
- **What I changed on the r9 rigs:**
  - hit: neck, head and tail eased;
  - faint: grounded side-lie (about 77°, the root lifted per key), not belly-up;
  - the Monitor's hit hop scaled down;
  - Duskhush's wings eased ×0.5 in attack and fly_grip;
  - weights relaxed on all three.

## GPU cr1102b (2 Nov ~12:40 UTC; tree 29c1b53c5 vs main1102b) and the landing head

| Species | main | lane | Δ |
|---|---|---|---|
| Ashtusk | 7.21 | **7.52** | +0.31 |
| Torrentoad | 6.81 | 6.97 | +0.16 |
| Tuskroot | 7.65 | 7.01 | **−0.64, regression** |

- **Tuskroot is fixed for landing.** `creatures_ralph_tuskroot_brown` is OFF and removed from `JUDGED_ON`.
  - It was the only Tuskroot change: the Tuskroot GLB matches main, so Tuskroot on this branch now renders as main.
  - The Ashtusk lift is a separate flag on Ashtusk's own repaint, and it stays ON.
- **Landing-ready head:** the commit that carries this section; see `git log -1 -- ralph/reports/LANES/CREATURES-RALPH/READY.md`.
- **Nothing must not land.** Every OFF flag changes nothing while off:
  - tuskroot_brown, aquaryn_r9_scales, the grounded-hit roster flag, and the unkept r14/r15 coats.
- **Local checks:**
  - `test_remake_owner1101_finish.gd` and `test_creature_model_flags.gd` pass for every species this lane touched.
  - Species outside this container's partial import set fail only because their textures are not imported; CI imports everything.
  - `test_fight_camera_long_body_bias.gd` passes.

## Main merge held (coordinator, 2 Nov ~12:30 UTC)

#798 turned Meadows light and river candidates ON in main, and the F36 creature stage reads production `meadows_look.json`. This branch does **not** merge `origin/main` until cr1102b is judged and the creature landing PR is open, so the A/B lighting keeps matching the main1102b control. The first QUEUE job after that merge is marked "needs fresh main control (main1102c)".

## GPU-confirmed: cr1102 (2 Nov ~12:10 UTC; three code-blind judges, anchors, calibrated; tree 29518c111 vs main1102b)

| Species | main | lane | Δ |
|---|---|---|---|
| Sirenseal | 5.93 | **7.10** | +1.17 |
| Skyrill | 6.05 | 6.87 | +0.82 |
| Staticub | 6.46 | **7.16** | +0.70 |
| Thundertunnel | 5.59 | 6.28 | +0.69 |
| Aquaryn | 6.26 | 6.64 | +0.38 |
| Duskhush | 6.44 | 6.77 | +0.33 |
| Mangrove Monitor | 6.13 | 6.44 | +0.31 |

All seven are GPU-confirmed gains, and Sirenseal and Staticub cross 7.0. **Nothing on this branch must be held back from landing.** Every OFF flag (the grounded-hit roster flag and the unkept coat flags) changes nothing while off.

## Coordinator order of 2 Nov ~11:30 UTC: status

1. **Sirenseal hit and faint (r18): KEPT.** CPU 5.82 → 7.30 mapped on the r10 model. The hit hop is ×0.3; the left flippers fold and the faint settles, so the flipper prop is FIXED for all three judges. The GLB is in the queued GPU job.
2. **Bramblebun and Ripplet fight-camera bias (option 2):** already its own commit ("Fight camera: lean the pair midpoint toward the ally for longer remakes; Bramblebun and Ripplet ON"). Ready to land; CI's `smoke_combat` decides.
3. **Torrentoad blue speckled toad:** `creatures_ralph_torrentoad_toad` is ON. It scored r10 CPU 4.64 → 5.55, which clears the new target 4.73 (GPU roster 5.53 − 0.8). It is registered in `JUDGED_ON`. The gaunt biped silhouette still needs new art.
4. **Tuskroot and Ashtusk value lift:** already ON since r10 (Tuskroot 5.55 → 7.42, Ashtusk 5.71 → 7.07, CPU). The roster baseline (main dd2d01342) does not contain this branch, so its Tuskroot 6.85 and Ashtusk 7.16 are pre-fix. Please add both to the next GPU job.
5. **The 6.8–7.0 band.** Shared-lift probe (2 Nov ~12:30 UTC):
   - **Hit grounding (`creatures_ralph_grounded_hit_roster`).** 28 live remakes lift their hit react 0.15–0.68 m because the dog3 hit clip hops the root. One clip flag plants all 28 (position ×0.3).
     - The CPU stage A/B (tuskroot, mosshock, cliffspike) changes the hit frames by only 0.7–1.4 of 255 grey levels, because the hop is small at the stage camera.
     - Not judged; it stays OFF.
   - **Faints are uniform across the roster** (the 90° dog3 side-lie). No faint lever there either.
   - **Without the ROSTER-1102 per-species judge notes, the band has no evidenced shared defect.** Please push the notes. The judges' recurring note is rim light and value on the dark stage, which is lighting, not this lane's rig or coat work.

## r10 Meshy models wired (r16, 2 Nov ~11:00 UTC): Staticub, Sirenseal and Skyrill ON, queued for GPU with r9

- **Scores (mapped):**
  - Staticub 5.34 → **8.55**: "naturalistic bear, Stormursa bar".
  - Sirenseal 4.35 → **6.95**: "believable sea lion".
  - Skyrill 4.79 → **7.34**: "believable sail-back quadruped".
- **One GPU job** for the six r9 and r10 models is in QUEUE.md. Evidence is in `r16/`.
- **Sirenseal follow-up:** the hit lifts off the floor, and the faint end props on a flipper.
- **Thundertunnel (r17): KEPT, ON.** A velvet coat plus hit and faint fixes on the current remake: 2.93 → 5.36 mapped (target 3.92). The judges still want a clearer face and anatomy, which is the r10 remodel once Meshy credits return.
- **Test fix in `tests/test_remake_owner1101_finish.gd` (please review).** The r9 and r10 models carry glow masks, so `test_glow_pass_covers_every_remake_with_a_glow_mask` failed from r12 on. They are now in `remake_owner1101_glow_read`, which stays OFF, with maps from `remake_owner1101_finish.py`; that tool now reads the live remake model.
  - `test_enabled_coat_flags_apply_every_key` assumed every remake albedo lives under `candidate_owner1101/`. It now also accepts the exact live albedo of a remake's current model, which is stricter than a path pattern.
  - Locally, every check on the seven species I touched passes. The remaining failures are only species not imported in this container's partial import set; CI imports everything.

## Work list from 2 Nov ~09:20 UTC: the coordinator's GPU roster baseline (main dd2d01342)

16 of 70 creatures are at 7.0 or above. The full table lands as `ralph/reports/CLOUD-JUDGE/ROSTER-1102/`. Order of work:

1. **The 6.8–7.0 band** (aeriex 6.92, mosshell 6.92, galewisp 6.96, paddlenewt 6.98, trailpup 6.99, tuskroot 6.85, cindercub 6.85, stormbrush 6.82, nightburrow 6.80, water_mosshell 6.95): look first for a shared lift (faints, value against the dark stage, rim). Started: a CPU baseline of mosshell, galewisp and aeriex.
2. **Water variants:** do they inherit the base model's look fixes, and are their swim and ride clips missing?
   - **Band audit (2 Nov ~09:50 UTC).**
     - Faint end-roll: every live dog3 remake ends its faint on a 90° root side-lie (the bird recipe at 70°; fulgocobra and skyrill at 0°). There is no roster-wide over-roll to fix in one place.
     - CPU baseline of mosshell, galewisp and aeriex:
       - mosshell (an installed model, not a remake) flips fully belly-up in its own faint;
       - galewisp and aeriex read cleanly, with grounded side-lies.
     - Nothing shared stands out at the stage camera. **Needed from the coordinator: the ROSTER-1102 per-species judge notes** (defects per frame) for the band and the water_* rows. Without them every band arm is a guess. The water_* rows are separate species with their own clips and pose overrides (`creature_clip_flags.json`, `f36_pose_candidates.json`), so they do not inherit the base model's look fixes.
3. **The bottom, worst first.**
   - Thundertunnel, Sirenseal, Skyrill and Staticub get coordinator r10 Meshy models.
   - Sparkit, Ribbonray, Tempestwing and Ripplet are already tried (r14, r15) and need new art.

## GPU batch 6 (Sparkit, Tempestwing, Ribbonray), r14 (2 Nov): no keeps, shipped remakes unchanged

- **Sparkit:** shipped 5.86 vs regional fennec coat with the faint grounded 5.89 (mapped, three judges). A tie, so not kept. All three judges name "spindly stick legs"; that is mesh, so it needs a re-mesh or new Meshy art.
- **Tempestwing:** shipped 6.20 vs pale gold coat with the faint grounded 5.71. Not kept. The judges prefer the shipped dark body under bright white wings for the value split; the shipped faint already rests on its body (only the wingtips cross the floor).
- **Ribbonray:** shipped 5.53 vs value and saturation lift with the hit eased and the faint grounded 5.39. Not kept. All three judges call the magenta body "toy-like, no readable face". **It needs new Meshy art (a natural hue and a face). Parked.**
- The coat flags (`creatures_ralph_sparkit_fennec`, `_tempestwing_gold`, `_ribbonray_lift`) stay OFF with their scores. Evidence is in `r14/`.
- **Ripplet look (r15):** a natural otter regrade (sky-teal, deeper back, cream belly, matte, the grey dome texels recoloured) scored 5.29 against the shipped 5.42, so it is not kept. The judges want new art: fur or scale breakup, a back-to-belly gradient, natural plates in place of the domes, and glowing aqua markings and eyes. **Parked for Meshy.**
- **Requests for the coordinator's Meshy queue:**
  - Ribbonray: a natural-hued ray or serpent with a readable face;
  - Sparkit: the fennec with sturdier legs;
  - Ripplet: the otter with fur, natural plates and glowing aqua markings.

## GPU main1102 regressions (coordinator, 2 Nov ~08:30 UTC): status

- **Tuskroot and Ashtusk** (r10): KEEP and ON.
  - Tuskroot 5.55 → 7.42.
  - Ashtusk 5.71 → 7.07.
  - Both are in `JUDGED_ON`.
- **Torrentoad** (r10, r11): two approaches failed the 6.26 target (+0.91, +0.55).
  - **Coordinator: please generate the new Meshy blue toad.**
  - r10's coat stays committed with its flag OFF, as an optional interim (+0.91).
- **Terrapup** (r11): the faint change gave no gain, so it is dropped. The judges' issue is the plate grid, which the owner's look keeps. See `r11/VERDICT.md`.

## Paddlenewt remake ON (2 Nov ~06:55 UTC, coordinator GPU batch 5: installed 6.50 → remake 7.16)

- **Contract.** The HELD reason was "aspect variant Riftfrill uses textures painted for the old model". That is met: r5 shows Riftfrill's repaint resolving on the remake mesh.
- **Change.** The flag is ON and removed from HELD.
- **Caveat for the GPU.** On CPU r5, Riftfrill on the remake scored 5.70 against 6.49 installed. The judges called it "galaxy noise", the hunched stance came from the Paddlenewt mesh, and the GPU rates Paddlenewt higher. Riftfrill has not been GPU-judged on the remake yet, so please include it in the next GPU batch.
- **CI.** `test_dual_type` and `test_creature_model_flags` run in CI only.

## Queue additions (coordinator, GPU batch 5)

- **Meadowhart remake (live)** (r8, r9): the hit-react stoop fix is shipped in the GLB. Attempt-1 coat: 6.12 → 6.80 mapped (+0.68), 0.10 short of the 6.9 target, so `creatures_ralph_meadowhart_warm` is OFF. **Coordinator: please decide whether to turn it ON.** It is strictly better than the live remake. Attempt 2 gained nothing. See `r8/VERDICT.md`.
- **Mosshock remake (live): 6.55 → 6.45 on GPU.** A mild regression, at the end of Task 1.

## Bramblebun + Ripplet ON with the long-body fight-camera bias (coordinator option 2, 2 Nov ~08:40 UTC)

- **Commit.** "Fight camera: lean the pair midpoint toward the ally for longer remakes; Bramblebun and Ripplet ON". This commit stands alone. If CI's `smoke_combat` is red, drop only the failing species.
- **Code.** `fight_camera.gd::midpoint_bias_for(config, ally_ratio, foe_ratio)` returns `midpoint_bias` unchanged unless `camera.json fight.long_body_bias.enabled` is on and a fighter declares `framing_length_ratio` > 1. In that case it returns `midpoint_bias − slope·(ratio − 1)`, floored at `min_bias` (0.3). `combat_manager.gd` feeds it each fighter's declared ratio. No other fight changes.
- **Declared ratios** in `creature_model_flags.json`:
  - Bramblebun 1.18 (3.53 m rendered against the installed 2.99 m);
  - Ripplet 1.09 (hit-pose 6.22 m against the installed 5.73 m).
- **Test.** `tests/test_fight_camera_long_body_bias.gd` passes here: 4 tests, 79 assertions. It checks:
  - the bias is 0.5 within installed footprints, and shorter bodies never move it;
  - a longer remake leans the midpoint toward the ally;
  - with the flag OFF, nothing changes;
  - only declared remakes carry a ratio.
- **Not run here:** `smoke_combat` needs the Meadows world. If 1.18 or 1.09 is not enough lean, raise `slope` in `camera.json`; that touches only these two.

### Earlier analysis: smoke_combat camera anchor (2 Nov ~03:25 UTC)

Analysis only. `smoke_combat` needs the Meadows world imported, which does not fit this container's disk, so I could not run it.

- **The check.** `smoke_combat.gd::_check_the_fight_opened` takes the rig position minus height and shoulder, and fails when that is nearer the trainer than the ally.
- **What sets that position.**
  - `combat_manager.gd` calls `set_framing_pivot_offset(solution.pivot − ally)` and then `apply_fight_camera_pose`.
  - `fight_camera.gd::pivot()` lerps between the ally's and foe's **rendered** AABB centres (`camera.json midpoint_bias` 0.5). Those centres are `RENDER_BOUNDS.measure(model)`.
  - The arena spacing also grows with the **rendered** footprint (`_fighter_render_footprint` → `_admission_render_radius`, the xz reach of the render box corners).
- **Measured with CPU skinning, rest/idle pose.**
  - Both remakes are centred on their origins, the same as the installed models. Nothing is offset.
  - Bramblebun is longer: remake 1.59 × 3.00 × 3.53 m against installed 1.44 × 3.00 × 2.99 m. Its admission radius is 1.94 m against 1.66 m (hit pose: 2.30 m).
  - The extra length is in both ends: the head reaches +1.77 m and the leafy tail −1.77 m. Rotating the tail (±25–40°) does not shorten it, because the head end is just as long.
  - Ripplet: remake 1.94 × 3.60 × 5.87 m against installed 2.86 × 3.60 × 5.73 m (hit pose 6.22 m long).
- **What this means.**
  - The longer rendered bodies widen the formation and move the framing midpoint away from the ally, so the anchor ends up as near the trainer (2.6 m) as the creature (2.8 m).
  - Without shrinking, nothing in the remake mesh or rig moves it back. There is no stray island or offset to remove; the identity-defining head and leafy tail set the length.
- **Options (need a decision; I have not made any of these changes).**
  1. **Re-proportion the remake to the installed footprint.** This is how CAUSE-REMAKES fixed Terrapup (x 0.83, z 1.05, height kept, `terrapup/candidate_owner1101/source/fit_installed_footprint.py`). For Bramblebun that means z 0.85. It shortens the body, so it conflicts with "never shrink" unless the owner rule allows a height-kept re-proportion. **Owner/coordinator call.**
  2. **Bias the fight-camera midpoint toward the ally** for these pair classes (`camera.json` `midpoint_bias` below 0.5, or per `size_matrix` profile). This is a config change in the camera system, so it affects every fight's framing; CI and a GPU look would decide.
  3. **Leave both HELD** until one of the above is chosen.

## Done (CPU-provisional; batch these into the GPU confirmation pass)

- **Cliffspike** r1: 5.53 → 6.49 mapped (+0.96; target ≥ 5.80). GLB weight relax plus the coat flag `creatures_ralph_cliffspike_bands`. Ships as is.
- **Ashtusk** r1: 5.94 → 6.71 mapped (+0.77; target ≥ 6.60). Remake aspect textures plus rigid tusks in the Tuskroot GLB.
- **Tuskroot remake ON** r4 (takes Ashtusk live). Installed → remake mapped: Tuskroot 6.85 → 7.06; Ashtusk 5.36 → 7.27. The Tuskroot GLB weights are relaxed. Commit "r4".
- **Craghorn** r2: 5.75 → 6.45 mapped (+0.70; target ≥ 6.12). Weight relax in the GLB (horn stretch 1.38 m → 0.17 m). Ships as is.
- **Cannonback** r6: 5.33 → 6.22 mapped (+0.89; target ≥ 5.88). Coat flag `creatures_ralph_cannonback_moss` (ON).
- **Cragclaw** r7: 5.39 → 6.34 mapped (+0.95; target ≥ 5.90). Coat flag `creatures_ralph_cragclaw_body_mid` plus scale flag `creatures_ralph_cragclaw_presence` (×1.2). Landing needs the scale gameplay checks (arena containment) in CI.
- GPU form: `capture_f36_poses.gd -- --species=cliffspike,ashtusk,craghorn,cannonback,tuskroot,cragclaw --whole-body --context` with `remake_owner1101_tuskroot` enabled for Ashtusk; Forward+ 1920x1080, High first.

## Task 2 unholds that need CI (separate commit, "Task 2: turn ON ... CI to verify")

- Torrentoad, Meadowhart, Terrapup, Riptusk and Bramblebun are ON and removed from HELD. The CAUSE-REMAKES lane fixed each contract ("fixed, not run", `ralph/reports/LANES/CAUSE-REMAKES/READY.md`).
- Their contracts are gameplay smokes that need a full world import, and this container cannot run them. If CI fails any one, drop that species' two lines (flag `enabled` back to false, HELD line restored) and land the rest. That commit is independent of r1–r4.
- Still HELD:
  - Ripplet (parked by CAUSE-REMAKES: the combat camera anchor);
  - Burrowback, Trailpup and Paddlenewt (variant aspect textures not yet repainted for the remakes);
  - Mudsnout (Warrens seat);
  - Frostclaw (pose library).

## Parked / needs the coordinator

- **Aquaryn and Duskhush:** two approaches each with no gain (r1, r3). The judges ask for new models, which means Meshy, and the key is not in this container.
- **Mangrove Monitor:** two failed approaches (r2, r6). It needs new art via Meshy.
- **Burrowback and Trailpup remakes:** two approaches each (r5, r7) and still below their installed models. They stay HELD and are parked; they need new art or a re-rig (Blender).
- **Paddlenewt remake:** the hunched bipedal mesh needs new art (r5).

## Next

- **Task 3 (started 2 Nov, ~03:40 UTC).** The batch-4 creature table is not in the repo, so I used the last board scores on the coordinator dashboard (pre-1 Nov remakes). I baselined the shipped remakes of Sparkit, Mosshock, Pebbik and Shadelet on CPU.
  - **Shadelet:** the tail and leg geometry stands up about 2.7 m in the faint frames. It is skinned to the pelvis, head and rear_lower_r, not the tail chain. The rig joints sit off-centre and asymmetric across a mesh 3.4 m wide. It needs a Blender re-rig.
  - **Pebbik:** the faint end reads belly-up, but the shipped clip already keeps the feet lowest, so a root or pelvis roll does not help. It needs an authored faint (Blender).
  - **Mosshock:** the faint is a moss lump. Its worst clip stretch is 0.46 m (the weight relax brings it to 0.27 m), but r2 showed a relax alone does not move scores unless the artefact is visible.
  - **Sparkit:** reads cleanly; no defect obvious at the stage camera.
  - Without the current GPU table, Blender, or the rigged r9 models, further Task 3 rounds are guesswork. **Please push the batch-4 creature table (or the current board scores) to this branch.** I will then work up from the lowest score where grading or weights can help.

## Local checks

Not run yet. The required suite needs every remake imported, which does not fit this container's disk. Until I can run a scoped set, CI decides.

## Tools added (all without Blender)

- `tools/art_pipeline/relax_stretched_weights.py`: CPU skinning over gameplay clips, then a harmonic weight solve where triangles stretch.
- `tools/art_pipeline/rigid_bind_region.py`: binds a box region rigidly to one joint.
- `tools/art_pipeline/amplify_clip.py`: exaggerates a clip's rotations.
- `tools/art_pipeline/grade_regions.py` with `data/creatures/remake_grades.json`: regional coat grade by anatomy map.
- `tools/art_pipeline/grade_quill_bands.py`: banded quills.

## v1/b25 (4 Nov): Stormraven value lift ON (5.89 -> 6.59 mapped CPU); Fulgocobra, Voltwig and Mirejaw lifts judged flat, stay OFF
- `creatures_ralph_stormraven_value_lift` is ON, with its score in `_why_on`. The three flat arms record their result in `_judged`.
- Test: `test_dark_value_lift_flags` (+Stormraven). Ran `test_remake_owner1101_finish`, `test_creature_coat_flags` and `test_texture_import_policy`; all pass.
- Verdict: `v1/b25/VERDICT.md`. Albedo lift is now exhausted for near-black bodies, so the next arm is face/eye readability.

## v1/b26 (5 Nov): Reedwing (6.04 -> 6.70), Paddlenewt (6.15 -> 6.70) and Shadelet (5.97 -> 6.26) value lifts ON; Bramblebun flat, OFF
- The three gains ship ON, each with its score in `_why_on`. Riftfrill shares Paddlenewt's albedo, so the lift reaches it too.
- Test: `test_dark_value_lift_flags`. Also ran `test_creature_coat_flags`, `test_remake_owner1101_finish` and `test_texture_import_policy`; all pass.
- Verdict: `v1/b26/VERDICT.md`. Pose defects the judges name: Shadelet's upright faint tail, and Paddlenewt and Shadelet floating in hit-react mid.

## v1/b27 (7 Nov): Staticub (6.59 -> 6.80), Riverdrake (6.37 -> 6.69), Riptusk (6.22 -> 6.32), Sirenseal (6.53 -> 6.61) value lifts ON
- Resumed after the 5 Nov usage-limit pause and merged origin/main (#839).
- All four ship ON; every judge scored each one higher or equal. Calibration r is 0.51, which is weak; the raw scores are in the verdict.
- Test: `test_dark_value_lift_flags` (now handles r10 albedos). Also ran `test_creature_coat_flags`, `test_remake_owner1101_finish` and `test_texture_import_policy`; all pass.
- Glimmermoth, Pebbik, Galewisp and Tempestwing arms are committed OFF; their batch is next.

## v1/b28 (7 Nov): Tempestwing value lift ON (5.66 -> 5.87); Pebbik split, Galewisp and Glimmermoth flat, all OFF
- `creatures_ralph_tempestwing_value_lift` ON (score in `_why_on`). The other three record their results in `_judged`.
- Test: `test_dark_value_lift_flags`. Also ran `test_creature_coat_flags`, `test_remake_owner1101_finish` and `test_texture_import_policy`; all pass.
- The value lift has run out on the lighter remakes. The lane moves on to the pose defects the judges keep naming: faint wings and heads clipping the floor, hit-mid floating, and upright faint tails.
