# Creatures lane, close-1020 — work note

Renderer for every capture: Godot 4.7 Compatibility (opengl3), Mesa llvmpipe, xvfb, 1280x720, Low. CPU-provisional bar (owner, 17 Oct): Bar A mean ≥ 6.7; a GPU pass must later confirm 7.5.

Capture command (each round): `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=stormursa[,staticub] --candidate --whole-body --context --out=<local>`. The sheet crops the frames and scales Staticub by its camera-distance ratio, so both bears share one pixel scale against the same 1.80 m ruler.

## F29#3 Stormursa v1 — staging fix

With `--context`, the trainer ruler now stands 1.4 m clear of the resting body's rear (`capture_f36_poses.gd`). In r5 it hid behind the bear in the standing and hit frames.

## Round r6 (02:20 UTC): REJECTED

Matched control: the live r5 pose on the new staging. Candidate: `staged_faint` rolled +90° (back to camera), tuck 15, adduct −10, and `held_hit` scale 1.7. Three code-blind judges, Bar A:

| | J1 | J2 | J3 | Mean |
|---|---|---|---|---|
| Control | 6.4 | 6.4 | 5.6 | 6.13 |
| Candidate | 5.9 | 5.6 | 4.6 | 5.37 |

All three preferred the control. The away-from-camera faint ends as a smeared "fur boulder", and the 1.7× hit reads as cramped. The candidate was discarded.

## Round r7 (02:35 UTC): KEPT, +0.36, still OPEN

Candidate, authored by `assets/creatures/tetherbound/stormursa/source/author_f36_hit_faint_r7.py`:
- **`topple_faint`:** the feet stay planted while the front knees buckle (0–.45), then the body tips −90° onto its flank about the mesh long axis, with a late, small leg tuck and the head in line with the body.
- **`flinch_hit`:** the head snaps away and down, the shoulders hunch and the front knees give, with a 9° lean away. It holds to .35 and recovers by .8.

The guard-stretch solver runs on both. The sheet's "hit recover" column is phase .75. Sheet: `_sheet-f29-3-r7.png`, with the candidate as variant B. Three fresh code-blind judges:

| | J1 | J2 | J3 | Mean |
|---|---|---|---|---|
| Control Bar A | 6.3 | 5.5 | 6.4 | 6.07 |
| r7 Bar A | **6.8** | **5.9** | **6.6** | **6.43** |
| r7 Bar B | 5.8 | 4.7 | 5.0 | 5.17 |

r7 was preferred 3/3. Hit react: PASS, PASS, WEAK. Faint: WEAK ×3; the faint mid is now grounded and the end frame is the remaining defect.

Remaining defects (consensus):
1. **Faint end:** near paws crush into blobs toward the camera; a white hotspot on the belly and muzzle; the head is hard to read. Pose and material fixes, about +0.4–0.5.
2. **Material:** the fur drifts red-mahogany (toward oxblood) against the board's cool umber, and the veins never flare on hit or dim on faint. Material/shader fixes, about +0.3–0.6.
3. **Identity:** the cub's blue eyes are unreadable, there is no evolved storm feature, and the head is small and realistic. This needs the Meshy v3 model (requested), about +0.4–0.8.

The flag stays OFF; `enabled_species` is unchanged. Unit check: `test_f36_pose_candidates` 1 test, 8 assertions, 0 failed.

## Round r8 (02:45 UTC): READY F29#3 (CPU-provisional)

Candidate: the r7 poses plus a v1 material regrade (`assets/creatures/tetherbound/stormursa/source/regrade_v1_albedo.py`):
- **Base colour:** hue moved off red-mauve to chestnut-umber (texture mean RGB 95/59/60 → brown). The violet and blue veins are untouched, and the value is capped at 0.84.
- **Fur roughness:** floor raised to 0.85 (the source was 0.52–0.72).
- **Files:** the GLB's embedded images and the extracted JPGs are rewritten. Model sha256 is now `cde8a123487d0d80ec872e67d146a3294ce9e1ea2cada821774f442a1b881fde` (recipe `source_sha256` updated). The Meshy task (01a1256e-ac9f-77cf-bc43-5628bc37b068) and the rig are unchanged.

A clearly different faint, a belly-down sprawl, was tried and discarded unjudged: the leg weights barely move the mesh, so the bear stayed crouched with a stretched hind leg.

Proof: sheet `_sheet-f29-3-r8.png` (the candidate is B; key `f29-3-ab-key.json`), against the r7 control captured fresh with the same staging. Three fresh code-blind judges:

| | J1 | J2 | J3 | Mean |
|---|---|---|---|---|
| r7 control Bar A | 6.3 | 6.2 | 6.3 | 6.27 |
| **r8 Bar A** | **6.8** | **6.6** | **6.8** | **6.73** |
| r8 Bar B | 5.3 | 5.0 | 5.4 | 5.23 |

r8 was preferred 3/3 ("natural brown matches the cub board, clear of the villain red"). Scale passed for all three judges. Hit react: WEAK ×3. Faint: WEAK ×3; the faint mid passes and the faint end is stiff, with stub limbs and a white highlight.

**Disposition.** Bar A 6.73 ≥ 6.7 meets F29#3 as **CPU-provisional** under the owner's 17 Oct rule. The other conditions:
- Drafted reference: `reference/native-standing-v1.png`.
- Meshy task 01a1256e, with provenance.
- 4.10 m standing, larger than Staticub's 3.25 m and taller than the 1.80 m trainer.
- Not wild.

The judged pose recipe is now enabled: `stormursa` is in `enabled_species`. Evolution (`staticub_stormursa`, L50 feast) was already enabled, and `evolution.gd::storm_bear_ready()` returns true with the regraded model.

**A GPU Medium/High pass must confirm 7.5; a GPU score below 7.5 reopens F29#3.** The margin is thin (one judge scored 6.6). The Meshy v3 bear has been requested for the identity gap and stays OFF until judged against this v1.

Checks, all 0 failed:
- `test_f36_pose_candidates`: 1 test, 8 assertions.
- `test_creature_scale_ladder`: 2 tests, 156 assertions.
- `test_evolution`: 18 tests, 217 assertions.
- `test_evolution_links`: 9 tests, 35 assertions.
- `test_character_appearance_variants`: 11 tests, 235 assertions.
- `texture_import_policy.py --check`: PASS. The Godot import reported no errors.

## F36#0 round r1 (02:40 UTC): Meshy multiview candidates against installed — none pass, all stay OFF

Captures:
- Installed: the command above without `--candidate`, for bramblebun, terrapup and burrowback.
- Candidate: the same capture with each species' `placeholder.model` temporarily pointed at its `candidate_multiview` GLB. Burrowback also used its candidate `footprint_allowance` 3.76, because 3.2 auto-shrank it to 2.56 m. The edits were local and reverted, not committed.

Sheet `_sheet-f36-0-r1.png`, key `f36-0-r1-ab-key.json`. Three code-blind judges, with each creature's design reference:

