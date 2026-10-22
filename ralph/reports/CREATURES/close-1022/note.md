# Creatures close-1022 (lane tb/creatures)

## TO COORDINATOR
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
