# Meadows relay visual pass R2 — 2026-09-11

## Scope

Second bounded pass after the fresh `7daff8378` production frames and
independent regrade kept The Tether Relay at `POLISH`. The open findings were
the lower apparatus pad's thin rectangular roof/slab silhouette, straight
prototype supports, and the hard rectangular transition between worked relay
ground and meadow.

## Candidate

- Added two stepped textured fascia courses around the apparatus pad and one
  around the gantry.
- Added capital and footing courses to the four existing pad supports.
- Added two installed `WallEntranceBricks` undercroft arch skins, one readable
  from the yard and one from the apparatus-side camera. These are visual skins
  with no collision; the existing deck, ramp and leg colliders are unchanged.
- Feathered the existing textured packed-earth pad over its outer four metres
  with vertex alpha. Its central compound floor remains fully opaque, and no
  terrain bake or collision changes.

Focused validation: 3 tests, 42 assertions, 0 failed. The focused contract now
requires three fascia courses, four articulated supports, two installed-kit
arches, and a bounded 3–5m ground feather in addition to the R1 staffing,
lighting and route-open edge checks.

## Production evidence and disposition

The first 4/4 production candidate exposed an oversized pale apparatus-side
arch that occupied too much of the close camera. That candidate was rejected;
both installed arches were reduced and recessed before the final verification.

Final production capture: 4 frames written, 0 failed.

- `shots/locations/06-relay-standing-day.png` — the stepped fascia, articulated
  supports and yard arch now make the lower platform read as built undercroft
  instead of a single black slab.
- `shots/locations/06-relay-apparatus-day.png` — the corrected arch no longer
  blocks the apparatus-side composition; machinery, supports and the layered
  roof edge remain readable together.
- `shots/locations/06-relay-road-day.png` — route, gate and occupied camp remain
  legible, with the ground-pad edge softened into meadow growth.
- `shots/locations/06-relay-approach-day.png` — approach silhouette and
  progression route remain intact.

Honest disposition: **POLISH, not PASS**. R2 closes the crude single-slab and
straight-support findings and improves the immediate ground transition. The
road-side yard is still a broad, relatively flat composition, and the pale
installed undercroft masonry remains visually simpler than the relay machine.
Those are remaining authored-environment polish gaps rather than traversal or
location-identity failures.
