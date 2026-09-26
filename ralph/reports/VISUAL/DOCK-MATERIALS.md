# Dock material and lantern verification

Anchor: X04 / F13 dock presentation, ART_DIRECTION §§4, 6 and 9;
ACCEPTANCE §4. Baseline: main `32bd33079`.

This is a bounded visual repair, not Tidewake or whole-game acceptance.
The owner directs Codex to work on isolated visual branches and leave merges
to Claude. Gameplay, travel rules, world layout and saves are outside this diff.

## Reproduced defect

The dock material helper visits descendants but omits a MeshInstance3D root.
An imported scene rooted at a mesh therefore retains its source material even
when the dock code requests a tint or emission. The regression uses root and
nested meshes sharing one source material, plus an untouched sibling instance.

Command:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --script tests/run_tests.gd -- --only=test_water_dock_dressing::test_material_override_covers_root_mesh_and_children_without_mutating_source
```

- Before: 1 test, 5 assertions, 1 failure (root treatment absent).
- After root traversal repair: 1 test, 6 assertions, 0 failures. Both root and
  nested meshes receive the override, and the shared source remains unchanged.
- Native Windows Godot 4.7 stable, isolated checkout. This test establishes
  material assignment, not appearance.

The native installed-asset probe corrected the initial causal hypothesis:
`Lantern_Wall.gltf` imports with a Node3D wrapper, so it already received the
old override. Its white silhouette came from making the entire bracket, chain
and cage emissive. Root coverage is a separate demonstrated helper defect,
not the cause of this fixture's white appearance.

The candidate retains the installed opaque housing and adds one small amber
glass insert within its existing cage. The local light follows that fitted,
rotated insert. No source asset, collision or world state changes.

Two deck treatments were rejected during native inspection: a flat override
lost the wood detail, and an atlas-preserving pigment remap retained harsh noise
and looked too pale. Neither is included. The existing deck remains an open
material/geometry task requiring a different approach, not more tint iteration.

Focused candidate validation: 7 tests, 78 assertions, 0 failures, including the
real installed lantern and the existing First Shore barrier checks.

## Visual evidence status

Historical `CREATURE-ART-LANE/tidewake-docks/docks_after_v5.jpg` was independently
reviewed without code or change context. Both bars failed: white cage-like
lanterns, repetitive shore transitions, and weak dock/landmark hierarchy.
The reviewer requested amber interiors, dark housings and localized warm light
on legible timber. Shore and landmark composition remain separate open work.

## Current capture and independent verdict

Native Windows Godot `4.7.stable.official.5b4e0cb0f`, Compatibility/OpenGL 3.3,
NVIDIA GTX 1060 3 GB. Fresh isolated application-data directory, production Water
scene, player, CameraRig and HUD; tool-injected near/mid stands and frozen day/night
clock. These are diagnostic views, not earned travel, 30-second motion acceptance
or ROG Ally performance evidence. Ambient creatures and temporary HUD notices vary.

```text
Godot_v4.7-stable_win64.exe --path . --rendering-driver opengl3 --resolution 1920x1080 --script tools/art_pipeline/capture_tidewake_matrix.gd -- --out=res://shots/dock-final --only=dock-first-shore-pier-near,dock-first-shore-pier-mid
```

Baseline uses the exact main version of the dressing script. Final uses this PR's
script/config. Native 1920×1080 frames were also downscaled to 1280×720 for the
stress review. Both native capture runs contain no `ERROR:` or `SCRIPT ERROR`;
the existing physics-interpolation deprecation warning remains.

Reviewer `dock_final_visual_judge` received neutral sets X/Y, reference images and
the rubric, with no code, chronology or change narrative. X is the final candidate;
Y is baseline. The single committed sheet is `_sheet_dock_lanterns.png`.

**Bounded fixture result: improvement accepted, no visible regression.**
The reviewer preferred X at both rasters: warm shaded brackets/cages in day,
separate structural housing and small lamp highlights at night. Y's fully white
assemblies read as markers. At mid distance X remains coherent but lamp cores
could read more clearly without brightening their supports.

**Whole-scene Bar A: no. Bar B: no.** Ranked remaining defects: mottled/washed-out
creature surfaces and weak faces; rounded, weak Veilfall/landform silhouette; bare
repetitive shore and isolated props. Posts remain smooth cylinders, deck/cargo
surfaces noisy, and lamps small at mid distance. This PR closes only the white
emissive-housing defect and the separately tested root-override helper omission.

Reviewer `dock_code_review` independently inspected the actual script/config/test
diff: no correctness findings, no shared-material mutation, light/insert transforms
correct, no gameplay or collision scope expansion. It did not infer appearance from
code. A later reviewed timber experiment was removed following visual rejection.

`tests/smoke_playground.gd` completed `smoke: OK`. It also emitted the single distinct
dummy-renderer error `Parameter "material" is null`, explicitly documented in
WORKFLOW §5. No script error occurred. This is not reported as an error-free smoke;
the unrelated existing engine diagnostic remains open. Focused final tests again
passed 7 tests / 78 assertions on the submitted script/config.

PR288 is for Claude to merge after its CI/integration checks. No whole-chapter,
whole-game, target-device or live-main acceptance is claimed.
