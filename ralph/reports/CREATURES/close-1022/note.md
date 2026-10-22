# Creatures close-1022 (lane tb/creatures)

## TO COORDINATOR
- 22 Oct 18:00 CT note on times: stamps in this file from 15:20 CT on match the machine clock. Earlier stamps (18:45, 23:00, 23:35 CT and the b4-b8 batch headers) were written from a wrong clock assumption and run later than the real times; the order of entries is correct.
- 22 Oct 17:30 CT READY tb/creatures-land b0c9c0de3 (ce8798be2 shinies + one commit): F36#0 Galecrest, an owner style-bar creature, on its installed model gets `field_emission` 1.35 (albedo value lift, hue-safe) and `field_rim` 0.25 in species.json. b10 on the corrected owner-style prompt: mapped 6.82 vs 5.73 live (clean fit, RMSE 0.58), CPU-provisional; dark-body defect FIXED x3. Checks on b0c9c0de3: Godot `--only=creature_body,species,fly,colourway,shiny,surface_finish,scale_ladder,texture_import_policy` 64 tests, 0 failed. GPU confirm with `capture_f36_poses.gd --whole-body --context --species=galecrest` (no `--candidate`).
- 22 Oct 17:30 CT (b10, same lever) Tanglevolt 5.84 -> 6.60 (+0.76, 0.1 short; stronger round next). Fulgocobra 6.20 -> 6.24 and Voltarach 6.13 -> 6.20 (no gain); their judges ask for faints and eyes instead. b11 (candidate-1022 hit/faint recipes on Voltarach, Mirejaw, Meadowhart, Staticub, Sparkit) is with the judges now.
- 22 Oct 17:00 CT ack OWNER DIRECTION (installed naturalistic models are the style). WITHDRAWN: tb/creatures-land2 (all commits) and the remake commits on tb/creatures-land; don't land either. On tb/creatures (2e78c13bc) every remake is unbound (species, water roster, Fly carrier, Mirejaw recipe back as on main), Fulgocobra's ordinary finish row is restored, and the remake files stay OFF in candidate_meshy1022. tb/owner-creature-style e188bc862 is merged; every batch from now on uses its JUDGE_PROMPT.md.
- 22 Oct 17:00 CT READY tb/creatures-land ce8798be2 (rebuilt from origin/main, force-updated; my branch): shinies only, on the installed models. P2-030 r3 fallback ON (6.80 mapped vs 4.59) and P2-018 Solmane/Pebbik gradient-map shinies (6.77 vs 5.65). 3 files: creature_surface_finishes.json and the two shiny PNGs. Checks on that head: Godot `--only=shiny,surface_finish,colourway,creature_body,variant,texture_import_policy` 47 tests, 0 failed.
- 22 Oct 17:00 CT next: the owner worklist on the installed models with the corrected prompt: (1) dark-palette value lift and rim, (2) faces/eyes, (3) hits and faints incl. Meadowhart's kneel, (4) Galecrest wings, (5) Stormursa vs Staticub.
- 22 Oct 15:55 CT done (texture import policy, your heads-up): on tb/creatures (0a66da133), tb/creatures-land2 (now 132319491, on c62d3eb10) and tb/creatures-land (now bf1be820e, on e42ddf1ea), every Meshy-1022 thumbnail.png has moved to `<sp>/reference/meshy-1022_thumbnail.png` (gdignored), with its .import dropped and provenance paths updated. `texture_import_policy.py --apply` VRAM-compresses the runtime 3D textures, and `godot --import` has been run. test_texture_import_policy: 0 failed on all three heads. The remakes now render with compressed textures, so any GPU confirmation should capture from these new heads. The land2 HOLD (b9 correction) still stands.
- 22 Oct 15:20 CT CORRECTION to READY tb/creatures-land2 c62d3eb10: hold it, don't land it as CPU-provisional. In b9 (clean fit: RMSE 0.53, no warning, confirming batch) the same shipped remake files map to only Galecrest 5.56, Fulgocobra 5.68, Voltarach 5.81. b8's 7.05 / 6.89 / 6.73 came from a fit with RMSE 0.81, so b8 overstated them by about 1.0-1.5. They still beat live (b8 live raw 3.7-4.3 against remake 5.6-6.6, x3 judges), so c62d3eb10 is an improvement over main, but it is not >= 6.7. Your call: land it as an improvement with the row still open, or wait for GPU. I recommend a GPU judgement before any land. The same caveat applies to c7b3a66e3 (b6 also had RMSE > 0.75).
- 22 Oct 15:20 CT (b9) Face-grow + albedo-lift candidate (meshy1022h: head x1.25/x1.35, gamma 0.72-0.85) gained 0.00-0.06 mapped; none of the three judges saw a difference at strip size. That is the second round under +0.5 for Galecrest, Fulgocobra and Voltarach, so all three are PARKED on scene and material work. The remaining lever is new art: designed lighter colour blocks, bigger eyes or face plates, surface grain. MESHY ask: redraft Galecrest and Fulgocobra with those, plus the Voltarach eight-leg redraft already in OUTBOX.
- 23 Oct 01:40 CT READY tb/creatures-land2 c62d3eb10 (from origin/main 9c97caa68): Meshy-1022 remakes ON for Galecrest, Fulgocobra and Voltarach only, as judged in b8 (mapped 7.05 / 6.89 / 6.73 vs live 5.24 / 5.11 / 5.06; RMSE 0.81 caveat).
  - Contents: the three GLBs byte-identical to the b8 captures (tb/creatures `<sp>/candidate_meshy1022`), their Meshy raw folders, drafted references and provenance; species.json binds model + `colourway_source_species` `<sp>_meshy1022` + the Voltarach clip map; Fulgocobra's old-texture `ordinary` finish row dropped; Galecrest Fly carrier on the remake; `rig_bird.py --hit-gain` (default 1.0, other birds unchanged). No recipe flags: none of the three is in `enabled_species`, so they play their own clips. No Meadowhart/Riverdrake (005faf1b8), no Tanglevolt/Stormcapra/Mirejaw, no Stormursa growth.
  - Checks on c62d3eb10 itself: Godot `--only=f36_pose,scale_ladder,water,roster,colourway,surface_finish,fly,creature_body,species` 570 tests, 0 failed (scale ladder and grow-only included); test_f36_pose_postpass 8/8 OK (tear checks, water forms included).
  - Judged = shipped: capture the GPU confirmation from c62d3eb10 itself with `capture_f36_poses.gd --whole-body --context --species=galecrest,fulgocobra,voltarach` (no `--candidate`), so the GPU judges see exactly the shipped files. tb/creatures-land c7b3a66e3 (six remakes) is superseded by this branch for these three; the other three stay off.
