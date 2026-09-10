# South Bridge gate scale continuation — 2026-09-10

## Result

The existing approved South Bridge hero gate now reads as a fortified chapter
threshold in the production camera. Its fitted height increased from 2.76 m to
4.40 m: from 1.53 to 2.44 times a 1.8 m trainer. The same imported gate, palette,
placement, animated gameplay leaf, collision, guardian encounter, and unlock
contract remain in use.

This is a local composition correction, not a commercial-pass claim for the
Meadows. No new art was generated, no Meshy request was made, and no route or
progression state changed.

## Why this was retained

The approved board at `docs/art/reference/21_South_Bridge_Checkpoint_Gate.png`
shows a full-width, cart-blocking timber checkpoint standing substantially above
the people beneath it. In the fresh baseline the 2.76 m hero gate was barely
taller than the trainer and visually subordinate to the separate approach
banners, so it read as a yard gate rather than the chapter boundary.

Fresh like-for-like production captures:

- before: `.artifacts/broad-visual-0910/south-bridge-scale-before/`
- after: `.artifacts/broad-visual-0910/south-bridge-scale-after/`
- matched stands: `bridge-approach-played`, `bridge-checkpoint-shoulder`, and
  `bridge-deck-far-side`
- capture entry point: `tools/_capture_w22_bridge_signpost.gd`, Godot 4.7,
  OpenGL3, 1280x800

Across all three stands the retained 4.40 m fit makes the gate the dominant
destination at the end of the road and bridge. The close view preserves a clear
trainer comparison; the shoulder view reads as a fortified checkpoint; the far
side retains the silhouette through the bridge rails. The wider fitted stone
shoulders remain plausibly embedded in the gully banks, with no visible floating
or route obstruction.

## Bounded implementation

- `scripts/world/south_bridge.gd`: changed only `HERO_GATE_HEIGHT`, from the
  2.76 m post-plus-lintel value to 4.40 m.
- `tests/test_south_bridge_visual_scale.gd`: measures the real imported model and
  enforces a minimum 2.4 trainer-height silhouette and a fitted width of at least
  9 m.

`_build_hero_gate()` still creates visual dressing only. The independent gate
leaf and collision retain their original dimensions and animation, and the hero
mesh is still removed by the existing open-state path.

## Verification

- Focused suite:
  `test_south_bridge_visual_scale.gd,test_crossing_failsafe_placement.gd,test_river_crossings_stay_open.gd,test_item_gate.gd`
  — **21 tests, 88 assertions, 0 failed**.
- `tests/smoke_south_bridge_challenge.gd` on the real Meadows scene — **exit 0**.
  The guardian walked 5.61 m to the player in 152 frames, opened
  `south_bridge_grunt_challenge`, and the bridge auto-opened two frames after the
  defeat flag and key landed.
- Fresh after captures completed for the same three production-camera stands.

The smoke emitted the pre-existing late-arrival `adopt_starter` warning after its
successful result; that story-fixture warning is unrelated to gate geometry and
did not change the exit result.
