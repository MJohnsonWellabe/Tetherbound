# Meadows Pond visual pass R2 — 2026-09-11

## Scope

Bounded follow-up to the current `POLISH` grade for **The Pond**. Fresh
full-resolution production frames retain a strong mill/pond destination but
show two specific gaps: the large hero water wheel reads as flat brown
primitives against the textured half-timber building, and a mature near-field
canopy fills the left third of the fixed route-head approach and obscures the
ranger-station/mill reveal.

## Candidate

- Retained the existing 4.7m wheel, ten spokes, ten paddles, axle, wash and
  placement. Added installed medieval wood albedo/normal/roughness via triplanar
  mapping, a restrained iron tyre, ten fastening straps and paired hub plates.
- Added one 14m Band 1 vegetation clearing around both the authored route-head
  waypoint and actual pulled-back camera/ordinary arrival corridor. It removes only tree/rock
  obstruction; grass and flowers remain, and existing mill, ranger, camp and
  far-bank grove clearings are unchanged.
- No building, bridge, pond, terrain, water, route, collision, encounter or
  progression position changed.

## Validation and evidence

Focused validation passed before the first production capture: 9 tests, 213
assertions, 0 failed. That capture wrote 3/3 frames. Full-resolution review
accepted the wheel-side material/construction improvement but rejected the
approach result: the 9m camera-only opening left the next canopy band directly
across the sightline. The corrected route-head clearing is now 14m and centred
on the authored waypoint, covering both waypoint and pulled-back eye. A second,
8m sightline lens sits at (-365,505), within 2.2m of the exact 75% point from
camera (-320,484) to mill (-382,514). It only bridges the measured seam between
the existing ranger r10 and mill r15 clearings; it does not widen the shoreline
or far-bank opening. Final approach reproof is pending the renderer queue.

The corrected production reproof completed with **3/3 frames written, 0
failed**:

- `shots/locations/02-mill-pond-approach-day.png` — the real route-head view
  now opens cleanly onto pond water, ranger station and the mill tower, with
  mature canopy retained as a frame on both sides rather than covering the
  destination.
- `shots/locations/02-mill-pond-standing-day.png` — the accepted tall
  half-timber landmark, people and outbuilding remain unchanged; the darker
  textured working assembly reads behind the mill's left edge.
- `shots/locations/02-mill-pond-wheel-day.png` — wood grain, iron tyre, ten
  straps and paired hub plates give the retained wheel a believable material
  and construction hierarchy against the textured building.

Honest disposition: **PASS for the bounded Pond gaps**. The crude flat-brown
wheel and obstructed route reveal are both materially closed without thinning
the wider pond pocket or changing traversal/geography. Ordinary polish remains:
the standing angle is intentionally building-led rather than water-led, and the
wheel remains a static environmental assembly.

Final focused validation after the corrected lens: **9 tests, 220 assertions,
0 failed**. `git diff --check` is clean.
