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

## Visual evidence status

Historical `CREATURE-ART-LANE/tidewake-docks/docks_after_v5.jpg` was independently
reviewed without code or change context. Both bars failed: white cage-like
lanterns, repetitive shore transitions, and weak dock/landmark hierarchy.
The reviewer requested amber interiors, dark housings and localized warm light
on legible timber. Shore and landmark composition remain separate open work.

Current baseline/candidate captures and their independent judgment are pending.
The draft PR must not be treated as visual acceptance until those are recorded.
