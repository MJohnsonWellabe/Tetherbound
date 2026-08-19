# BUILD-REMOVE — Dismantle player-built structures with full refund

## Owner decision
The player needs a way to delete/remove structures they built. The owner approved the proposed Valheim-style answer.

Locked behavior:
- removal is a deliberate construction-mode action, not an accidental generic interact;
- the targeted player-built piece is visibly highlighted before removal;
- dismantling returns **100% of that piece's normal material cost**;
- controller-first and discoverable through the build controls;
- only player-built/removable structures use this action. World buildings, landmarks, terrain props and authored village structures must not become destructible by accident.

## Goal
Let players correct mistakes, rebuild, and experiment without being trapped by bad placement or punished for learning the snap system.

## Inspect first
- `scripts/build/build_placer.gd`
- placed-building runtime node/script(s)
- `autoload/game_state.gd::placed_buildings`
- save/load reconstruction of placed buildings
- `data/items/buildables.json`
- inventory/add-item/resource overflow behavior
- current build-target ray/query utilities
- placement ghost/highlight material utilities
- storage/stateful buildables and any serialized internal state

## Targeting contract
While build mode is active, expose a Dismantle/Remove action that targets the single nearest piece under the player's construction aim/crosshair within a reasonable range.

The target must be unambiguous:
- highlight only the piece that will be removed;
- do not select through another structure;
- do not remove a neighboring snap piece because its collider is larger;
- do not target arbitrary StaticBody3D world geometry.

Prefer explicit metadata/group/interface on player-built nodes over heuristics such as node-name matching.

## Removal transaction
Dismantling a piece must be one coherent transaction:
1. validate target is a removable player-built piece;
2. determine its authoritative buildable id;
3. capture the correct recipe/material cost from data;
4. handle any stateful contents safely;
5. remove it from `Game.placed_buildings`/save registry exactly once;
6. remove its world node/collision;
7. refund the full normal construction cost exactly once;
8. show concise feedback for refunded materials.

Do not allow save reload to resurrect a dismantled piece.

## Stateful structures
Inspect existing behavior for storage, workbench, beds and any buildable carrying state.

At minimum:
- never silently destroy inventory stored in a chest;
- never duplicate stored contents during dismantle/reload;
- a creature currently assigned/resting in a bed cannot be orphaned by deleting that bed. Either refuse dismantle with clear feedback until the bed is empty, or cleanly return the creature to the available party state before removal according to the new bed-rest contract. Prefer refusal if it is simpler/safer and clearly explained;
- do not let removing a workbench corrupt any menu that is currently open from it.

If a container is non-empty, the safest default is **refuse dismantle and say why**, unless the project already has a proven spill/drop mechanism.

## Full refund semantics
Refund the buildable's current normal construction ingredients, 100%.

- Free Build does not create phantom resources: if a piece was built for free under the development toggle, inspect whether build records retain enough information to know that. If not, choose the safe project-consistent rule and document it; do not create an infinite resource exploit accidentally.
- If inventory capacity cannot accept the whole refund, use an existing world-drop/overflow mechanism. Never silently delete refunded materials.
- No random loss percentage or durability tax.

## Input/UI
Add the action to the persistent placement hint strip using existing glyph infrastructure.

The remove input must not collide destructively with:
- Place
- Cancel
- Rotate
- Snap
- menu reopen/change-piece

Use the existing InputMap conventions; do not read raw physical button numbers in gameplay code.

## Save/load regression
Test:
- build A/B/C;
- dismantle B;
- save/load;
- A and C remain, B does not;
- materials refunded once, not again on load.

For a dismantled piece adjacent to others, neighbors remain in place and their save entries stay intact.

## Acceptance criteria
1. Player can enter build mode, aim at one of their pieces and see which piece will be removed.
2. Remove action deletes exactly that player-built piece.
3. Authored world/village structures cannot be dismantled.
4. Full material refund occurs exactly once.
5. No refund/materials are silently lost on capacity overflow.
6. Placed-building registry/save state removes the correct record.
7. Reload does not restore dismantled structures or duplicate refund.
8. Stateful pieces protect contents/resting creatures from silent loss.
9. Removal works with controller and keyboard/mouse.
10. Repeat-placement build mode remains active/usable after dismantling.

## Definition of done
A player can build experimentally, correct mistakes immediately, and recover all construction materials without corrupting world/save state.