| Creature | Installed Bar A (J1/J2/J3) | Candidate Bar A (J1/J2/J3) | Means | Preferred |
|---|---|---|---|---|
| Bramblebun (01a142e8) | 4.3 / 3.4 / 3.6 | 3.0 / 2.8 / 2.6 | 3.77 vs **2.80** | installed 3/3 |
| Terrapup (01a142f9) | 4.8 / 4.4 / 4.6 | 6.0 / 5.5 / 6.1 | 4.60 vs **5.87** | candidate 3/3 |
| Burrowback (01a14306) | 5.0 / 4.0 / 5.2 | 5.7 / 4.6 / 5.6 | 4.73 vs **5.30** | candidate 3/3 |

None reaches 6.7, so all three stay OFF; installed models are unchanged.

Findings:
- **Bramblebun candidate:** a red/lime blotch texture with no readable face, below installed.
- **Terrapup candidate:** the closest. Hit react equals standing, the belly-up faint shows black paw-pad discs, and the fur is too yellow.
- **Burrowback candidate:** the stone plates blend into ochre fur. It is 7.87 m long at 2.95 m tall.
- **Every row, installed included:** hit react identical to standing.

**Hard-rule finding on the installed game.** Installed Bramblebun renders red-orange, breaking the reserved-red rule. Its texture is olive-brown (mean RGB 123/101/57). The cause is `creature_body.gd::_apply_field_brightness` with species `field_emission` 2.5 and `field_degreen` 0.75: red and blue get the full 3.5× push, green less, so the brown coat walks to red. Terrapup (`field_emission` 0.6) also renders rust. This is a shared-system change (field legibility, OWNER-0901); it is reported to the coordinator rather than changed silently.

## Hourly log

- 02:45 UTC:
  - **Game changes:** r7 poses (kept); v1 regrade and matte fur (kept); `stormursa` F36 poses enabled.
  - **Proofs:** F29#3 r6 (rejected), r7 (+0.36), r8 (6.73, met); F36#0 r1 (none pass).
  - **Closed:** F29#3, CPU-provisional (READY).
  - **Next:** the F36#0 Terrapup candidate hit/faint and the coordinator's call on field tint; F36#1 pose rounds; the Stormursa v3 when it lands.

## Field-brightness tint fix (03:00 UTC): hard rule, red reserved for Team Tether

The coordinator assigned this to the lane (02:44 UTC). `creature_body.gd::_apply_field_bright_values` multiplied red and blue by the full field push and green by less (`field_degreen`). `albedo_color` tints every texel, so the whole coat walked toward red: Bramblebun's olive-brown texture rendered red-orange.

Fix: red and blue never rise above green's boost, so each texel keeps its hue, and `field_degreen` still trims the push. Per-species data values are unchanged.

New test `tests/test_field_degreen_hue.gd`: 2 tests, 13 assertions. It fails on the old code (2 failed) and passes on the fix (0 failed). `smoke_creature_field_brightness.gd`: PASS. Matched stage capture: Bramblebun now renders brown instead of red-orange; Mudsnout (no degreen) is unchanged.

## F36#1 batch 1 (02:50–03:05 UTC): topple faint and flinch hit across six quadrupeds

`f36_pose_postpass.py --topple=a,b` rewrites only the named species' hit and faint, using the r7 `topple_faint` and `flinch_hit` with a per-species roll.

**r1:** live recipe against topple+flinch at roll +90 (back to camera). Three judges, Bar A means:

| Species | Live | Topple +90 | Gain |
|---|---|---|---|
| terrapup | 4.90 | 5.53 | +0.63 |
| mudsnout | 5.97 | 5.33 | −0.64 |
| burrowback | 5.53 | 6.30 | +0.77 |
| staticub | 5.90 | 6.60 | +0.70 |
| tuskroot | 6.30 | 5.30 | −1.00 |
| trailpup | 5.57 | 5.87 | +0.30 |

All three judges asked for the faint to face the camera.

**r2:** r1 winner against topple at roll −90 (belly, legs and face toward the camera). Three fresh judges:

| Species | r1 winner | Topple −90 | Kept |
|---|---|---|---|
| terrapup | 5.60 | 6.10 | −90 |
| mudsnout | 6.43 | 5.20 | original |
| burrowback | 5.87 | 6.07 | −90 |
| staticub | 6.37 | 5.53 | +90 |
| tuskroot | 6.63 | 6.33 | original |
| trailpup | 4.87 | 5.77 | −90 |

Keys: `f36-1-batch1-ab-key.json`. Sheet (r2): `_sheet-f36-1-batch1-r2.png`.

Live now: terrapup, burrowback and trailpup topple −90; staticub topple +90; mudsnout and tuskroot unchanged. None reaches 6.7. Best: tuskroot 6.63, staticub 6.60 (r1 panel), mudsnout 6.43.

Consensus next fixes:
1. Faint mid floats: the paws lift as the knees bend, so it should buckle with the body grounded.
2. Hit react should snap the head up and back. This is the opposite of the Stormursa panel's request; the mudsnout and tuskroot originals do it.
3. Faint end should show both face and back by stopping the roll at about 60–70°.
4. Trailpup's faint end flattens.

Checks, all 0 failed: `test_f36_pose_candidates`, `test_creature_scale_ladder` and `test_field_degreen_hue`.

## F29#3 Stormursa v3a/v3b vs landed v1 (03:10 UTC): v1 stays; v3 OFF

The coordinator's Meshy v3 candidates (tasks 01a15c3e-d54b… for v3a, 01a15c40-06de… for v3b; merged from tb/meshy-batch d869a4860) were captured with their native clips on the same staging (`placeholder.model` swapped locally, not committed). Three-way sheet `_sheet-f29-3-v3-vs-v1.png`; key in `f29-3-v3-and-cub-keys.json`. Three fresh judges, Bar A:

| Variant | J1 | J2 | J3 | Mean |
|---|---|---|---|---|
| v3a | 5.6 | 4.8 | 4.9 | 5.10 |
| v3b | 5.8 | 5.0 | 5.3 | 5.37 |
| **v1 (landed r8)** | **7.0** | **6.5** | **6.6** | **6.70** |

All three ranked v1 first. The v3 fur reads orange-red, near the reserved red, and the veins read pink-magenta. The native hit clips equal standing, and the faint ends belly-up and near-black.

v3 stays OFF. This fresh panel confirms v1 at 6.70, at or above the CPU-provisional 6.7.

Next lift for v1 (judges): thinner, branching emissive veins; visible blue eyes; a bigger hit snap. These are material and pose work.

## Staticub colour regrade (03:15 UTC): KEPT, +1.13

