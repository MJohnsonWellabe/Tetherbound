# BUILD-SNAP — Make floors, walls, doors and roofs compose into a real modular house

## Owner reproductions — 2026-08-18 evening
- A roof cannot be built cleanly on top of an already-built wall.
- Floors do not occupy/align to a full logical square.
- Walls sit about half a square off instead of snapping to the intended floor edge.

These are not three cosmetic offsets. Treat them as evidence that the current modular dimension / pivot / snap-anchor contract is inconsistent across build pieces.

## Goal
A player should be able to construct a basic house from the catalogue without fighting hidden half-cell offsets or manually eyeballing every piece.

The canonical regression structure is:
- 2x2 floor grid;
- walls around the perimeter;
- one doorway/door;
- roof pieces seated on the wall tops;
- no gaps caused by inconsistent module size;
- no overlaps/z-fighting caused by piece-specific correction hacks.

If the system cannot build that reliably, snapping is not done.

## Inspect first
- `scripts/build/build_placer.gd`
- grid/snap helper code and current snap step constants/config
- `scripts/build/build_piece.gd`
- piece scripts/prefabs for floor, wall, door, roof, fence and foundations if present
- `data/items/buildables.json`
- model/pivot transforms and imported mesh bounds
- collision dimensions for each modular piece
- save/load transform reconstruction
- `tests/test_build_grid.gd` and all build-placement tests

Measure actual mesh/collision bounds and pivots before changing snap values. Do not tune by screenshot until it looks approximately right.

## Establish one module contract
Define the project's canonical building module in data/code so every structural piece agrees on:
- horizontal cell size;
- floor thickness and floor top elevation;
- wall width/height and where its local origin sits;
- roof support/top anchor height;
- door opening dimensions/pivot;
- snap points / edge anchors / corner anchors;
- yaw increments.

Prefer explicit per-piece snap metadata derived from one module over hidden offsets scattered through switch statements.

Do not rescale visible meshes arbitrarily if the issue is merely imported pivot/origin. Conversely, do not preserve a bad pivot and compensate with a dozen magic numbers.

## Required snap families
### Floor to floor
- Adjacent floors land exactly one module apart edge-to-edge.
- A 2x2 layout closes cleanly with no half-cell drift.

### Wall to floor
- Wall snaps to a floor perimeter edge, not the floor center and not half a cell away.
- Corners meet cleanly.
- Rotated walls use the same rule.

### Door / doorway to wall system
- Door-bearing piece aligns with the wall grid.
- Door opening remains traversable and collision matches visuals.

### Roof to wall
- Roof support edge/anchor snaps to the top of a wall at the correct elevation.
- Existing wall collision must not make the intended roof position permanently invalid.
- Placement validity should understand legitimate structural contact rather than treating every support touch as an overlap.

### Roof to roof
If multiple roof pieces are required to span a larger house, they should meet predictably using the same module/angle grammar.

## Placement validity
A common failure mode is a correct snap transform being rejected by generic overlap logic because supporting pieces touch.

Audit the validity test so it distinguishes:
- illegal penetration/overlap;
- intentional support/contact at snap anchors;
- adjacency between modular pieces.

Do not simply disable collision checks for build mode.

## Repeat placement coordination
`40-BUILD-valheim-repeat-placement.md` means the player will place many adjacent pieces quickly. Snapping should therefore:
- prefer nearby valid structural anchors when present;
- remain stable as the camera moves slightly;
- avoid oscillating between two anchors;
- allow an intentional unsnapped/grid placement path only if the current design already supports it.

## Dismantle coordination
Bad snaps must be correctable with the dismantle action, but dismantle is not the solution to systemic misalignment.

## Automated regression
Create a data-driven build-grid test that constructs or computes the canonical transforms for:
1. Floor A at origin.
2. Floors B/C/D making a 2x2 square.
3. Four perimeter wall runs/corners.
4. Door piece on one wall.
5. Roof pieces on wall tops.

Assert expected world transforms within tight tolerance and verify placement legality at each intended snap.

Also verify saved/reloaded transforms remain identical; load must not introduce rounding drift.

## Live/controller verification
In the actual Meadows build:
- select floor once;
- place a 2x2 floor using persistent mode;
- place walls around it;
- place door;
- place roof;
- walk through door and around inside;
- save/load and inspect the same house.

No manual transform console edits or free-camera precision placement in acceptance.

## Acceptance criteria
1. Floors fill the logical grid exactly.
2. Walls snap to floor edges with no half-square offset.
3. Wall corners meet correctly.
4. Roof can be placed on already-built walls.
5. Legitimate support contact does not fail generic collision validity.
6. Door aligns with wall/floor system and is traversable.
7. Repeated placement remains stable and predictable.
8. Save/load preserves exact composition.
9. Every fix is systemic/metadata-driven rather than one coordinate offset per observed piece.

## Definition of done
A first-time controller player can build a small enclosed roofed house using only the visible build controls and snaps; the geometry looks intentional without precision nudging.