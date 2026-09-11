# Cloudreach shared environment diagnosis — 2026-09-11

Status: **implementation recommendation only; production remains FAIL**.

This diagnosis uses the current R4 route-ecology production frames, especially
Three Bells, Windscar, Cliffhold, Old Wind Observatory, and Summit Eyrie. It
also respects the accepted R1 route-ecology disposition and the withdrawn
grass-tip, grass-arc, and upland-material experiments. No Godot run, render,
shared-world edit, staging, or commit was performed for this diagnosis.

## Root causes

### 1. Dirt polygons are exposed visual-mesh footprints, not primarily bad dirt

The route trail and inhabited-ground builders place several independent meshes
slightly above the real turf. Both `cloudreach_trail.gdshader` and
`cloudreach_worn_ground.gdshader` paint a procedural approximation of the turf
over the part of each visual mesh that is not dirt. That approximation does not
match the underlying crown pixel-for-pixel: it has a different mesh normal,
height, draw, and sometimes a different dry/wet binding. Consequently the
supposedly grassy part of each overlaid triangle remains visible. At Cliffhold,
the communal yard, house thresholds, service patches, watch apron, and path
ribbons overlap, exposing a field of large angular green/brown polygons. The R4
Cliffhold day frame is the clearest proof.

The route builder compounds this at joints. `_path_ribbon` creates a new ribbon
for every ground section and computes endpoint distance independently for each
one. It therefore buries and fades every internal section endpoint as if it were
the end of the route. The collision ribbon is separate and already hidden, so
this is a presentation defect; it does not require a traversal change.

### 2. Cliff repetition is authored by an exact realm-wide band function

The near cliff shader calculates a world-Y band with `floor`, alternates every
second band, and applies an ochre/moss tint on a fixed three-band cadence. Even
at the configured five-percent strength, the same horizontal frequency crosses
every large vertical mass. The generated masses then reuse similarly broad,
upright faces and flat turf caps. The result is the repeated pale striping and
table-top silhouette visible behind Windscar, Cliffhold, and the Observatory.

The withdrawn upland-material candidate is not evidence against this diagnosis:
that experiment changed crown texture definition, not the exact cliff-face
periodicity or macro silhouette.

### 3. Grass now has enough instances but the wrong silhouette hierarchy

The accepted route-ecology pass correctly added mid-distance cover and should be
retained. The remaining failure is not blanket density. The procedural cover
still uses the Meadows seven-blade tuft, then forces grass X/Z scale into a
fixed `1.6..2.3` range even when route wear reduces Y scale to 30–68 percent.
That creates short-but-very-wide crossed blades at route edges and large
waist-high lattices elsewhere. The R4 Three Bells and Windscar frames show both
failure modes. Clustering also gates whole individual tufts rather than
composing low cover, medium masses, and sparse tall accents, so the terrain
alternates between bare lawn and blade walls.

The two matched grass-tip ties and the grass-arc judgment mean taper and another
single density/curve knob are exhausted. A useful next pass must change the
height/width hierarchy and distribution representation, not retune tip shape.

### 4. Flat cloud cards are a mechanism limit

The cloud sea scatters 760 independent flattened `SphereMesh` instances, each
at roughly the same relationship to the sheet. Random radius and squash change
size but do not make cloud bodies: distant instances still project as detached
white ellipses. Their opaque lit material stays a high-value cutout at day and
night. The current frames repeatedly show this across the main valley view.

The Cloudreach cloud mechanism has already spent four render rounds and three
blind judgments. More count, radius, flatten, colour, or emission tuning is not
justified. The implementation unit must be a clustered cloud-bank mechanism,
not another configuration sweep of the present individual billows.

## Ranked implementation plan

### 1. Replace turf-painted wear overlays — highest leverage, low-to-medium risk

Make visual wear a true coverage overlay. Outside the dirt/wear mask, discard
the fragment (or use a stable alpha-hash coverage edge) so the real crown shows
through; do not shade an imitation turf pixel on the overlay mesh. Apply the
same coverage contract to route ribbons and worn settlement patches.

Then build one continuous visual ribbon per authored route polyline, splitting
only across real bridge omissions. Use bevelled joins (or a conservative miter
limit), continuous longitudinal distance, and endpoint fade only at the true
route/bridge endpoints. Keep the existing hidden controller collision ribbons,
route coordinates, widths, exclusions, and surface queries unchanged.

Acceptance evidence: matched day/night frames at Cliffhold and Three Bells,
plus one long turning route at Windscar. Reject if any overlay polygon remains,
if joins darken from double blending, or if a visible seam replaces the current
overlap. Run existing route/crown traversal tests because the builder is shared,
even though collision should remain untouched.

### 2. Replace independent cloud billows with authored clusters — very high visual leverage, high risk

Retain the safety-owned `CloudSea` node and its height/fall-recovery contract.
Replace only the upper decorative billow scatter with approximately 80–120
deterministic banks. Each bank should contain several overlapping lobes with a
shared centre, at least three height tiers, non-uniform horizontal offsets, and
a broad low body that intersects the deck. A soft depth/fresnel edge material
should provide a shaded base and must inherit night exposure rather than remain
near-white. Keep the current clearance clamp and visibility range.

Acceptance evidence: matched day/night downward vistas from Three Bells,
Windscar, Observatory, and a summit rim. Reject any repeated ellipse chain,
opaque card edge, bright night cutout, or cloud mass above walkable ground.
Because earlier parameter rounds are exhausted, do not ship this without blind
image review.

### 3. Break exact cliff periodicity before resculpting geometry — broad leverage, medium risk

First make strata spatially intermittent rather than deleting all geological
read. Warp band phase with low-frequency XZ noise, multiply band strength by a
large irregular face mask, and remove exact alternating/three-band parity as the
main colour selector. Preserve moss on upward-facing shelves. This is an
isolated shader/config experiment and is cheaper than rebuilding all masses.

If matched Windscar/Observatory frames still read as banded drums, the next unit
is geometry: add two or three silhouette profiles (split shoulders, sloped
buttress, broken crown) selected by seed, while retaining the crown/collision
height model. Do not change region bounds or walkable crowns to solve a distant
silhouette issue.

### 4. Rebuild grass as three height roles — broad leverage, medium risk

Retain the accepted route-verge stations and asset-family rule. Replace the
fixed grass width override with width proportional to height and clamp it to an
art-directed range. Allocate most instances to embedded low cover, fewer to
medium tuft masses, and a small fraction to tall accents. Tall accents should
occur in irregular clumps away from the route centre; they must not form a
continuous wall. Reduce high-contrast tip lift so distant fields read as masses,
not lime linework.

Acceptance evidence: matched Three Bells and Windscar day/night frames at
trainer scale, plus a bare-prone Gate frame. Reject if route shoulders become
parallel rails, if low cover exposes more lawn, or if foreground blades obscure
the trainer. Do not revisit point taper or the retired grass-arc candidate.

## Why no isolated production candidate is included

No single unwired shader file can safely close the observed shared defect. The
apparently smallest fix—transparent wear overlays—changes depth, sorting, and
overlap behavior at every route and settlement patch, and must be mounted in the
shared material/world path to be meaningful. The cliff shader is biome-wide;
the cloud fix explicitly requires a new scatter mechanism; and the grass issue
requires mesh/instance-role changes. Implementing any of these blind while the
render lane is occupied would repeat the repository's already-documented
no-visible-improvement experiments. The first bounded implementation unit
should therefore be item 1 with matched production captures, not an unmounted
candidate claimed as progress.