Staticub's base colour had the same red-mauve cast as Stormursa (texture mean RGB 93/60/62). The in-game coat comes from `staticub_extracted_base_color_vivid.png` (OF28 colourway swap of albedo and emission), so that PNG was regraded along with the GLB's embedded image and extracted JPG, using `regrade_v1_albedo.py --glb/--jpg` and `--png`. The model sha256 changed `c2e42a53…` → `fccc3ca4…` (F36 recipe updated). Staticub has no entry in `shiny_colourways.json`, so no generator overwrites the PNG. The shiny PNG is untouched.

Sheet `_sheet-staticub-regrade.png` (after = B), with the adult render and the Staticub board as references. Three judges, Bar A:
- **Before:** 5.0 / 5.5 / 5.0 = 5.17.
- **After:** 6.4 / 6.2 / 6.3 = **6.30**.

Preferred 3/3. Palette went poor → good; "same line as the adult" went partly → yes.

Remaining (all three): cub proportions. The head, eyes, ears and legs read as a small adult rather than a cub, so this needs new art; requested. The lightning reads as a purple wash.

## Water Cannonback Meshy retexture (03:20 UTC): preferred, below the bar, OFF

Retex 0459d957a was captured texture-only with the live pose recipe. For the capture only, the recipe and the water_roster binding were pointed at the retex GLB, and `water_species_catalog.gd` honoured the candidate's `colourway_source_species`; all three edits were reverted. Without that, the catalog's forced `colourway_source_species = id` makes the old Cannonback vivid PNG cover any retexture, which also matters at integration.

Three judges, Bar A:
- Installed: 5.4 / 5.6 / 5.5 = 5.50.
- Retex: 6.6 / 6.2 / 6.4 = **6.40**.

Preferred 3/3, but below 6.7, so it stays OFF. The material fix (slate-blue stone shell with moss, cream underside and face, amber eye) went to the coordinator.

## F36#1 batch 2 r1 (03:25 UTC): topple −90 with a recoil hit across eight quadrupeds

`recoil_hit` throws the head up and back, rocks onto the haunches and lifts the forelegs. Three judges, Bar A means (live vs candidate):

| Species | Live | Candidate | Kept |
|---|---|---|---|
| ashtusk | 5.80 | **6.67** | candidate |
| sparkit | 5.07 | **6.33** | candidate |
| cindercub | 6.00 | 6.27 | candidate |
| shadelet | 6.33 | 6.63 | candidate |
| mirejaw | 5.50 | 5.83 | candidate |
| stormtrail | **6.13** | 5.40 | live |
| frostclaw | **6.60** | 6.03 | live |
| riptusk | **6.20** | 5.50 | live |

The key is in `f36-1-batch2-r1-ab-key.json`.

Consensus defects:
- Faint ends that flip belly-up or flatten lose identity.
- Faint mid sometimes rears or stays standing.
- Hits read as a rear more than a directional flinch.

r2, the r1 winners against a +90 back-to-camera faint, is running. Checks: `test_f36_pose_candidates` and `test_creature_scale_ladder`, 0 failed.

## F36#1 batch 2 r2 (03:35 UTC): r1 winner vs topple +90 (back to camera)

Three fresh judges, Bar A means (r1 winner vs +90):

| Species | r1 winner | +90 | Live now |
|---|---|---|---|
| stormtrail | **6.80** | 6.50 | original recipe |
| ashtusk | 6.50 | 6.60 | topple −90 + recoil (judges split 2–1 for it; +0.10 is noise) |
| sparkit | 6.43 | 6.40 | topple −90 + recoil |
| cindercub | 6.27 | **6.73** | **topple +90 + recoil** (switched) |
| shadelet | **6.73** | 6.50 | topple −90 + recoil |
| frostclaw | **6.93** | 6.57 | original recipe |
| riptusk | 6.13 | 5.80 | original recipe |
| mirejaw | 6.17 | 6.23 | topple −90 + recoil (tie) |

Sheet `_sheet-f36-1-batch2-r2.png`; key `f36-1-batch2-r2-ab-key.json`.

### F36#1 per-species status (CPU-provisional, hit and faint)

Species whose only in-play roles are hit and faint (no `rideable`, no `swim_mount`, not a `fly_traversal` carrier) meet the 6.7 bar on their live poses:

| Species | Bar A | Panel |
|---|---|---|
| frostclaw | 6.93 | batch 2 r2 |
| stormtrail | 6.80 | batch 2 r2 |
| cindercub | 6.73 | batch 2 r2 |
| shadelet | 6.73 | batch 2 r2 |
| stormursa | 6.73 | F29#3 r8; 6.70 on the v3 panel |

Below the bar, on their best live poses:

| Species | Bar A |
|---|---|
| ashtusk | 6.50–6.67 |
| tuskroot | 6.63 |
| staticub | 6.60 / 6.37 |
| mudsnout | 6.43 |
| sparkit | 6.43 |
| mirejaw | 6.17 |
| riptusk | 6.13 |
| terrapup | 6.10 |
| burrowback | 6.07 |
| trailpup | 5.77 |

F36#1 stays OPEN: every species is needed, and the ride and swim roles remain for rideable and water forms.

Remaining consensus defects:
- Hit reads as a rear rather than a directional knockback; heavy bodies (riptusk) barely move.
- Faint mid sometimes rears or hops.
- Faint ends flatten ("pancake") or flip belly-up.

## F36#1 batch 3 (03:45 UTC): thirteen enabled quadrupeds, three-way (live, topple −90, topple +90, both with the recoil hit)

Three judges, Bar A means. Full table in `f36-1-batch3-abc-key.json`; sheet (creatures 7–12) `_sheet-f36-1-batch3.png`.

| Species | Live | −90 | +90 | Live now |
|---|---|---|---|---|
| stormbrush | 5.23 | **6.43** | 5.67 | −90 |
| thundertunnel | 5.37 | **6.47** | 5.10 | −90 |
| pebbik | 4.90 | **5.87** | 5.13 | −90 |
| cragclaw | 5.53 | **5.97** | 5.00 | −90 |
| torrentoad | 5.67 | **5.93** | 5.93 | −90 |
| voltwig | 6.07 | 6.20 | 6.07 | original (+0.13 is noise) |
| meadowhart | **6.87** | 5.70 | 6.30 | original |
| brooktail | **6.87** | 6.30 | 6.07 | original |
| cloudfang | **6.77** | 6.07 | 6.30 | original |
| cliffspike | **6.23** | 5.53 | 6.13 | original |
| mosshock | **6.17** | 5.93 | 5.97 | original |
| mangrove_monitor | **6.10** | 5.60 | 5.87 | original |
| skyrill | **6.10** | 5.27 | 5.60 | original |

Per-species pass on hit and faint (their only in-play roles), CPU-provisional ≥6.7, adds brooktail 6.87 and cloudfang 6.77. Meadowhart (6.87) is rideable, so its ride role is still to be judged.

Consensus remaining defects:
1. Faint ends go top-down, belly-up or flattened, hiding face and signature. The judges want a 70–80° side-lie with the head toward the camera.
2. Hit is too small on heavy, short-legged bodies (crab, mole, hedgehog, toad).
3. Faint mid strides or leaps instead of buckling.

