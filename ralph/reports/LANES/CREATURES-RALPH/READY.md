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
