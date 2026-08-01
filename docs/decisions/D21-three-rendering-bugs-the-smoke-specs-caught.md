# D21. Three rendering bugs the smoke specs caught

Kind: implementation

Recorded because each was invisible to typechecking, invisible to unit tests,
and would have shipped.

**The error screen was always on.** `.fatal { display: flex }` is an author
rule, and any author rule beats the browser's own `[hidden] { display: none }`.
So the fatal-error overlay sat on top of a perfectly working game from the
first load, showing an empty message because nothing had actually failed. Fixed
with an explicit `.fatal[hidden] { display: none }`. Anything that sets
`display` now has to restate `[hidden]`.

**The ground rendered inside-out.** Babylon is left-handed by default, so the
triangle winding that looks correct under the right-hand rule produces a
surface facing down. The terrain was culled from above: the player floated over
a grey void with a distant horizon band, which looks far more like a camera bug
than a winding bug and cost the most time to find. Diagnosed by toggling
`backFaceCulling` at runtime in a browser session.

**Thin-instance batches inherited the wrong bounds.** A clone takes the
prototype's bounding box, which describes one small prop at the origin, so
every prop batch would be frustum-culled as soon as the camera looked away from
world zero. Bounds are now built explicitly from the chunk footprint, which is
also much cheaper than `thinInstanceRefreshBoundingInfo` walking every matrix.

Related, and worth stating because it looks like free performance:
`doNotSyncBoundingInfo` on static terrain chunks is not safe. It leaves bounds
that do not describe where the vertices are, and the chunks nearest the camera
get culled.