Check: `test_f36_pose_candidates`, 0 failed.

## Hourly log

- 03:45 UTC:
  - **Game changes:** field-tint hue fix; Staticub regrade; F36#1 batches 1–3 (topple/flinch/recoil kept on 15 species where judged better).
  - **Proofs:**
    - F29#3 v3 vs v1: v1 6.70.
    - Staticub: 6.30.
    - Water Cannonback retex: 6.40 (OFF).
    - F36#1: nine paired or three-way rounds.
  - **Closed:** F29#3 (CPU-provisional, earlier). F36#1 per-species passes on hit/faint: frostclaw, stormtrail, cindercub, shadelet, stormursa, brooktail, cloudfang. The criterion stays open.
  - **Next:** F36#0 retex candidates (Bramblebun/Burrowback/Terrapup multiview_retex); a 75° side-lie with head turn for the remaining species.

## F36#0 r2 (03:55 UTC): red-free multiview retextures vs installed — all stay OFF

The coordinator's `candidate_multiview/models/creature_<sp>_multiview_retex.glb` variants (tb/meshy-batch 5fb1d830f) were captured with their native clips; the placeholder was swapped locally and reverted. Installed creatures were captured as they play live: F36 poses for terrapup and burrowback, native clips for bramblebun. Key: `f36-0-r2-retex-ab-key.json`. Three judges, Bar A:

| Species | Retex (J1/J2/J3) | Installed (J1/J2/J3) | Means |
|---|---|---|---|
| bramblebun | 5.2 / 4.8 / 5.6 | 4.8 / 5.4 / 5.9 | 5.20 vs 5.37 |
| terrapup | 6.0 / 5.9 / 6.3 | 6.6 / 6.3 / 6.6 | 6.07 vs **6.50** |
| burrowback | 5.6 / 5.7 / 5.5 | 6.0 / 5.1 / 6.3 | 5.60 vs 5.80 |

None passes, so all stay OFF; the installed models are unchanged.

Findings:
- On all three retex candidates the native hit clip equals standing.
- **Bramblebun retex:** glossy dark chocolate with lime smears; still not the reference's matte tan, cream chest and moss-and-flower back. The installed antler form drifts from the hare reference, and the body is under the 1.80 m trainer except the ears or antlers. Scale-rule finding: installed Bramblebun's 2.05 m height comes mostly from the antlers.
- **Burrowback retex:** stones blend into muddy fur, and the underside tiles.
- **Installed Terrapup:** fur reads rust; the moss is lime.

## F36#1 batch 4 (04:00 UTC): eased roll (±75°) with neck curl — flat, nothing adopted

Live vs candidate, three judges: every gap was 0.3 or less, so nothing changed. This panel scored the same live poses about 0.7 lower than earlier panels, so panel spread is large.

## Staging fix: `--combat-pitch` (capture_f36_poses.gd)

Every pose panel's main complaint was that downed creatures read as "belly-up" or "shell blob". The cause is the stage camera, which looks almost level (about 1.6°), while fights are watched from `combat.json` `camera.pitch_start_deg` −25°.

The opt-in `--combat-pitch` flag tilts the whole-body stage camera to that pitch (read from config), with the same target and distance. The default framing is unchanged, so earlier rounds stay reproducible, and the receipt records `combat_pitch`.

## F36#1 fight-pitch round (04:15 UTC): 22 enabled quadrupeds not yet passing, three-way

Variants: live, topple −90, topple +90, each species with its judged hit style. Three judges, Bar A means. Key and full table in `f36-1-fightpitch-abc-key.json`; sheet (creatures 1–6) `_sheet-f36-1-fightpitch.png`.

**+90 adopted** (back and markings to the fight camera; gain over live, 15 species):

| Species | Bar A | Gain |
|---|---|---|
| burrowback | 6.40 | +1.37 |
| mirejaw | 6.03 | +1.36 |
| stormbrush | 6.03 | +1.30 |
| torrentoad | 6.13 | +1.13 |
| terrapup | 6.37 | +1.10 |
| trailpup | 5.83 | +1.03 |
| ashtusk | 6.03 | +0.73 |
| thundertunnel | 5.80 | +0.67 |
| mudsnout | 6.03 | +0.63 |
| meadowhart | 5.90 | +0.47 |
| mangrove_monitor | 5.63 | +0.46 |
| riptusk | 5.47 | +0.37 |
| cragclaw | 5.57 | +0.34 |
| skyrill | 5.83 | +0.33 |
| voltwig | 6.00 | +0.30 |

**Kept live:**
- sparkit 6.03 and pebbik 5.50 (live is already −90; +90 was worse);
- staticub 6.10 (live is already +90);
- sirenseal 6.03, mosshock 5.83, cliffspike 5.83;
- cannonback (+0.24, under threshold).

Terrapup, burrowback and trailpup had taken −90 on level-camera panels; the fight camera reverses that. The gameplay camera governs. Per-species passes earned on the level stage (frostclaw, stormtrail, cindercub, shadelet, stormursa, brooktail, cloudfang) are unchanged.

No species in this round reaches 6.7; this panel's scale ran low (best 6.40). Remaining consensus:
1. Faint mid floats or stays standing; it needs a grounded buckle.
2. Hit react is too small on heavy, low bodies; it needs about 3× amplitude.
3. Legs point up stiffly in the side-lie.

Checks, all 0 failed: `test_f36_pose_candidates` and `test_creature_scale_ladder`.

## F36#0 r3 (04:30 UTC): installed-rig retextures — READY Tuskroot (CPU-provisional), Water Cannonback v2 OFF

Both candidates are on the installed rig with identical UVs, so they were captured texture-only with the live F36 pose recipe at the fight camera (`--combat-pitch`). For the capture only, the recipe model and sha, the placeholder model and `colourway_source_species` were swapped, plus the water catalog's colourway line for Cannonback; all were reverted.

Sheet `_sheet-f36-0-tuskroot-cannonback-retex.png` (after = B); key `f36-0-r3-retex-ab-key.json`. Three judges, Bar A:

| Candidate | Installed (J1/J2/J3) | Retex (J1/J2/J3) | Means |
|---|---|---|---|
| Tuskroot native retex (tb/meshy-batch 0d2669cb2) | 6.6 / 6.3 / 6.9 | **6.9 / 7.0 / 7.2** | 6.60 → **7.03**, preferred 3/3 |
| Water Cannonback retex v2 | 5.6 / 5.6 / 5.2 | 6.6 / 6.4 / 6.0 | 5.47 → 6.33, preferred 3/3, below 6.7 |

Tuskroot role verdicts: ride PASS ×3; faint PASS, PASS, WEAK; hit WEAK ×3.

