# Route-root support evidence

Baseline: c461d5e6f. Native diagnostic identified the floating Cliffhold clump
as ProceduralGroundCover/CoverPatch1274/Grass, indices1412,1668,2382,2908.
Roots were around(-310.2,833.7,3993.8); physical support was y832.996.
The patch is the route segment(-243.75,841.25,4036.25) to(-340,830,3970).
Its original linear height disagreed with the generated shoulder's236rows.

The repair shares the generated shoulder rows with its planting patches,
locates the containing row interval, and samples the same triangle split
used for both rendered and collidable ground. Missing support is rejected.
No mesh vertices, collision, roads, houses or camera were changed. XZ, RNG,
yaw and scale are preserved when corrected height does not change exclusions.
The exclusion broad phase now uses XZ for these patches; its existing precise
height check still separates stacked surfaces. Other patch types are unchanged.

Independent source review: route_grass_support_review identified the stale-Y
exclusion broad-phase gap. After correction, the reviewer found no remaining
source blockers. That reviewer added tests; root inspected and ran them.
Nine focused tests /1616assertions /0failed: uneven and rotated nonplanar rows,
triangle edges/outside support, real uploaded grass/flower/bush transforms
against independent engine ray-triangle intersections, and stacked exclusions.
Existing yard and role regressions also pass. Full unit suite not run here.

The intermediate native probe measured triangle height832.995963 against
physics832.995972, and832.985044 against832.985046 at the second point.
Its image was inspected: the unsupported clump moved to ground and a raised
right-side grass strip dropped. This probe preceded the exclusion broad-phase
correction; only the final after set represents the complete game diff.
The first probe inspected nearby procedural batches; its batch-origin distance
filter excluded globally rooted finish batches. The intermediate probe removed
that diagnostic filter and confirmed the actual patch data and support heights.

Shortcuts disclosed: native Windows GTX1060/Compatibility1920x1080; stationary
production rig, scripted flags/time, hidden HUD, companion parked behind camera.
These settlement diagnostics do not establish full C2, played route continuity,
motion or Ally performance. No asset generation or new reference art involved.
