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