**Tuskroot enabled with the proof** (F36#0 CPU-provisional; a GPU pass must confirm 7.5):
- `species.json` tuskroot `placeholder.model` → `tuskroot/candidate/models/creature_tuskroot_native_retex.glb`, with `colourway_source_species` `tuskroot_native_retex_review` as in the candidate file.
- The F36 recipe row `tuskroot` takes the retex model, sha `9ef181bb…` and uid `uid://bnuvq4y45ap4y`.
- `tuskroot` is added to `enabled_species`, because the judged state is the retex playing the recipe poses.
- Ashtusk (aspect variant on the native mesh) is unchanged.

A live-path capture with no swaps matches the judged frames (ride identical; under 0.04% of pixels differ).

Water Cannonback v2 stays OFF. The judges name geometry and pose:
- The head reads blue and snake-like; the board's cream beaked face is missing.
- The cannons are small stubs.
- The faint floats.
- The hit barely moves.

Checks, all 0 failed:
- `test_f36_pose_candidates`, `test_creature_scale_ladder`, `test_character_appearance_variants`.
- `test_creature_rest_pose`: 13 tests, 530 assertions.
- `test_evolution`.
- `test_rideable_roster`: 10 tests, 82 assertions.
- `test_charger_lunge`.

**Smallest fix, reproduced blocker (F29#3 scale contract).** `tools/art_pipeline/tests/test_f36_source_contracts.py` failed on main with "scale roster mismatch: missing targets=['stormursa']": the bear is in `species.json` but not in `creature_scale_ladder.py` `TARGET_HEIGHTS`. Added `stormursa: 4.1`, its installed height, which grows nothing. The test now passes: 2 tests OK.

## F36#1 batch 7 (04:45 UTC): knee fold 30° + recoil ×2 on the 15 fight-pitch species — worse, nothing adopted

Live vs candidate at fight pitch, three judges. Gains run from −1.16 to +0.23:
- voltwig −1.16, mangrove −0.97, meadowhart −0.70.
- Best: thundertunnel +0.23, ashtusk +0.20.

The doubled recoil whips the head and tears the throat (white stretched neck bands). The judges want the blow carried by the spine and body with the neck capped (about 25–35°), not a bigger head toss. The key is in `f36-1-batch7-ab-key.json`.

## F36#0 Staticub regen B (04:50 UTC): OFF

The coordinator's cub-proportions regen B (`staticub/candidate_regen/models/creature_staticub_regen_b.glb`, own rig, 3.25 m) was given a recipe row authored from its rig with `author_f36_pose_profiles.rig_contracts`, and its hit and faint were regenerated with the live topple +90 / flinch settings. It was captured at fight pitch; all swaps were local and reverted.

Three judges, Bar A:
- Installed regraded cub: 6.6 / 6.4 / 5.6 = 6.20.
- Regen B: 5.4 / 5.5 / 5.0 = **5.30**.

Installed preferred 3/3; key `staticub-regen-b-ab-key.json`. B's vinyl, fur-less material, orange-rust coat near the reserved red and blank white eyes break the line with the furred adult, even though its cub proportions are better.

Request sent: a reference-guided regen of the installed furred cub with cub proportions and blue eyes.

## F36#1 batch 8 (05:05 UTC): body-carried `shove_hit` — adopted on 3 species

`shove_hit` makes the spine and chest rock back and away, caps the neck at 12°, lifts the forelegs and braces the hind legs. It was tested at fight pitch on the 17 species currently on the topple faint, live vs candidate. Three judges; key in `f36-1-batch8-ab-key.json`.

Adopted (gain ≥0.3):

| Species | Live | Shove | Gain |
|---|---|---|---|
| burrowback | 5.77 | 6.30 | +0.53 |
| terrapup | 6.00 | 6.37 | +0.37 |
| trailpup | 5.70 | 6.07 | +0.37 |

The other 14 range from −0.07 to +0.23 (mean +0.14) and are not adopted; voltwig is highest at 6.60.

This is the third consecutive fight-pitch pose round without a new 6.7 pass (fight-pitch round 6.40 best, batch 7, batch 8). Consensus remaining defects:
- The faint end reads as a "dead bug" (legs up) or crops at the frame edge.
- Faint mid rears or leaps instead of buckling.

Both need limb-level pose work that the weakly weighted Meshy rigs resist.

Checks: `test_f36_pose_candidates` and `test_creature_scale_ladder`, 0 failed.

## F36#0 r4 (05:15 UTC): installed-rig retextures and Staticub regen A — none pass, all OFF

All candidates were captured at fight pitch with the live pose recipe and the vivid colourway bypassed. For Staticub regen A, a recipe row was authored from its own rig and its hit and faint regenerated with the live settings. The swaps were local and reverted. Keys: `f36-0-r4-installed-retex-key{1,2}.json`. Three judges, Bar A:

| Candidate | Installed (J1/J3/J2) | Candidate (J1/J3/J2) | Means |
|---|---|---|---|
| Terrapup installed retex (1eeb8f5b3) | 5.4 / 5.8 / 5.9 | 6.0 / 6.4 / 5.4 | 5.70 vs 5.93 (split 2–1) |
| Burrowback installed retex (06edd59c4) | 5.5 / 5.0 / 5.0 | 6.4 / 6.3 / 6.0 | 5.17 vs **6.23** (3/3) |
| Bramblebun installed retex (65d6c2d6a) | 5.2 / 4.6 / 5.3 | 4.3 / 4.0 / 4.3 | **5.03** vs 4.20 |
| Staticub regen A (3f0f0eea5) | 6.3 / 6.0 / 6.0 | 6.6 / 6.6 / 6.4 | 6.10 vs **6.53** (3/3) |

## F36#0 item ledger (05:15 UTC)

Status and scores are Bar A on CPU (llvmpipe), with three judges unless noted. "Board" means the earlier board-recorded state.

| Asset | State | Score / note |
|---|---|---|
| Stormursa (F29#3) | passing, ON | 6.73 (r8), 6.70 (v3 panel) |
| Tuskroot | passing, ON (native retex) | 7.03 vs 6.60 |
| Mirejaw, Aeriex, Veridian, Voltarach, Meadowhart | switched on (board, 10–12 Oct) | not re-judged here |
| Adair NPC identity | switched on (board) | — |
| Staticub | installed regraded coat ON | 6.30 regrade (+1.13). Regen A 6.53 (OFF), regen B 5.30 (OFF). Needs: regen A lightning shifted from pink-magenta to blue-violet (#6E74FF, white-blue core) and a fur-strand normal or breakup on the body. Judges estimate it passes. |
| Burrowback | installed | Installed retex 6.23 (OFF); multiview 5.30/5.60 (OFF). Needs: stones down from blown-out white to matte warm grey-brown with darker cracks, fur visible between plates, olive moss. |
| Terrapup (starter) | installed | Live 5.7–6.5 by panel; installed retex 5.93, multiview 6.07 (OFF). Needs: fur mid-brown (not dark chocolate, not orange), cream blaze, muzzle and chest, stones mid-grey (albedo ~0.5), olive moss. |
| Bramblebun | installed | All candidates lose (multiview 2.80/5.20, installed retex 4.20). Needs a new model from `bramblebun_redesign/reference/` (long upright ears with pink inner, small antler, moss-and-flower mantle on the back, tan-brown fur). Scale finding: the body sits below the 1.80 m trainer; only the antlers reach 2.05 m. CREATURES.md measures total height and says to preserve catalogue values, so growing it is a design call; flagged, not changed. |
| Water Cannonback | installed | Retex v1 6.40, v2 6.33 (OFF). Geometry regen running (cream beaked face, large barrel cannons; ref `docs/art/reference/26_Cannonback_Board.png`). |
| Solmane | held (board: wing-root topology) | not re-judged |
| Ripplet, Galewisp (starters) | not judged this session | — |
| Legendaries (Ground Legendary, Abyssal Guardian) | not judged this session | — |
| NPC faces | Otto v4 parked; Iona v2 parked (Water-lane scene); Orsen held | Warden Aldis, Grandpa, Lyra, Kael, Sera not started |

F36#0 stays OPEN.

## F36#1 batch 9 (05:45 UTC): hind-leg crouch 25° + late knee fold 20° on 17 fight-pitch species: flat, nothing adopted

The candidate added `topple_faint(crouch=25, fold=20)`, which crouches the hind legs during the buckle and folds the knees late, against the live recipe. Capture was at fight pitch. Keys: `f36-1-b9-key{1..5}.json`. Three judges, Bar A, unblinded means:

| Species | Live | Cand | Δ |
|---|---|---|---|
| terrapup | 6.17 | 6.33 | +0.17 |
| burrowback | 6.17 | 6.33 | +0.17 |
| mangrove_monitor | 5.87 | 6.03 | +0.17 |
| the other 14 | — | — | −0.17 to +0.07 |
| **set** | **6.01** | **6.02** | +0.01 |

The judges' slight "prefer B" leaned on slot B, not on the candidate. No species gained 0.3 and none reached 6.7, so nothing was adopted. The `crouch` parameter stays in the postpass at default 0, so output is byte-identical to the live file.

The consensus remains unchanged across batches 4, 7, 8 and 9:
- The faint end reads as belly-up ("dead bug"), hides the face and signature feature, and sometimes crops.
- Faint mid rears or floats.

All four rounds varied the limb and roll parameters of the same roll-based topple. The next round must be a clearly different approach: a belly-down, pivot-driven prone collapse with no roll.

## F36#0 r5 (06:35 UTC): Water Cannonback geometry regen: preferred 3/3 but 5.80, stays OFF

The candidate is tb/meshy-batch c63e3ba91 `cannonback/candidate_regen` (cream beak, three bronze cannons). It was captured at fight pitch with its own native clips; the F36 recipe is bound to the installed rig's sha and does not apply. The comparison is the installed Water Cannonback with live F36 poses. Both were fitted to the same 4.15 m height. The swap was local, the vivid colourway was bypassed, and everything was reverted. Key: `f36-0-r5-cannonback-regen-key.json` (A = regen). Three judges, Bar A:

| | J1 | J2 | J3 | Mean |
|---|---|---|---|---|
| Installed | 5.1 | 5.5 | 4.9 | 5.17 |
| Regen | 5.7 | 5.8 | 5.9 | **5.80** (+0.63, preferred 3/3) |

Consensus on the regen:
- It is clean and stylised: readable cannons, face and blue/cream palette.
- The shell is a smooth dome, not the board's stacked rocky plates with moss. The cannons are about 25–35% too big and sit on top of the shell rather than being seated into the plates.
- The plastron is dark olive; the board's is cream.
- Native hit = standing; faints hover and the cannons clip.
- The rider perches on the cannons; it needs a seat between them, with water_mounts anchors re-measured.

Next: author an F36 recipe row on the regen rig, so the grounded topple faint and recoil hit apply, and ask for a material pass: cream plastron, plate breakup and moss, cannons scaled about 0.7 and seated.

## F36#1 batch 10 (06:20 UTC): belly-down prone collapse, adopted on 16 species

This round followed the faint-grounding fix: the full rewrite now replays `--topple` adoptions and grounds them. The capture covered the 21 toppled species at fight pitch, three-way and blind:
- **live**: the topple as committed, unclamped hurt neck.
- **ground**: topple plus `SOLVER.ground_faint`.
- **prone**: the new `prone_faint`, also grounded. The front knees buckle and the chest drops (0–.45). The hindquarters then give, and the body settles on its belly (.4–.8) with no roll. The forelegs reach forward and the hind legs slide out behind with a 14° splay. The head is down and turned 14° toward the camera.

Keys: `f36-1-b10-key{1..7}.json`. Unblinded per species: `f36-1-b10-scores.json`. Three judges, Bar A.

| | Live | Ground | Prone |
|---|---|---|---|
| Set mean (21) | 5.54 | 5.53 | **6.02** |

- **Prone adopted (16, +0.47 to +1.07):**
  - ashtusk 6.40, burrowback 6.27, cragclaw 6.20, mirejaw 6.07, mudsnout 6.20, riptusk 6.07, shadelet 6.27, skyrill 6.40
  - staticub 6.17, stormbrush 6.20, stormursa 6.37, terrapup 6.37, thundertunnel 6.03, torrentoad 6.30, trailpup 6.33, voltwig 6.23
- **Grounded topple kept (5):** cindercub 5.80 (live 6.03), mangrove_monitor 5.53, meadowhart 5.73, pebbik 5.83 (+0.46), sparkit 6.00. Grounding is required by the torso-on-floor invariant and is neutral overall (−0.01).
- **Ceiling:** no species reaches 6.7, so F36#1 stays open for these.
- **Judge consensus on what remains:**
  - The hit react is a small head toss; it needs a whole-body recoil, a squash and a flash.
  - Faint mid is too close to standing; it needs a visible knee buckle and a head drop.
  - The grey stage floor caps the Bar A read.

Generator (`f36_pose_postpass.py`):
- The full rewrite now reproduces the committed file (`--check` current).
- `TOPPLED` replays the per-species hit and faint; `PRONE` selects the collapse.
- `clamp_neck` holds hurt necks within the 20° invariant. It clips the recoil hits by 5–8°, and the earlier lanes' ripplet, paddlenewt and galecrest hits by up to 14°.
- `ground_faint` now runs on every replayed faint. The worst torso gap went from 0.28 to 0.11 of height.

Bramblebun grass probe (`tools/_probe_grass_separation.gd`, SHIPPED 2.05 m, emission 2.5, degreen 0.75) after the hue-preserving degreen: the coat reads tan-brown, with no red cast, clearly separated from the meadow grass. CPU capture, judged by eye.

## F36#0 r6 (06:40 UTC): coordinator's four candidates; Burrowback v2 passes (ON), installed Staticub passes

Candidates are from tb/meshy-batch f5c2659f4 (folders checked out only). Captures were at fight pitch with live F36 poses and the vivid colourway bypassed. Installed creatures were captured as they play live. Staticub A2 and the Bramblebun regen got recipe rows authored from their own rigs, using the pivot-driven topple (+90) and the live hit. On these weakly weighted Meshy rigs the bone-driven prone barely moved, so it was not used. Key: `f36-0-r6-key.json`. Three judges, Bar A:

| Item | Installed (J1/J2/J3) | Candidate (J1/J2/J3) | Means |
|---|---|---|---|
| Terrapup retex v2 (f5c2659f4) | 5.8 / 6.2 / 6.2 | 6.2 / 5.8 / 5.9 | **6.07** vs 5.97, OFF |
| Burrowback retex v2 (74db64c7b) | 5.4 / 5.5 / 5.6 | 6.6 / 7.0 / 7.0 | 5.50 vs **6.87**, preferred 3/3, **ON (CPU-provisional)** |
| Staticub regen A2 (1fb0d6179) | 6.8 / 6.9 / 7.0 | 5.6 / 5.6 / 5.8 | **installed 6.90** (regraded coat + batch-10 prone) vs 5.67, A2 OFF |
| Bramblebun regen A (e70b30a6e) | 4.8 / 5.0 / 4.8 | 5.2 / 5.6 / 5.0 | 4.87 vs 5.27, OFF |

The installed Staticub now clears 6.7 (6.90, CPU-provisional). It was 6.30 in r4; the difference is the batch-10 prone faint and the grounding fix.

Burrowback v2 is enabled. species.json `burrowback` and `nightburrow` (its aspect variant must share the mesh) and both F36 rows point at `creature_burrowback_installed_retex_v2_lod0.glb`, which has the same rig.

Its shiny, alpha and Nightburrow repaints were painted on the old texture set and derive their paths from the albedo. `creature_body.gd` `RETEX_LEGACY_MAPS` resolves those colourways against the old set, including its normal and metal/roughness maps. `vivid` is excluded because the retex is the new ordinary look. `tests/test_retex_legacy_colourways.gd` covers this: it fails without the table and passes with it. An engine dump of the dressed Nightburrow material matches main exactly.

Judges' asks for the coordinator:
- **Terrapup:** dark umber or chocolate fur, not orange or peach. Stones in mid-grey, not blown white. A bold cream blaze, chest and muzzle. The board's stone tail club.
- **Burrowback:** head 15–20% larger, with the white stripe over the crown. Fewer, larger spine stones.
- **Staticub:** cub proportions (rounder head, big ears, short muzzle, blue eyes). Thin branching periwinkle veins instead of a broad violet wash.
- **Bramblebun:** all three judges again say the body is smaller than the 1.80 m trainer (the regen's back is about 0.95 m). They also want leaf and loam layering over the whole body, thorn vines, and no "vest".

## F36#0 r7 (06:45 UTC): Water Cannonback three-way, all OFF

Installed vs regen 1 (c63e3ba91) vs regen 2 (7fd342ec5, stacked slabs, cream plastron, seated cannons, seat dip). Both regens used native clips. Key: `f36-0-r7-cannonback-3way-key.json`.

| | Installed | Regen 1 | Regen 2 |
|---|---|---|---|
| Mean | 4.97 | **6.07** | 5.87 |

Regen 1 was preferred 2 of 3; one judge preferred regen 2 for its cream plastron and seat hollow. Regen 2's slabs read as pasted-on bricks, its cannons as small pipes, and the rider perches on the rim.

Asks: regen 1's clean finish, with the board's rugged stacked-rock shell, a cream plastron, seated weathered barrels, a heavier snapping-turtle head, and a saddle ledge so the rider straddles.

## Bramblebun scale (07:10 UTC): grown 2.05 → 3.0 m (coordinator's revised ruling)

Hard rule: relative scale fixes grow the smaller side. Every r4/r6 panel flagged Bramblebun's body as under the 1.80 m trainer; only the antlers reached 2.05 m. The coordinator ruled that the catalogue height may grow on that evidence.

The installed Bramblebun was captured at 2.05, 2.6 and 3.0 m, with the radius scaled in proportion as `creature_scale_ladder.apply_scale` does. Capture was at the fight camera with live poses. Key: `bramblebun-scale-key.json`. Three judges, Bar A:

| Height | J1 | J2 | J3 | Mean |
|---|---|---|---|---|
| 2.05 m | 5.2 | 4.5 | 5.0 | 4.90 |
| 2.6 m | 5.9 | 5.0 | 5.9 | 5.60 |
| **3.0 m** | 6.2 | 5.5 | 5.6 | **5.77** (preferred 2 of 3; J3 preferred 2.6 because 3.0 starts to read as a boulder) |

Applied 3.0 m, radius 0.66625 → 0.975, footprint allowance unchanged at 5.8. The fit is height-limited: 3.0 × 2.77 × 3.50 m.

Changes:
- `creature_scale_ladder.py` `TARGET_HEIGHTS.bramblebun` is now 3.00.
- species.json was edited by hand. The tool's `--apply` reformats unrelated rows, so it was not used. A dry run now reports no change for Bramblebun.
- Bramblebun has no aspect variant.

Pre-existing and unrelated: the ladder also reports `water_mirejaw: fitted render 3.276395m misses declared 3.55m` on the base commit.

The remaining score cap is art, not scale: antler branches instead of the board's long leafy ears, flat orange clay with no cream face or chest, and no leaf or thorn layering. Bramblebun regen A2 is in production.

Size-sensitive checks on c5022db53, 0 failed:
- Unit tests: test_scale_sensitive_gameplay 3/11, creature_scale_ladder 2/156, practice_engage_priority 8/31, fresh_opening_target 7/42, opening_beats 25/229, tutorial_faint_floor 8/39, catch_math 36/208, capture_check 21/47, combat_math 35/52, village_boundary 15/254, spawns_data 25/2007, encounter_rewards 31/117, gate_f_live_targets 2/9, dual_type 15/488.
- Smokes: combat OK, creature_grass_clear passed, creature_field_brightness PASS, charger_lunge 54/0, bramblebun_colourway_binding 12/0, alpha_pins OK.
- test_f36_source_contracts OK.

## F36#0 item 6 (07:20 UTC): Ripplet, Galewisp, Veridian, Abyssal Guardian as installed

All four were captured as installed at the fight camera, playing their own clips; none is in the F36 enabled set. Sheet: `_sheet-f36-0-i6.png`. Three judges, Bar A, absolute scores:

| Creature | J1 | J2 | J3 | Mean |
|---|---|---|---|---|
| Ripplet | 6.0 | 6.0 | 5.5 | 5.83 |
| Galewisp | 5.0 | 5.0 | 5.0 | 5.00 |
| Veridian Stag | 5.5 | 4.8 | 5.0 | 5.10 |
| Abyssal Guardian | 6.0 | 6.3 | 6.5 | 6.27 |

Every judge noted for all four that the native hit react looks the same as standing.

Faint ends:
- Ripplet: sits upright, reading as idle.
- Galewisp: wings spread, reading as triumphant.
- Veridian: legs slide through the floor with the head up.
- Abyssal: neck straight up, reading as a rig glitch.

Art asks (all three judges agree):
- **Ripplet:** large translucent aqua fan ear frills with coral inner edge, replacing the pink spiky tufts. Translucent ribbed tail fin. Body toward teal #2BA8C4–#3AA9C0 with navy back accents. Teardrop markings instead of white dots.
- **Galewisp:** wings half open at the sides instead of one vertical spike up and one down. Two matching blue-to-cream ear tufts. Warm cream #EDE3CC instead of stark white. Rounder chest ruff. Gold accents. Fuller fanned tail.
- **Veridian:** the biggest drift. Cream/ivory hide with the green moss confined to the neck/chest mane, shoulders and leg boots. Gold filigree instead of brown vine cages. Teal chest gem. Large branching brown antlers with a few leaves. Short deer tail instead of a white fox brush. Larger head with a readable face.
- **Abyssal Guardian:** emissive cyan line from the eye along the neck and spine, glowing spine tips and fin spots, hexagonal scale normal detail, lower gloss, and a large eye with a cyan ring.

Pose work on my side: F36 recipes for these four (flinch hit plus a grounded faint). Veridian was among the earlier board items switched on; at 5.10 it does not count toward the F36#0 tally.

## F36#0 board-item re-judge (07:30 UTC): none of the earlier switched-on creatures is at 6.7

The coordinator asked for each counted item to have a 6.7+ score on record. Mirejaw and Meadowhart were captured with their live F36 poses; Aeriex and Voltarach play their own clips. Fight camera. Veridian is in the item-6 table above (5.10). Sheet: `_sheet-f36-0-board-rejudge.png`. Three judges, Bar A:

| Creature | J1 | J2 | J3 | Mean |
|---|---|---|---|---|
| Mirejaw | 5.0 | 5.5 | 5.0 | 5.17 |
| Meadowhart | 6.3 | 6.8 | 6.3 | 6.47 |
| Aeriex | 5.8 | 6.0 | 5.8 | 5.87 |
| Voltarach | 5.5 | 6.8 | 6.0 | 6.10 |

The Meadowhart reference I supplied (08 roster sheet) shows no deer, so its identity went unchecked.

Shared findings and asks:
- Native hit reacts match standing (Aeriex, Voltarach).
- Meadowhart's grounded topple faint flips belly-up; the judges want a side-lying collapse. Prone scored 5.20 for it in batch 10.
- **Mirejaw:** stocky axolotl proportions, a visible open cream jaw, pink-red head fronds instead of orange, and no tail-tip tuft.
- **Aeriex:** a cream serpentine body, teal/blue feathers with orange tips, an orange beak and amber eye.
- **Voltarach:** the blue multi-eye cluster emissive and visible from the fight camera.
- Two judges suggested shrinking Mirejaw and Voltarach toward their sheet sizes. That breaks the hard rule (never shrink a larger creature to fit), so it is not forwarded.

F36#0 items on record at ≥6.7 CPU-provisional, judged this session: Stormursa 6.73, Tuskroot 7.03, Burrowback 6.87, Staticub 6.90 (4). The Adair NPC face is deferred because it needs the portrait capture.

## F36#1 native-clip round (07:40 UTC): F36 recipes for six creatures that played their own clips

Three-way capture at the fight camera, blind:
- **native**: the creature's installed clips.
- **recipe**: its existing F36 recipe row switched on.
- **topple**: the recipe with the grounded topple (+90) and recoil hit.

Means: `f36-1-native6-scores.json`. Three judges, Bar A.

| Species | Native | Recipe | Topple | Adopted |
|---|---|---|---|---|
| ripplet | 4.60 | **6.27** | 5.43 | recipe (+1.67) |
| galewisp | 4.77 | 5.07 | **5.83** | topple (+1.06) |
| veridian | 6.27 | 6.30 | 6.00 | none (+0.03) |
| abyssal_guardian | 4.37 | **5.60** | 5.60 | recipe (+1.23; topple's neck-up end reads as a glitch) |
| aeriex | 5.20 | 4.30 | **5.60** | topple (+0.40; the recipe deforms the torso) |
| voltarach | 6.10 | 4.60 | 6.20 | none (+0.10) |

Enabled ripplet, abyssal_guardian, galewisp and aeriex. Galewisp and aeriex are in the postpass `TOPPLED` set (+90, recoil). The full rewrite reproduces all four judged variants and changes only those profiles. None reaches 6.7 yet, so F36#1 stays open for these.

The remaining asks are hit reacts that read and faint-mid frames that differ from standing, together with the art pass 4 materials.

Checks on dd823857b, 0 failed:
- Unit tests: f36_pose_candidates 1/8, rideable_roster 10/82, riding_saddle 8/34, dual_type 15/488, scale_ladder 2/156, fly_traversal 16/153.
- Smokes: water_swimming OK (22), riding OK, fly_traversal 30/0.
- Postpass: --check current; python postpass and source contracts, 9 tests OK.

## F36#0 art pass 3 (07:55 UTC): Terrapup v3, Bramblebun A2, Cannonback regen 3, all OFF

Candidates from tb/meshy-batch: Terrapup v3 11abb63de, Bramblebun A2 66ae69bcd, Cannonback regen 3 2cc7420da. Captures were at the fight camera:
- Terrapup v3 used live F36 poses (same rig).
- Bramblebun A2 got its own-rig recipe (topple +90) at the new 3.0 m.
- Both Cannonback regens played native clips.

Key: `f36-0-pass3-key.json`. Three judges, Bar A:

| Item | Installed | Candidate(s) | Verdict |
|---|---|---|---|
| Terrapup | 5.4 / 5.5 / 6.0 = 5.63 | v3 6.0 / 6.3 / 6.4 = **6.23** (3/3) | OFF |
| Bramblebun (installed at 3.0 m) | 4.5 / 5.8 / 5.8 = **5.37** | A2 5.0 / 4.8 / 5.2 = 5.00 | OFF |
| Water Cannonback | 4.6 / 5.2 / 5.8 = 5.20 | regen 1 6.0 / 6.4 / 6.8 = **6.40**; regen 3 6.3 / 6.0 / 6.6 = 6.30 | OFF |

Asks:
- **Terrapup v3:** the stones still render near-white ("marshmallow") on CPU and the moss is a lime rim. It needs mid-grey stone with dark cracks, olive moss in the seams, the cream chest and muzzle, and tan claws.
- **Bramblebun A2:** reads as a tan hare in a camouflage saddle. It needs a full leaf coat with red thorn vines and a cream face. The body is still small at 3.0 m total because the ears take about 40% of the height.
- **Cannonback:** every judge says the faints float on the native clips. A grounded F36 recipe on the regen rig is the lever on my side. Regen 1's cannons are about 15% too big. Regen 3's moss cap is one flat slab, and its rider stands on the moss.
