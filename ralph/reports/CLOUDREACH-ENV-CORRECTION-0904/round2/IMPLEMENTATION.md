# Cloudreach environment correction, round 2 — 2026-09-05

Status: coherent tested candidate, not final visual acceptance. Creatures remain
excluded. No new generated or externally sourced assets were used. The first
round's blind verdict remains valid as a record of that earlier evidence.

## Changes

- Main plateau crowns now have sloped, irregular outer margins around their
  conservative playable cores. The main region's collision uses the real mesh,
  preserving the visible crown profile.
- Route cliffs use broad, irregular mountain cross-sections and rooted side
  masses, not repeated thin floating buttresses. Region companion crags and
  bedded spurs extend to the valley foundation. The isolated shrine pinnacle
  also reaches the valley; it no longer ends in mid-air above its highland.
- Cliff faces have tessellated relief, shared warm world-space stone shading,
  installed nature-family outcrops and selective physical vegetated shelves.
  Adjacent faces use equal subdivision fractions to avoid T-junction cracks.
  The three cliff bands share one rendering surface to reduce draw submission.
- Distant mountain groups contain overlapping, varied-height masses with broader
  proportions. Cloudreach overrides its local production sky profile to reduce
  cloud-edge competition while retaining the game's day-cycle mechanism.
- Trails have variable widths, irregular eroded edges and transitions. Fixed a
  concrete cover-placement bug: grass clearance used the original broad route
  width instead of the 4.2 m visible trail, leaving metres of bare texture.
- Galefoot and Cliffhold have worn connected yards, fences, domestic work and
  supply clusters, benches, planting masses and building clearance. The lower
  Candy courtyard remains accessible. Cliffhold's watchtower now marks the
  counterweight-exit destination as well as the east arrival.
- Summit Stronghold has measured coursed masonry, base plinths, tower courses,
  articulated gate buttresses, rear arcades, banners, supplies, braziers and the
  installed Team Tether relay apparatus. The last plain summit spire is replaced
  by the installed production pylon. The entrance threshold is a low walkable
  plate, not the former obstructing step.
- High Roost shrine has an inner arch, articulated pillars, approach steps,
  ancient metal armature, suspension supports and a small reflective emissive
  heart. This is environmental presentation, not a new Heart gameplay behavior.
- Near-camera grass is shortened by the cover shader, and the summit approach
  corridor is explicitly clear. The same trainer/camera/scene remains visible.

## Validation

All checks use Godot 4.7 stable in `D:/Tetherbound-source`.

- `tests/run_tests.gd -- --only=cloudreach_environment,cloudreach_world_data`:
  PASS, 15 tests / 399 assertions. The assertion count changed because cliff
  bands now share one surface; the test also enforces that batching contract.
- `tests/smoke_cloudreach_foundation.gd`: PASS, six regions, twelve landmarks,
  five bridges, procedural cover and production entry collision.
- `tests/smoke_cloudreach_arrival_walk.gd`: PASS, uninterrupted production
  controller movement through every arrival-road waypoint to Aila's offered
  interaction. Final player position approximately (-275.14, 180.00, 517.51).
- `tests/smoke_cloudreach_environment.gd`: PASS, all ten non-creature resource
  wrappers have real floors; Sunleaf remains in Fly-only High Roost; courtyard
  cover exclusion and ten horizon groups remain present.
- Scoped `git diff --check`: PASS (only ordinary LF/CRLF notices).

## Evidence and limits

`shots/` contains the same ten production route views as round 1, at 1280x720.
`contact-sheet.png` is assembled from those captured PNGs. The capture uses the
real Windows OpenGL renderer, production world, player and camera rig; it does
not use generated art, an editor camera or substitute geometry. The environment
survey hides HUD and places the player at its documented route stands; it does
not represent continuous play or establish interaction reliability by itself.

`performance.json` records actual renderer counters and 24 measured frames per
view on the GTX 1060 3GB. This is a short desktop development profile, not ROG
Ally acceptance or a sustained traversal profile. The final capture measured
552–3,843 draw calls, 1,130,266–12,337,845 submitted primitives and 3.70–13.97 ms
per frame. These are actual short desktop samples; they do not establish the
target-device budget. The occupied final-arena view is the highest submitted
geometry and slowest sample and needs continued profiling as the runtime grows.

## Residual work — do not mark the geological art gap closed

The ravine still presents a large near-continuous cliff enclosure. Its silhouette
is more irregular and has shelves/outcrops, but the broad exposed faces remain
too smooth and regular. Cliffhold's counterweight exit now shows a destination
tower, yet its close supporting crag still dominates the frame. Distant ranges
also retain a repeated layered-form tendency. These are visible art/composition
limitations, not evidence of reference parity.

The two villages have purposeful domestic groups now, but substantial open
textured terrace remains. The shrine and fortress are more developed, but the
degree of material/architectural cohesion must be assessed by the independent
reviewer. No creature, boss, Fly silhouette, finale or chapter completion claim
is made by these environmental stills.

Next highest-value work: replace the ravine's continuous corridor-skirt backdrop
and Cliffhold's close preview crag with deliberately composed, overlapping
geological masses at distinct depths, preserving all existing route/collision
and unlock contracts. Do not solve this by adding uniformly scattered props or
claiming the new material alone closes the gap. Commission a fresh code-blind
judge for any candidate proposed for acceptance.
