# Stormheart material and geometry candidate 02

Status: **WITHDRAWN** after fresh blind judgment. Production geometry, traversal and matched native capture checks passed, but the candidate did not improve the complete landmark presentation and lost the narrow floor-material comparison.

## Problem and baseline

The real-input southern approach capture `shots/catalogue/stormwood/broad-stormheart-gameplay-approach02` completed three production-camera views at approximately 80m, the outer-deck edge and 40m from the tree centre. It uses the real trainer, production `CameraRig`, ordinary left-stick traversal from the authored approach foot and ordinary right-stick look. Those views show a consistent landmark problem rather than a catalogue-camera artifact: the 250m split shell reads as giant planar bark walls, the four-turn ascent reads as broad black ribbons, and the energy seam reads as disconnected cyan blocks. The earlier exact-base catalogue pair remains useful only for showing why a camera placed beneath the deck is a poor landmark view.

## Candidate

`scripts/world/stormheart_tree.gd` now separates the constructed walk surfaces from living bark. The bark keeps the installed `Bark_TwistedTree` family, gains finer metre-scale UV repetition and presentation-only radial fluting. The deck, ramps, braces and posts use the installed `Floor_WoodDark` material family's atlas strip with a small material-local shadow lift so their visible undersides retain brown form. The energy seam is narrower, follows a continuous low-frequency path and uses shorter overlapping segments.

All values live under `stormheart_presentation` in `data/config/stormwood_world.json`. The change does not alter the physical ring meshes, ascent curve, rail transforms, encounter anchors, core anchor, deck radii, creature sizes or spawn counts. Shell fluting is applied only to rendered outer-bark vertices.

The first walk-surface implementation repeated the entire `T_WoodTrim` atlas and produced obvious orange checkerboard and stripe patches. `Floor_WoodDark.gltf`'s real UV accessor selects atlas V `0.311528..0.554958`; the corrected shader repeats only that installed plank strip. Procedural meshes do not provide tangents, so the candidate deliberately does not assign the atlas or bark normal maps.

The old bark U expression covered about 37.7 texture repeats around a complete circle (`angle * 6`). The candidate uses 48 explicit repeats, so it is finer rather than coarser, and repeats vertically every 7m instead of every 11m.

## Preserved failed evidence

- `stormheart-material-presentation-first` / failed art 01: native run exited failed after 66 seconds (04:31:47–04:32:54) with one retained diagnostic frame. The walk material visibly repeated the whole trim atlas. The camera aim also missed the strict 2° band by 0.0046° after 32 frames. This is not passing visual evidence.
- `shots/catalogue/stormwood/broad-stormheart-material02` / failed material 02: one of three frames was retained, then the native run failed with desired pitch 27.388°, ending pitch 23.553° and 3.835° error. The atlas checkerboard was gone, but the proportional input fell below the combined input-map and camera deadzones. This is not a matched comparison and cannot support acceptance.

The diagnostic controller now derives its minimum raw strength from both production deadzones: input-map `0.20 + CameraRig 0.18 * (1 - 0.20) = 0.344`. Its 0.36 floor yields about 0.63° per 60Hz frame at the production 190°/s rate and retains the original 2° acceptance threshold. This is capture-tool behavior only; gameplay camera behavior is unchanged.

## Structural evidence

- Focused `test_stormheart_presentation.gd`: 4 tests / 139 assertions passed without errors (04:45:50–04:45:53). It verifies the rendered shell remains outside the 44m physical arena, named production floor bodies remain present, and roots avoid the southern approach and Water departure.
- Canonical scatter bake: completed 04:45:02–04:45:12 with all 108 region binaries unchanged. The world config addition does not change vegetation placement.
- `smoke_stormheart_ascent.gd`: completed cleanly in 47 seconds (04:47:47–04:48:34). It ray-checks the actual ascent floor and both rails at five fractions, then continuously walks a real `CharacterBody3D` over the full four-turn ascent to `core_anchor`, once with rendered-world construction and once with simulation-shell construction.

These checks support the claim that this presentation candidate preserves authored traversal and collision. They do not establish that the new surface treatment looks better.

## Native comparison and judgment

`shots/catalogue/stormwood/broad-stormheart-material03` is the first complete matched candidate set using the corrected atlas crop and deadzone-aware evidence controller. The guarded native OpenGL run `stormheart-deadzone-aware-approach-first` completed 3/3 frames without errors in 79 seconds (04:49:09–04:50:28). This establishes a complete, like-for-like physical approach set; it does not by itself establish visual improvement. Those three views were compared blindly with `broad-stormheart-gameplay-approach02` before disposition.

The fresh blind review `JUDGE-STORMHEART-MATERIAL03.md` mapped F01–F03 to the candidate and F04–F06 to the baseline. It preferred baseline F04–F06 narrowly because their warmer foreground floor reads more clearly as timber. The candidate floor read as a smoother, indistinct coated surface. Both groups received **A: No**, **B: Yes, narrowly**, and **commercial quality beside Palworld: No**. The judge also found that neither treatment solves the dominant landmark problems: immense repetitive grain, dark ribbon-like ramps, weak route entry and structural articulation, flat cyan geometry, and weak local lighting/grounding.

The candidate is therefore withdrawn. Passing collision, ascent, bake and capture checks establish safety and evidence quality, not visual acceptance. The tree script and `stormheart_presentation` config changes are being removed from production. Their preserved patch is `.artifacts/broad-visual-0910/stormheart-material02-withdrawn.patch`. The corrected real-input approach capture tool remains useful for a future, materially different authored-geometry pass. No further texture or small geometry tuning is justified in this pass.
