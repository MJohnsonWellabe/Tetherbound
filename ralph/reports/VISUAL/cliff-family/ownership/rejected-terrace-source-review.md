# Terraced cliff profile — independent source/math review

2026-09-27. Reviewed `scripts/world/terraced_cliff_profile.gd`, the current `_mesa` integration in `cloudreach_world.gd`, and `cloudreach_visual.json::geology.wall_profile` in the owned visual-acceptance checkout. This is the broad terrace candidate, separate from the rejected fine-ridge experiment. No engine/import/export or production edits; native capture was running separately.

**Verdict:** no collision/crown-generation change or winding blocker found. The original helper's claim that every sample stays inside the original radial envelope must not be extended to the full connecting surface. A concrete outward excursion exists where the new bands skip an old profile corner. The parent has proposed preserving the original profile knots; that proposal is assessed below but was not yet present in the reviewed source.

## Concrete finding: profile-corner bridging

`terraced_cliff_profile.gd:5` uses levels 0, .055, .24, .27, .51, .56, .79, .83, 1, while `_sample` changes segments at .26 and .65. Each newly sampled vertex is radially contracted from its sampled source point. However, the connecting edge can bridge outside an inward original corner because neither source corner is retained.

A CPU reconstruction using the production summit region's size `(560,1370,294)`, seed 6 and 48 sides found this witness:

- Perimeter column 4, band .56→.79, edge fraction .52.
- Candidate local point `(263.352911, -246.693128, 74.877755)`; world height `228.306872`.
- Candidate horizontal radius `273.790858 m`.
- A horizontal ray from the local centre at the same height/direction intersects the **old displaced, tessellated wall** at radius `241.637485 m` (old lower band, column 3). Candidate extends **32.153373 m farther out** here.

This does not establish a gameplay collision blocker: the wall remains visual-only and this witness is far below the summit crown. It does disprove strict same-height containment and calls for either preserving the profile corners or explicitly accepting the silhouette excursion. It is not evidence that the whole object's maximum bounds grew.

**Parent's proposed correction:** retain exact unwarped/unrecessed .26 and .65 rings, and keep intermediate warped levels inside their original source band. This removes the skipped-corner mechanism. A same-column/same-height calculation at the witness drops the candidate radius from `273.790858` to `242.056204 m`, below the unrelieved source column's `242.606536 m`. This is a proposed-math check, not a re-review of an implemented mesh. Narrowing the header to a sampled-vertex bound is still appropriate: containment against every old displaced/twisted triangle is not proven by these knots. Clamping can place a recessed sample at a knot's height, making a horizontal ledge; it need not be a degenerate face because their radii differ.

## Geometry checks and preserved behavior

CPU reconstruction covered all six actual region `CliffMass` recipes, seeds 1–6, authored dimensions, original ring jitter, and the current .035 warp:

- 4,848 candidate wall triangles; **zero degenerate triangles and zero inward radial winding results**. Minimum triangle area was `104.134189 m²`; minimum adjacent ring height separation was `7.350952 m`.
- Exact top and bottom rings are returned. The existing clockwise Godot submission through `_add_surface_triangle` is retained. Shared side/band boundaries use the same ring arrays, including the last-to-first perimeter seam, so no independently displaced edge opens a crack.
- The level warp `t + a*sin(pi*t)` is monotonic over t for the allowed `|a| <= .08` (derivative at least `1-.08*pi > .748`), so the current sorted levels cannot cross purely because of this warp. Source ring Y still needs to be ordered; it was ordered for these six production region recipes.
- The source leaves crown generation, carved summit crown, route ribbons, crown collision/skirt, and any airborne bottom root unchanged. It only replaces the wall branch for `size.y >= 180`. This gate is size-based, not restricted to region labels; other sufficiently tall `_mesa` instances also receive the candidate. Smaller landmark/shelf mesas retain the old path.
- These probes are a JavaScript double-precision reproduction of the supplied formulas, not an execution of GDScript or a complete world export. They do not cover every non-region `_mesa` instance or prove global self-intersection freedom.

## Embedded shelves and route exposure remain capture obligations

`_build_embedded_rock_shelves` still positions outcrops at `size.x/z * .40` and geological shelf centres at `size.x/z * .44`, with their existing heights, rotations, vegetation and first-three collision bodies. They do not consult the new recessed wall. Preserving .26/.65 knots does **not** preserve overlap at every intermediate shelf/outcrop height. Maximum configured vertex contraction is 20%; on a 250 m radial section that is up to 50 m, enough to merit close inspection rather than assuming the same attachments remain embedded.

No complete imported-outcrop or nested-shelf intersection probe was performed, so this review does not claim any specific shelf has detached. Native near/mid views should establish that shelf backs and outcrop bases still enter the parent cliff, including the three unchanged colliding shelves. Likewise, unchanged roads/colliders can become visually exposed by a recessed wall; unchanged crown contact alone does not prove route-side support remains convincing. Do not move those gameplay surfaces to repair a purely visual overlap.

## Cost and settings

- Current candidate walls cost `8 bands * 2 triangles * sides = 16*sides`, or 768–848 triangles for 48–53 sides. Across the six reconstructed region masses: **4,848 versus 40,640 old wall triangles**, approximately 88.1% fewer. Crown, embedded dressing and other scene geometry are excluded. The source preserves one existing wall material surface/draw; SurfaceTool vertices remain unindexed.
- Adding the two proposed source knots would produce ten bands: `20*sides`, or 6,060 wall triangles across the same six regions, still substantially below the old wall count. No native startup/frame-time claim follows from these counts.
- Disabled/absent `wall_profile.enabled` follows the original wall path. Strength is clamped 0–1 and warp 0–.08. `recess_strength=0` is not an exact old-shape fallback: the coarse samples still skip profile corners and omit the old fine relief. Use `enabled=false` for a baseline comparison.

Final source recheck should confirm the proposed knots before making a containment claim. Native witnesses should cover shelf attachment, road-side support, crown seams, regional silhouettes and representative performance. No visual acceptance is inferred from this source verdict.
