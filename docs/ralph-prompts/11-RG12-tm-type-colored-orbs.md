# RG12 — TM world pickups should use type-colored orb visuals

## Goal
Replace the current upright tablet/slab visual for world TM pickups with a compact orb-based visual language whose color communicates the TM move type consistently.

## Owner intent
The owner confirmed that TM pickups should be colored orbs, with the color tied to move type rather than arbitrary per-TM decoration. Examples explicitly given:
- Ground TMs = brown orbs
- Water TMs = blue orbs
- Fire TMs = red orbs
- etc. for the remaining move types

The purpose is twofold:
1. TMs should read immediately as a distinct collectible pickup in the world.
2. The orb color should teach and reinforce the move's type at a glance.

Do not preserve the current upright-tablet visual merely because it already works technically.

## Current state
Current implementation is `scripts/world/tm_pickup.gd`.

Today `_build_visual()` creates:
- a small vertical `BoxMesh` slab/tablet
- an emissive material whose color comes from TM data
- a small white emissive rune/square on its face

The pickup behavior itself is already correct and should be preserved:
- TM is a real inventory item, not just a permanent knowledge flag
- full inventory refuses the pickup and leaves the object in world
- successful pickup writes the `tm:<id>` progression flag so the world pickup does not respawn after reload
- already-collected TM placements are skipped by world placement code

RG12 is primarily a visual-language change, not an inventory/progression rewrite.

## Desired player-facing behavior
A player walking through the Meadows should be able to spot a TM pickup and understand two things before interacting:
1. this is a TM/valuable pickup rather than ordinary scenery
2. its move type, from the orb color

The object should:
- be orb-shaped rather than tablet-shaped
- hover slightly above the ground or otherwise sit clearly proud of terrain
- have a subtle idle motion such as slow float, bob, gentle rotation, or pulse
- remain readable at normal exploration distance
- avoid looking like a giant glowing quest beacon
- avoid looking identical to a standard capture orb if capture orbs use a similar spherical language

The animation should be understated. TMs are discoverable collectibles, not neon waypoints.

## Type-color contract
Use a single shared source of truth for move-type colors. Do not scatter hard-coded type/color mappings across TM pickup code.

At minimum the mapping must include all move types currently present in the repo. The owner explicitly established these examples:
- Ground = brown
- Water = blue
- Fire = red

Define sensible, internally consistent colors for every other existing move type using the game's established palette where possible. If type colors already exist elsewhere in the repo, reuse that shared mapping instead of inventing a second one.

Important: the type color should be derived from the TM's move type/category data, not from arbitrary TM-specific authored colors. Two Ground TMs should read as the same Ground family even if their moves are different.

If current `tm_db` data only exposes an arbitrary per-TM color, trace the move/TM data relationship and add a clean type lookup seam rather than encoding special cases into the visual.

## Relevant systems/files to inspect first
Before editing, inspect current main and confirm the live paths. Likely relevant:
- `scripts/world/tm_pickup.gd`
- `scripts/creatures/tm_db.gd`
- `data/moves/tms.json`
- move/type data used by creature/move UI
- any existing shared type-color helper or UI token mapping
- world placement code that instantiates TMs
- tests that cover TM inventory/persistence

Also inspect capture-orb visuals before finalizing the TM sphere so the two systems are related but not confusable.

## Implementation requirements
1. Replace tablet/rune geometry with an orb-based pickup visual.
2. Derive orb color from TM move type.
3. Reuse or create one shared type-color mapping.
4. Add subtle idle presentation movement without affecting collision or interaction range.
5. Preserve current interact prompt and pickup semantics unless the live repo has already improved them.
6. Preserve the one-time-world-pickup persistence path (`tm:<id>` flags).
7. Preserve full-inventory refusal behavior.
8. Preserve controller/keyboard interaction behavior.
9. Do not create one custom scene/file per TM if a data-driven visual can render all TMs.
10. Keep values such as hover height, bob amplitude/speed, emissive strength, and orb scale tunable rather than burying them as unexplained magic numbers.

## Design constraints / preserve list
Preserve:
- TM inventory item contract
- one successful world pickup per save
- satchel-full refusal
- interaction arbiter/prompt behavior
- item identity and move-teaching systems
- performance suitability for handheld target

Do not:
- turn TMs into permanent knowledge again
- consume or grant a TM merely by getting close
- make the orb so bright that it becomes an always-visible beacon through vegetation
- use random colors per TM
- make color purely decorative with no consistent type meaning
- duplicate a type-color system that already exists elsewhere

## Edge cases
Verify:
- every TM currently placeable in Meadows resolves to a valid move type
- unknown/malformed type data fails visibly in development but still gets a safe fallback visual
- two TMs of the same type share the same color family
- TMs of clearly different types are distinguishable on the actual Meadows lighting palette
- night lighting does not make blue/purple/green families impossible to tell apart
- colorblind readability is helped by shape/idle treatment remaining consistent and the interact prompt naming the move; do not rely on hue alone for identity
- collected TM remains gone after save/load
- full inventory leaves the orb present and interactable

## Acceptance criteria
RG12 is complete when all of the following are true on current main:
- No Meadows TM world pickup uses the old upright tablet/slab visual.
- Every TM pickup is rendered as a compact orb collectible.
- Orb color is derived consistently from the TM move type.
- Ground TMs visibly use brown, Water blue, Fire red, with equivalent consistent mapping for all other live move types.
- The orb has subtle idle motion/presentation and remains easy to notice without functioning as a giant quest marker.
- A player can distinguish a TM pickup from ordinary scenery and from a standard capture orb.
- Picking up a TM still adds the correct inventory item.
- A full satchel still refuses the pickup without deleting it.
- The same world TM cannot be collected again after save/reload once successfully taken.

## Testing / verification
Add or update focused tests where practical.

At minimum verify programmatically:
- type lookup for every current TM
- same-type TMs resolve to same type color
- required example mappings Ground/Water/Fire resolve to brown/blue/red families
- TM pickup inventory and persistence tests remain green

Also perform a visual verification in the Meadows with several TM types placed/visited in normal daytime and nighttime lighting. Capture at least one frame where multiple different types can be compared if the tooling supports it.

Do not call the task complete from unit tests alone; this item is primarily a world-readability/presentation change.

## Definition of done
The Meadows uses one coherent TM pickup visual language: small orb collectibles, subtly animated, whose colors consistently communicate move type, while all existing TM inventory and persistence behavior remains intact.
