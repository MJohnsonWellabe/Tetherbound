# The Village Inn common room — R5 static correction

## Disposition

**HOLD for production proof.** R4's twelve-frame production set rejected the
floorboard candidate: its shader made oversized, nearly black grid seams across
the whole aisle and pushed the room farther toward prototype art. The 1.15-scale
serving pot also dominated the east table, and both table views hard-cropped the
nearest settings.

R5 removes the rejected floor treatment completely and retains only the clean
public-room occupation work. It does not claim a hard PASS until its fresh
production frames are independently judged.

## R5 correction

- Delete the floor-finish plane, shader resource and their positive assertions.
  The accepted plain collision slab is again the only floor surface.
- Keep the installed `Pot_1.gltf`, but set it to 0.58 scale. Its imported bounds
  are 0.539 x 0.224 x 0.486 m, so the visible vessel is now approximately
  **0.313 x 0.130 x 0.282 m**: ordinary tabletop serving scale rather than
  nearly table-width.
- Retain the 0.58-scale apple crate, fitted green/red runners and four asymmetric
  plate/tankard settings. They remain presentation-only and collisionless.
- Pull both common-room cameras back toward the threshold and raise them. The
  general tables view moves from local `(0, 1.8, 3.7)` to `(0, 2.0, 4.3)`;
  the table-service view moves from `(-0.25, 1.55, 3.15)` to
  `(-0.45, 1.85, 4.25)`. Both now aim farther into the room so the closest
  settings can remain fully framed instead of being cut by the bottom edge.

No exterior, config, NPC, interaction, item, terrain, vegetation, scatter,
lighting, footprint, furniture collision or doorway-to-counter route changes.

## Exact path scope and overlap

The revised candidate occupies only:

- `scripts/world/inn_interior.gd`
- `tests/test_inn_interior_visual_identity.gd`
- `tools/capture_inn.gd`
- this report

The R4-only `shaders/inn_floorboards.gdshader` and R4 static report are removed.
These Inn paths do not overlap Highfield, Ranger Camp or Stronghold work. No
generated scatter or production capture artifact is part of the candidate.

## Static verification

The focused Inn checks pass: **6 tests, 46 assertions, 0 failures** across
`test_inn_exterior_identity.gd` and `test_inn_interior_visual_identity.gd`.
The latter now pins the pot to the 0.5–0.6 believable
scale interval, preserves the table occupation/no-collision checks, and adds a
negative assertion that the rejected `CommonRoomFloorboards` node cannot return.

Godot `--check-only` exits zero for `scripts/world/inn_interior.gd` and
`tools/capture_inn.gd`. `git diff --check` is clean for the exact candidate
paths. No production renderer or scatter bake was run in this revision lane.

After static checks, run `tools/capture_inn.gd` under the authorized Windows
Compatibility renderer only when the renderer lease is free. Accept only if all
12 frames are fresh and complete, no floor grid exists, the serving pot stays
secondary, the nearest settings are fully in frame, and the aisle remains clear.
