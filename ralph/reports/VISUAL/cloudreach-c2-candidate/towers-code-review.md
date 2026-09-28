# Cloudreach belvedere source review

## Blocker

**P1 — All arch-stone faces are inside out.** In `scripts/world/cloudreach_aviary_towers.gd:94–95`, the two `_triangle` calls reverse each quad in the face table. That table already has the clockwise exterior winding Godot expects. The resulting geometry exposes the interior faces and `generate_normals()` consequently generates inward normals. The production masonry shader retains back-face culling (`shaders/cloudreach_masonry.gdshader:2`), so the four open arches on each tower cannot render as correctly closed solid masonry. Reverse the two triangle emissions to `[0,1,2]` and `[0,2,3]` within each face, or use the existing outward-normal `_arch_quad` pattern. Keep the roof order unchanged.

Verification: independently evaluated the submitted vertex/face expressions numerically for every one of the 11 stones. With Godot's clockwise convention, all 132 triangles per arch point toward their stone's centroid (132/132 inward); the roof's 6/6 triangles point outward. The existing architecture test also encodes this clockwise convention in `tests/test_cloudreach_aviary_architecture.gd:31–35`. This was an analytic geometry check, not an engine render.

## Scope checks

- **Footprint and seating pass for the current config.** Both drum radii are 27 m and the pier offset is 0.6 m. The new centers exactly match the four existing pier centers at 55/125/235/305 degrees. Rotation `-angle` matches the existing radial/tangential pier basis. The 2.2 × 3.0 m shaft fits the 2.4 × 3.2 m capital with 0.1 m margin per side. It starts at local y=9, the capital's top. The lowest 0.32 m decorative course overlaps the capital by 0.16 m, avoiding a seating gap; its 2.48 × 3.28 m footprint overhangs the capital by only 0.04 m per side.
- **Existing summit seating is retained.** `_seat_aviary_on_summit_carve` adds footings; it does not move the pier tops. Calling the new builder afterward therefore does not detach the shafts from their supports.
- **Collision, route openings, and pylon anchor pass source review.** Every new box passes `collision=false`; the cylinders and custom meshes contain no bodies. The existing arch, drum collision, and anchor computations are unchanged. The tower addition begins above local y=8.84 and remains on the four existing off-route supports. The gallery expands at y=24, far above the route openings.
- **Roof winding passes.** All four pitched faces and both underside triangles have exterior clockwise winding. Roof base seats exactly on the eaves top. The finial overlaps the apex by 0.2 m. No detached roof component was identified.
- **Gold material hookup passes source review.** A valid `StandardMaterial3D` supplies both dome rib and ring materials while preserving geometry and the existing timber/iron fallbacks for callers without `dome_rib`. The supplied roof material is also valid.
- **No concrete GDScript parse or runtime exception identified from source.** Typed loops, static helper calls, dictionary arguments, mesh commits, and node ownership are consistent with the project's Godot 4.7 usage. This is not a parser/runtime pass: no Godot process, import, gameplay run, or new render was launched for this review.

## Limits and receipt

Reviewed the uncommitted new tower script, its specific world hookup, dome-material change, and aviary JSON additions at base HEAD `5e2695bcc77012a3fb55dcf85efeaa5c7d29c2ab`. Tower script SHA256 at review: `78567DD2421648C1ACAAC645FD7A97663D07258DA68F4B90662EF9451F0E21F4`.

Other Cloudreach WIP was excluded. No source edits were made. Board resemblance and final visual acceptance remain with the separate visual review. The calculated placement guarantee applies to today's circular drum; if the radii become unequal, the new builder's radius-plus-offset formula and radial rotation would no longer exactly reproduce the existing ellipse-normal pier placement.

## Correction review disposition

**The P1 winding finding is resolved; no remaining source-review blocker identified in the bounded tower change.** Independently reread the corrected `_arch_stone`: it now emits `[0,1,2]` and `[0,2,3]` for each face. This reverses all 132 previously inward arch triangles to the correct outward direction. The six roof triangles retain their original correct winding. Corrected tower script SHA256: `11ADD3B70F22268B88D56B33F523526253C65EA020292DAC2F0E2F114FCE7976`.

Inspected `tests/test_cloudreach_belvedere_geometry.gd` and the actual `visual-acceptance-local/cloudreach-candidate-tests.log`. The new test checks each roof/stone triangle's clockwise geometric normal against an interior centroid, so it would catch the original inversion instead of merely accepting matching inward generated normals. It also builds all four extensions, verifies no collision objects, compares shaft dimensions with the supporting pier dimensions, and checks the shaft bottom is above the required portal height. These are meaningful bounded regression checks. They do not independently verify the full route sweep or rendered appearance; the source seating/placement assessment above still applies.

The supplied Godot 4.7 runtime log records **10 tests, 202 assertions, 0 failed**, including both new belvedere tests and all three existing aviary architecture tests. This provides actual parse/build execution evidence beyond the original source-only review. I did not launch another Godot process or render. Native `towers-v2` visual acceptance is separate and was not inferred from these results. Original finding retained above as the review history.
