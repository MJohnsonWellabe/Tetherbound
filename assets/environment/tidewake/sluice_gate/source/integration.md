# Asset integration contract

The two scene variants use the authored 18 m and 30 m gate widths, both 7 m high. Origin is floor-centre of the existing gate plane; +Y is up, -Z faces the intake approach. No scale or rotation is required.

Each scene contains two independent children:

- `FixedFrame`: timber guides outside the original opening, overhead hoist, slatted receiving drum, slot and wheel above it, side counterweights. Attach this to the interior root at `(0, 0, gate.z)`, not beneath the barrier that is hidden.
- `GateLeaf`: oak lower gate, bronze reinforcement and open upper bars. Attach this to the existing gate `StaticBody3D` at local zero, replacing only the old visual bars. Preserve its existing collision box and `_gates` registration.

The existing `barrier.visible = not opened` then hides only the leaf, leaving the hoist, receiving roll and frame visible. All fixed geometry below Y7 sits outside the opening, preserving the original width. The receiving assembly tops at Y11.25, below the existing Y12 ceiling. Do not add collision to either model.

The open pose is `GateLeaf.visible = false`. The segmented lower boards, hinged grille rows and overhead wound slats imply a roll-up gate with a permanent receiving housing, rather than a rigid gate rising through the ceiling. Its winding fill is static in both states; this does not simulate gate animation. Do not translate the entire rigid mesh upward.

The low posts outside the opening are necessarily partly embedded in the continuous side walls. Visible overhead cheek plates, slot lintels and projected support brackets provide structural attachment above Y7 without narrowing the original walkable aperture. Full-height side guides could only be exposed inside the current walls by narrowing the opening or recessing the masonry, which is outside this asset-only change.

The closed leaf keeps its upper section open to retain visibility into the next room. The low timber panel is visually solid and corresponds to the existing closed full-width barrier.

Revision r3 uses deeper joints between substantial two-course planks, dark recessed backing, end-seated reinforcement, iron washers under dull bronze hex bolts and broad vertex-colour wear. All exported surfaces retain four shared materials per model; the installed wood atlas is reused.

`source/mesh-audit.json` records the final native metre bounds, triangle counts and zero degenerate triangles. `build_sluice.py` reproduces both widths; pass `-- --preview` for a CPU-only diagnostic image. Preview is not acceptance evidence.