- 23 Oct 01:20 CT READY tb/creatures-land e42ddf1ea (on top of c7b3a66e3): shiny fixes ON, CPU-provisional.
  - P2-030 r3: the `shiny_fallback` hue shift ON with the r3 per-species rows (tb/shared-art ae6bafa24); Tidewake shinies are no longer flat magenta. b2: 6.80 mapped vs 4.59, magenta FIXED x3.
  - P2-018: Solmane/Pebbik gradient-map shiny textures with no shift on top. b2: 6.77 mapped vs 5.65.
  - Checks: Godot `--only=shiny,surface_finish,colourway,creature_body,variant` 45 tests, 0 failed.
  - GPU: re-run the P2-018 (13 rows) and P2-030 (Tidewake 13) `phase2_capture_creatures.gd --poses=idle,shiny_idle` sets.
- 23 Oct 00:55 CT READY tb/creatures-land c7b3a66e3: F36#0 stylised Meshy-1022 remakes ON, CPU-provisional (CLAUDE.md: mapped >= 6.7 until GPU confirms 7.5).
  - Mapped CPU scores vs live 4.9-6.3, three-judge yardstick, b4-b8 in close-1022/: Stormcapra 7.20, Galecrest 7.05, Fulgocobra 6.89, Tanglevolt 6.81, Mirejaw 6.80, Voltarach 6.73. b6 and b8 carry the RMSE > 0.75 caveat.
  - Contents: the six `candidate_meshy1022` models (rigged and animated here) and their Meshy raw folders; species.json bindings (model, `colourway_source_species` so no old-UV textures swap in, footprint allowances); the Voltarach clip map (charged->attack, rest->faint, swim->walk, fly_grip/ride->idle); Mirejaw out of `enabled_species` (its recipe targets the old rig and would refuse anyway); Fulgocobra's old-texture `ordinary` finish row dropped; water Mirejaw (fit allowance 7.8) and the Galecrest Fly carrier on the remakes.
  - Base: 4ce8d157e (Aeriex).
  - Checks: Godot `--only=f36_pose,scale_ladder,water,roster,colourway,surface_finish,fly_traversal,creature_body,species` 558 tests, 0 failed; `--only=fly` 28 tests, 0 failed; test_f36_pose_postpass 8/8 OK.
  - Please queue GPU confirmation of all six with `capture_f36_poses.gd --whole-body --context` (no `--candidate`: they play their own clips).
  - Known gap: the remakes have no authored shiny colourway yet; shinies take the finish/tint path.
- 22 Oct 23:35 CT QUESTION GPU-judge the Meshy-1022 remakes? On the CPU yardstick they sit at 6.7-7.2 against live 4.9-6.3: Stormcapra 7.20, Fulgocobra 6.87, Tanglevolt 6.81, Mirejaw 6.80, Galecrest 6.72, Voltarach 6.43 (b4-b7). Your GPU scale has run 0.7-1.0 above CPU on the same rows, so Stormcapra and Fulgocobra could clear 7.5. They are flag-off on tb/creatures at `<sp>/candidate_meshy1022/models/creature_<sp>_meshy1022.glb`. To bind one for a GPU capture, set its species.json placeholder: `model` to that GLB, `colourway_source_species` to `<sp>_meshy1022` (so no installed vivid texture is swapped onto new UVs), footprint_allowance 3.9 for tanglevolt / 7.8 for mirejaw / 3.8 for fulgocobra, and drop fulgocobra's `ordinary` row from creature_surface_finishes.json. Capture: `capture_f36_poses.gd --whole-body --context` without `--candidate` (these play their own clips). Voltarach needs its missing clips mapped (swim/fly_grip/ride/rest/charged) before it could ship.
- 22 Oct 23:35 CT BLOCKED Riverdrake growth can't be judged on the stage (it frames each creature to its own size; 5.6 m scored identical to 4.0 m). It needs an in-world fixed-camera capture. Meadowhart's head-down faint end won't take on its rig (`rest_head` either sign keeps the head up); parked.
- 22 Oct 23:00 CT READY tb/creatures-land 4ce8d157e: 7e0e76daa (Aeriex installed clips, already in #709) plus the author_f36_pose_profiles.py Aeriex exclusion only. 005faf1b8 is dropped from the land branch (GPU 7.22-7.39 < 7.5), and on tb/creatures the Meadowhart/Riverdrake recipes are back OFF under `--candidate-1022` (live profiles == main).
- 22 Oct 23:00 CT done: b3 per-judge verdicts in b3/judges.md; test_f36_pose_postpass now tear-checks the water_ forms (water_riverdrake hit 0.035, faint 0.035; water_torrentoad faint 0.112; all < 0.12). Next GPU state: Meadowhart head-down faint (rest_head 60) + field_rim, and Riverdrake grown with field_rim. SHA follows once judged on CPU.
- 22 Oct 18:45 CT READY tb/creatures-land 005faf1b8 F36#0 Meadowhart 7.56 + Riverdrake 7.51 mapped (CPU b3, confirming batch; held shove hit, Meadowhart resting-deer faint), on top of 7e0e76daa Aeriex. Checks: test_f36_pose_postpass 8/8 OK; Godot test_f36_pose_candidates + test_creature_scale_ladder 0 failed. Please queue GPU confirmation (Low/Compatibility and Medium) with `capture_f36_poses.gd --candidate --species=meadowhart,riverdrake`.
- 22 Oct 16:35 CT QUESTION Can the GPU lane judge Riverdrake c3 (shove hit) and Meadowhart c1 (shove + resting-deer faint) against live? On CPU both gain (+0.40 / +0.59 mapped, b2), and the same live rows sit 0.7-1.0 higher on your GPU yardstick (7.33 / 7.19), which projects ~7.7 / ~7.8. Recipes: `python3 tools/art_pipeline/f36_pose_postpass.py --candidate-1022 --topple=meadowhart --shove-hit=riverdrake` (tb/creatures). Capture: `capture_f36_poses.gd --candidate`. Also P2-030 r3 maps 6.80 on CPU (magenta FIXED x3); file `close-1022/p2-030-r3-finishes.json`.
- 22 Oct 15:05 CT READY tb/creatures-land 7e0e76daa F36#0 Aeriex: removed from enabled_species so it plays its installed clips (your GPU yardstick: installed 7.54 vs recipe 7.16, confirming batch). Check: test_f36_pose_postpass 8/8 OK.
- 22 Oct 14:40 CT QUESTION Is OUTBOX.md fine for MESHY requests (six MESHY lines and three REDRAFTs are there), or should they move here?
- 22 Oct 14:40 CT (b1 CPU yardstick) Candidates beat base on every set, but none has reached 7.5: shiny 6.60, poses 6.64, dark palette 6.12, F29#3 6.12 (mapped). Round 2 is capturing now.

Renderer for every capture: Godot 4.7 Compatibility (Low), Mesa llvmpipe under xvfb. Scoring waits for the
judge yardstick (tb/judge-yardstick) to land; until then this lane fixes and captures.

## RESUME
- Coordinator messaging is refused from this session (`elevated_session_untrusted_device`); see `OUTBOX.md`.
- Meshy remakes (two-style split, top GPU ask) are blocked on reference drafts: `remake-briefs.md`.
- Candidates, all OFF on the branch:
  - `f36_pose_postpass.py --candidate-1022` (+ `f36_arachnid_profile.py --candidate-1022`): every recoil hit becomes
    the body-carried shove at gain 1.5; Mirejaw side topple; Meadowhart resting-deer prone (antlers off the floor);
    Fulgocobra hood-drop prone (dip 3) + shove; Voltarach side-tip with legs curled.
  - `data/config/creature_surface_finish_1022_candidate.json`: value-gamma lift for Tanglevolt, Voltarach,
    Galecrest, Fulgocobra (shader uniforms `base_value_gamma`/`base_saturation_scale`, default 1.0 = unchanged).
  - Solmane / Pebbik shiny gradient maps: `<species>_extracted_base_color_shiny_gm.png`
    (`solmane/source/shiny_gradient_map.py`); live shiny png and the `shift` rows unchanged.
  - P2-030 r3 (ported from tb/shared-art ae6bafa24 with the fallback ON): `p2-030-r3-finishes.json`.
  - F29#3 growth: Stormursa 4.10 -> 5.00 m (species.json height/radius + ladder target) on this branch only.

## Batch b1 (22 Oct ~14:00 CT): yardstick round 1, every candidate beats its base; none at 7.5

CPU Compatibility (llvmpipe), stage tool `capture_f36_poses.gd --candidate --whole-body --context` at 1280x720
(base = lane state with live recipes and Stormursa 4.10 m; c1 = `--candidate-1022` recipes, finish candidate rows,
Stormursa 5.00 m) and `phase2_capture_creatures.gd --biome=cloudreach --poses=idle,shiny_idle` for the shinies.
Standard prompt verbatim, three fresh judges, 3 anchor pairs (p2_094_r4, f36_0_gap:C2, f36_0_npc:C1), `calibrate.py`:
linear, slope 1.309, intercept -1.827, anchor RMSE 0.432, top anchor 7.53 (confirming batch), no warnings. Files: `b1/`.

| Set | Base raw (j1/j2/j3) | c1 raw | Base mapped | **c1 mapped** | Gain |
|---|---|---|---|---|---|
| P2-018 Solmane + Pebbik shinies (gradient map) | 5.6/5.6/5.6 | 6.4/6.5/6.4 | 5.50 | **6.60** | +1.10 |
| F36 poses (Mirejaw, Meadowhart, Voltarach) | 5.2/5.6/5.4 | 6.2/6.6/6.6 | 5.24 | **6.64** | +1.40 |
| F36 dark palette (Tanglevolt, Galecrest, Fulgocobra) | 5.4/5.6/5.3 | 6.0/6.2/6.0 | 5.29 | **6.12** | +0.83 |
| F29#3 Stormursa 5.00 m + bear shove hit | 5.3/5.8/5.5 | 5.8/6.4/6.0 | 5.42 | **6.12** | +0.70 |

Defects (c1): hit react FIXED x2 / PARTIAL x1; Mirejaw+Voltarach faint FIXED x2 / PARTIAL x1; Meadowhart antlers FIXED x3;
dark melt PARTIAL x3; shiny blotches PARTIAL x3 (Solmane navy wing streaks and eye smudges, Pebbik flank mottling);
cub = adult model PRESENT/PARTIAL (needs new art), bear hit PARTIAL (recover equals standing).
Asks: lift dark grades further plus a soft rim (Mirejaw's faint end goes near-black; Voltarach melts); a distinct
juvenile cub mesh (new art); cleaner shiny masks. Fulgocobra keeps its live pose (prone hood-drop dropped unjudged).

## Batch b2 (22 Oct ~16:30 CT): every candidate beats live again; none at 7.5 on CPU

Same capture routes as b1. P2-030 r3 = tb/shared-art ae6bafa24 finishes with `shiny_fallback` ON (13 Tidewake
shinies, `phase2_capture_creatures.gd --biome=water --poses=shiny_idle`). 4 anchor pairs incl. craft and
f04_6_r22 (non-creature) and f36_0_npc:C1. Fit: linear, slope 0.936, intercept 0.688, r 0.768, RMSE 0.619,
top anchor 7.53 (confirming batch). Warning: some candidates lie >0.5 outside the anchors' measured range. Files `b2/`.

| Set | Base raw | Cand raw | Base mapped | **Cand mapped** |
|---|---|---|---|---|
| P2-030 r3 Tidewake shinies | 4.0/3.8/4.7 | 6.5/6.5/6.6 | 4.59 | **6.80** (magenta FIXED x3) |
| P2-018 Solmane+Pebbik c3 | 5.0/5.3/5.6 | 6.3/6.6/6.6 | 5.65 | **6.77** (Pebbik FIXED x3, Solmane PARTIAL: wing streaks, eye dots) |
| F36 dark c2 (Tanglevolt, Galecrest, Fulgocobra) | 4.8/4.7/5.4 | 5.8/6.0/6.2 | 5.34 | **6.31** (melt FIXED x2) |
| F36 Mirejaw+Voltarach c2 (pose + lift) | 4.5/4.9/5.2 | 5.6/6.0/6.2 | 5.24 | **6.24** (faint FIXED x3, melt FIXED x3, spider hit PARTIAL) |
| F36 Meadowhart c1 (shove + resting faint) | 5.6/5.9/6.2 | 6.2/6.6/6.8 | 6.21 | **6.80** (hit FIXED x3, antlers FIXED x2) |
| F36 Riverdrake c3 (shove hit) | 6.0/6.3/6.6 | 6.6/6.7/6.9 | 6.59 | **6.99** (hit FIXED x3) |

CPU stage vs GPU: the same live Riverdrake and Meadowhart map 6.59 / 6.21 here and 7.33 / 7.19 on the GPU
yardstick (stage capture, Medium). Adding the CPU gains to the GPU live scores projects Riverdrake c3 ~7.7 and
Meadowhart c1 ~7.8; only a GPU batch can confirm that.
Remaining asks: Solmane wing streaks/eye smudges; Galecrest thin spiky silhouette and tangle faint (new art);
Voltarach hit still weak; faint mid should visibly start to go down; creature faces (new art).

## Batch b3 (22 Oct ~18:00 CT): Meadowhart 7.56 and Riverdrake 7.51 mapped (CPU), both ON

c4 = `--candidate-1022` plus the longer shove hold (release .5, back by .97) and Meadowhart prone dip 2.5;
Voltarach hit doubled. Base = live recipes (Stormursa 4.10 m). Anchors: f36_0_npc:C1, p2_094_r4, craft, f36_0_gap:C7.
Fit: linear, slope 1.323, intercept -1.750, r 0.948, RMSE 0.431, top anchor 7.53. Meadowhart passes only above the
top anchor, but this batch's anchors reach 7.35 or more, so it is the confirming batch. Files `b3/`.

| Set | Base raw | c4 raw | Base mapped | **c4 mapped** |
|---|---|---|---|---|
| Meadowhart (shove + resting-deer prone faint) | 6.4/5.8/6.0 | 7.2/6.9/7.0 | 6.28 | **7.56** (above top anchor, confirming) |
| Riverdrake (shove hit, held) | 6.6/6.4/6.2 | 7.2/7.0/6.8 | 6.72 | **7.51** |
| Mirejaw + Voltarach (pose + lift) | 5.2/4.6/4.4 | 6.3/5.8/6.1 | 4.51 | 6.28 |
| F29#3 (Stormursa 5.00 m + held shove) | 6.2/5.9/5.6 | 6.7/6.4/6.0 | 6.06 | 6.67 |

Meadowhart and Riverdrake are now live on tb/creatures (`SHOVE_GAIN_BY`, `SHOVE_HOLD_BY`, `LIVE_SHOVE_HIT`,
Meadowhart `PRONE` dip 2.5). The regenerated profiles are byte-identical to the judged c4 ones, and every other
profile is unchanged.
Remaining: the Meadowhart faint end overlaps the stage ruler (staging only; the ruler stands beside the
creature). Mirejaw/Voltarach c2 palettes now read blown-out white and yellow; tone them down. The F29#3 cub is
the same model as the adult (new art).

## Batch b4 (22 Oct ~20:00 CT): the Meshy-1022 remakes beat the live models by 0.5-1.7; none at 7.5

Capture: `capture_f36_poses.gd --whole-body --context` without `--candidate` (installed clips, as non-enabled
species ship), live vs remake bound locally (species.json model + colourway source + footprint allowance).
Remakes are rigged here: measured quadruped (Tanglevolt, Stormcapra, Mirejaw), rig_bird (Galecrest) and new
cobra/spider rigs (Fulgocobra, Voltarach); their clips carry the held shove hit. Fulgocobra was held back (its
first faint folded backwards) and is recaptured. Anchors: f36_0_gap:C7, f10_2_r3_capacitor, craft, f36_0_npc:C1.
Fit: linear, slope 0.897, intercept 1.314, r 0.856, RMSE 0.633, no warnings. Files `b4/`.

| Species | Live raw | Remake raw | Live mapped | **Remake mapped** | Two-style defect |
|---|---|---|---|---|---|
| Tanglevolt | 4.7/4.6/4.8 | 6.4/5.6/6.4 | 5.53 | **6.81** | FIXED x3 |
| Stormcapra | 6.0/5.2/5.3 | 6.4/5.6/6.3 | 6.25 | **6.78** | FIXED x3 |
| Galecrest | 4.3/3.8/4.2 | 6.3/5.8/6.0 | 4.99 | **6.72** | FIXED x3 |
| Voltarach | 4.5/4.0/4.0 | 5.8/5.6/5.2 | 5.05 | **6.28** | FIXED x3 |
| Mirejaw | 4.6/4.2/4.3 | 5.6/5.4/5.3 | 5.23 | **6.19** | PARTIAL x3 |

Asks:
- faint ends collapse into dark or colourless blobs (side-roll / belly-up shows the unlit underside);
- weak hit on the bird, spider and ram; the spider's faint mid stands it on end;
- Mirejaw's face is small and its body barely clears the trainer;
- Tanglevolt and Stormcapra read cute/plastic (owner steer: stylised realism, not cartoon).

## Batch b5 (22 Oct ~21:00 CT): Fulgocobra remake 6.87, Voltarach remake r2 6.43; Riverdrake growth not visible

Fit: linear, slope 0.880, intercept 1.207, r 0.829, RMSE 0.679, no warnings. Files `b5/`.

| Set | Base raw | Cand raw | Base mapped | **Cand mapped** |
|---|---|---|---|---|
| Fulgocobra Meshy-1022 (cobra rig, forward fold faint) | 4.1/4.0/4.5 | 6.5/6.2/6.6 | 4.90 | **6.87** (two-style FIXED x3) |
| Voltarach Meshy-1022 r2 (flip done by .4) | 4.2/3.7/4.2 | 5.5/6.3/6.0 | 4.75 | **6.43** (faint FIXED x3; one judge: reads as a beetle, not a thunder spider) |
| Riverdrake c4 (live) vs grown 4.80 m + rim | 6.0/5.9/6.3 | 6.1/6.0/6.3 | 6.54 | 6.60 |

- **Riverdrake:** the stage tool reframes every creature to its own size, so the growth can't show against the
  ruler, and the rim (`rim_amount` on the finish overlay) is invisible. I reverted the growth; it needs an
  in-world fixed-camera capture to judge. The same live c4 Riverdrake mapped 7.51 in b3 and 6.54 here, so the
  b3 pass sat inside batch noise (RMSE 0.43-0.68). The GPU yardstick's 7.39 is the number that counts.
- **Rim finish:** the rim row turns Meadowhart flat yellow (the overlay drops the base material's colour
  multiply), so it isn't usable as a generic rim light.
- **Asks:** a material rim/fresnel pass on creatures (needs a shader-side change, not the overlay); weak hits on
  the spider and bird; ram faints float.

## Batch b6 (22 Oct ~22:00 CT): quadruped remakes with back-to-camera faint: Stormcapra 7.20, Mirejaw 6.80, Tanglevolt 6.80

Fit: linear, slope 0.814, intercept 1.884, r 0.794, RMSE 0.754. **Warning:** anchor residual RMSE 0.75 > 0.75
(these judges ranked the anchors less like the reference judges); report the mapped scores with this caveat. Files `b6/`.

| Species | Live raw | Remake raw | Live mapped | **Remake mapped** |
|---|---|---|---|---|
| Stormcapra | 4.4/5.0/4.0 | 6.6/6.5/6.5 | 5.52 | **7.20** |
| Mirejaw | 3.8/4.6/3.7 | 5.9/6.0/6.2 | 5.17 | **6.80** |
| Tanglevolt | 4.1/4.8/3.9 | 6.1/5.6/6.4 | 5.36 | **6.80** |

All three recorded defects are FIXED on every remake: two styles, hit reads as standing, and dark faint blob
(Mirejaw two-style PARTIAL x1).
Asks:
- flat, plasticky material with no rim (the `field_rim` round is next);
- small faces on Stormcapra and Mirejaw;
- Tanglevolt's saturated royal blue drifts off the Stormwood storm-wolf board (grey/violet with white-violet
  lightning).

## Batch b7 (22 Oct ~23:30 CT): Stormcapra remake + rim 6.96; Riverdrake 5.6 m and Tanglevolt violet don't help

Fit: linear, slope 0.915, intercept 1.042, r 0.874, RMSE 0.594, no warnings. Files `b7/`.

| Set | Live raw | Cand raw | Live mapped | **Cand mapped** |
|---|---|---|---|---|
| Stormcapra remake + `field_rim` 0.3 | 5.3/5.2/5.2 | 6.2/6.6/6.6 | 5.83 | **6.96** |
| Riverdrake 5.60 m + `field_rim` 0.3 | 5.9/5.8/5.8 | 5.9/5.8/5.8 | 6.38 | 6.38 (all three: sides identical) |
| Tanglevolt remake, grey-violet shift | 5.7/5.3/5.1 | 4.9/4.7/4.9 | 5.95 | 5.46 (flat clay purple; worse) |

- **Riverdrake:** the stage frames each creature to its own size, so no growth reads; that ask needs an in-world
  fixed-camera capture (`phase2_capture_creatures.gd`). Not committed.
- **Tanglevolt:** the violet shift is dropped; the blue remake (b6 6.80) stays the best.
- **Meadowhart:** the head-down faint end (`rest_head`, either sign) leaves the head raised on this rig; parked.

Gain rule (mapped, CPU; best per item):

| Item | Rounds | Status |
|---|---|---|
| Stormcapra remake | 6.78 → 7.20 → 6.96 | two rounds < +0.5: PARKED at 7.20 |
| Tanglevolt remake | 6.81 → 6.80 → 5.46 | PARKED at 6.81 |
| Mirejaw remake | 6.19 → 6.80 | open |
| Fulgocobra remake | 6.87 | open |
| Galecrest remake | 6.72 | open |
| Voltarach remake | 6.28 → 6.43 | open |

The clearly different next approach is the stylised-realism redraft (owner steer), not more scene tweaks.

## Batch b8 (23 Oct ~00:30 CT): stronger hits on the remakes: Galecrest 7.05, Fulgocobra 6.89, Voltarach 6.73

Changes:
- Fulgocobra cobra rig: hit rears 30/32 (was 16/18).
- Voltarach spider: carapace 26, every leg lifts.
- Galecrest rig_bird: `--hit-gain 2.0` (new option; the default 1.0 leaves every other bird unchanged).

Fit: linear, slope 0.798, intercept 1.971, r 0.758, RMSE 0.806. **Warning:** RMSE 0.81 > 0.75, so these
judges ranked the anchors less like the reference judges; read with that caveat. Files `b8/`.

| Species | Live raw | Remake raw | Live mapped | **Remake mapped** | Previous best |
|---|---|---|---|---|---|
| Galecrest | 4.3/4.0/4.0 | 6.2/6.3/6.6 | 5.24 | **7.05** | 6.72 |
| Fulgocobra | 4.0/3.8/4.0 | 6.3/5.8/6.4 | 5.11 | **6.89** | 6.87 |
| Voltarach | 4.0/3.7/3.9 | 6.0/5.6/6.3 | 5.06 | **6.73** | 6.43 |

All three recorded defects are FIXED x3 on every remake: two styles, hit-as-standing, and no faint.
Asks: flat, plasticky material with no rim; dark bodies on the dark stage (cobra, spider shell); small faces on
the bird and spider. Fulgocobra has now had one round under +0.5.

## Batch b9 (22 Oct ~15:10 CT): face-grow + albedo-lift on the three remakes, no visible gain; b8 scores overstated

Candidate: `tools/art_pipeline/meshy1022_head_grade.py`, written to `<sp>_meshy1022h.glb` (OFF). It scales vertices weighted to the leaf head joint (Galecrest x1.25, Fulgocobra x1.35) and lifts the albedo value (gamma 0.85 / 0.75 / 0.72). A finish-overlay value lift was tried first and made the bodies darker (the overlay path loses the sRGB read), so it was dropped. Base = b8 remake frames (`.artifacts/b8c`), candidate = `.artifacts/b9h`, both on the stage tool without `--candidate`. Anchors: craft, f36_0_npc:C1, f36_0_gap:C1, f04_6_r22. Fit: linear, slope 0.934, intercept 0.793, r 0.838, RMSE 0.528, no warnings. Files `b9/`.

| Species | Remake raw | Candidate raw | Remake mapped | Candidate mapped |
|---|---|---|---|---|
| Galecrest | 5.3/5.0/5.0 | 5.3/5.0/5.0 | 5.56 | 5.56 |
| Fulgocobra | 5.4/5.4/4.9 | 5.4/5.5/5.0 | 5.68 | 5.74 |
| Voltarach | 5.6/5.3/5.2 | 5.6/5.3/5.2 | 5.81 | 5.81 |

All judges: the dark-body, small-face and flat-material defects are PRESENT on both sides; the strips are too small for the face change to read. Their top asks: a lighter stage plus a rim light (the stage is the fixed camera set, so it is not ours to change), and new art with lighter designed colour blocks, bigger eyes and surface grain.

## Batch b10 (22 Oct ~17:20 CT): installed-model value lift + rim on the dark palettes (corrected owner-style prompt)

Candidate: species.json `field_emission` (albedo multiply) + `field_rim`: Tanglevolt 1.45/0.25, Voltarach 1.5/0.25, Galecrest 1.35/0.25; Fulgocobra through its finish row (base_value_scale 0.85 -> 1.3, rim 0.25). Stage tool, installed clips. Anchors npc C1, capacitor r3, craft, gap C3. Fit linear slope 1.081, intercept 0.333, r 0.881, RMSE 0.581, no warnings. Files `b10/`.

| Species | Live raw | Cand raw | Live mapped | **Cand mapped** |
|---|---|---|---|---|
| Galecrest | 5.0/5.0/5.0 | 5.8/6.0/6.2 | 5.73 | **6.82** (ON) |
| Tanglevolt | 5.0/5.0/5.3 | 5.6/5.8/6.0 | 5.84 | **6.60** |
| Fulgocobra | 5.4/5.4/5.5 | 5.4/5.4/5.6 | 6.20 | 6.24 |
| Voltarach | 5.2/5.3/5.6 | 5.2/5.6/5.5 | 6.13 | 6.20 |

Asks: eyes/faces unreadable on all four; Tanglevolt's belly-up faint reads as a white slab; Fulgocobra's faint end rears like an attack; Voltarach's faint is a modest crouch.

## Batch b11 (22 Oct ~17:40 CT): hit/faint recipes on installed models (corrected prompt): all five >= 6.7

Candidate: `f36_pose_postpass.py --candidate-1022` + `f36_arachnid_profile.py --candidate-1022` (held shove hit gain 1.5 to 0.97; Mirejaw side topple; Voltarach doubled rear + side-tip faint; Meadowhart prone + head laid -45). Base: live recipes, both via the stage tool's `--candidate` preview. Anchors capacitor r3, craft, f04_6_r22, npc C1. Fit linear slope 0.894, intercept 1.403, r 0.849, RMSE 0.645, no warnings. Files `b11/`.

| Species | Live mapped | **Cand mapped** | Hit / faint defects (cand, x3) |
|---|---|---|---|
| Staticub | 6.17 | **7.27** | hit FIXED; faint PARTIAL |
| Meadowhart | 6.77 | **7.09** | hit FIXED; faint PARTIAL/FIXED |
| Sparkit | 6.62 | **7.06** | hit FIXED; faint FIXED |
| Voltarach | 5.93 | **7.03** | hit FIXED; faint FIXED (roll-over reads as down) |
| Mirejaw | 5.81 | **6.77** | hit FIXED; faint FIXED; floor sink PARTIAL |

Landed as live recipes only for the judged species: `LANDED_1022_SHOVE` (Sparkit, Staticub, Mirejaw; Mirejaw back to the side topple) and the arachnid profile's doubled rear + side-tip faint, with Voltarach now in `enabled_species` (the runtime plays a profile only for enabled species). The regenerated file changes exactly those four profiles, each byte-equal to the judged candidate rows. Meadowhart is held for a separate decision (the GPU rejected its earlier recipe).

## Batch b12 (22 Oct ~17:45 CT): stronger Tanglevolt lift; Stormcapra/Stormursa lift: no gain

Candidate: `field_emission`/`field_rim` Tanglevolt 1.8/0.30, Stormcapra 1.3/0.25, Stormursa 1.3/0.25. Fit linear slope 1.037, intercept 0.443, r 0.920, RMSE 0.379, no warnings. Files `b12/`.

| Species | Live mapped | Cand mapped | Note |
|---|---|---|---|
| Tanglevolt | 6.14 | 6.32 | 1.8 reads as over-saturated plastic violet; 1.45 (b10, 6.60) stays the best |
| Stormursa | 6.21 | 5.45 | the multiply pushes its veins to garish magenta: dropped |
| Stormcapra | **6.73** | 6.59 | live already >= 6.7 CPU on the stage |

All judges: the bar creatures' hits read as standing, and their faints are belly-up flips (Tanglevolt, Stormcapra) or never go down (Stormursa). Next: hit/faint recipes for the bar creatures.
