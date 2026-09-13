# Stronghold Approach — `final-stronghold-approach-05` independent visual judgment

## Verdict: POLISH — retain R5, but do not promote to strict named-location PASS

R5 materially improves the closest night view: the Hall's tower faces, crenellations,
scaffolds and central masonry now remain readable as stone instead of collapsing into
R4's near-black silhouette. The treatment is bounded to the architecture; it does not
look like an unmotivated global wash, and neither the pylon nor its cable has been
brightened into a larger distraction.

The explicit R4 promotion condition is nevertheless only partly closed. In
`04-hallward-overlook-night`, the broad climb surface remains an almost solid black
wedge from the foreground to the Hall. Its tread/grade cannot be read, and it still
fuses at the upper landing with the dark central entrance. Because the closest night
proof does not preserve both the façade **and** the traversable ramp as separate major
planes, Stronghold Approach remains **POLISH**.

## Evidence integrity: PASS

- `manifest.json` reports `complete: true`, zero failures, the production Meadows
  scene, and four distinct day/night pairs. All eight declared 1280×720 PNGs are
  present, non-empty and were inspected at full resolution.
- The disclosed fixture is the ordinary player in the production Meadows scene with
  live Terrain3D, scatter, props, harvestables and encounters, collision-surface
  seating, pinned clock/weather and hidden capture UI. No route, encounter, progress
  or Hall content was injected.
- The route is shown continuously from a normal 377.33 m outer arrival through the
  311.26 m road drop and 182.73 m processional reveal to the 80.89 m Hallward view.

## Strict findings

- **`01-outer-watch-arrival`: PASS.** At both clocks, the road, repeated pylons,
  wildlife and the distant fortified crown form a readable near/mid/far sequence.
  The Hall survives against the night horizon and is not replaced by the machinery.
- **`02-road-drop`: PASS.** The road and descending pylon rhythm pull directly toward
  the Hall. The cropped right pylon and cable remain assertive, but do not erase the
  destination or indicate a new R5 regression.
- **`03-processional-reveal`: PASS.** The bannered threshold, fenced route, ramp and
  Hall read as one occupied approach. At night the Hall is still dark at this range,
  but its silhouette, warm interior points and route infrastructure remain legible.
- **`04-hallward-overlook-day`: PASS.** The large Hall, ramp, work perimeter,
  standards, pylon and surrounding grove form a clear final approach at credible
  gameplay scale.
- **`04-hallward-overlook-night`: POLISH blocker.** R5's warm cross-light models the
  tower faces and reveals material detail without producing a broad wash. The main
  ramp surface, however, stays nearly black from bottom to top; only its rails and
  small edge accents survive. It reads as a dark wedge rather than a climbable plane
  and merges into the central threshold at the landing.
- **Lighting motivation: PASS.** The added value is selective and architectural. The
  surrounding forest, field and sky keep their night values, while the pylon/cable are
  no brighter than in the retained R4 frame.
- **Continuity and identity: PASS except for the named night blocker.** All four pairs
  preserve the same authored road-to-fortification escalation. Stronghold identity is
  never lost; the remaining failure is the closest view's traversal readability.

## Movement versus R4

1. **Resolved:** the Hall façade is no longer a single near-black mass at 80.89 m;
   tower stone, crenellations, scaffolds and the central wall remain visible.
2. **Resolved:** the correction is locally motivated rather than a broad exposure
   increase, and it does not amplify the cyan pylon or cable.
3. **Not resolved:** the closest night ramp remains a nearly uniform black surface and
   still does not separate cleanly from the Hall entrance at its upper landing.

## Three largest remaining gaps to the references

1. **Night climb readability (`04-hallward-overlook-night`).** The references retain
   major route planes through selective practical light and material contrast; here
   the climb becomes a black wedge even though the façade above it is now modelled.
2. **Modular architectural finish (`03-processional-reveal-day/night`,
   `04-hallward-overlook-day/night`).** Repeated square towers, planar ramp sections
   and exposed scaffold modules read less materially integrated than the reference
   landmarks.
3. **Foreground competition (`02-road-drop-day/night`).** The cropped pylon and bright
   cable still pull strongly at the right edge relative to the distant Hall.

## Reference-bar verdict

**A. Meadows key-art world fit: yes.** The meadow road, layered woodland, creatures,
fortified silhouette and restrained faction colour belong to the intended pastoral
fantasy world. The remaining ramp defect is local rather than a rejection of the
overall visual language.

**B. Palworld-kind-of-game fit: yes, below strict named-location finish.** This reads
as a creature-populated approach to a large hostile landmark with a coherent route and
faction identity. The commercial reference bar preserves clearer playable-surface and
landmark modelling at night than the final R5 frame does.

## Promotion condition

Retain R5's outer arrival, sequence and bounded façade modelling. A passing revision
must reveal the broad ramp plane and its upper landing enough to read as traversable,
without increasing global exposure or making the cyan machinery brighter. This is a
local ramp/landing treatment; no new camera, outer vegetation or façade-wide wash is
justified.

## Review-only scope

This review adds only `REPORT.md`. The authoritative named-location ledger, aggregate
count and ledger test remain unchanged because the strict verdict is **POLISH**. No
gameplay, world source, capture tool, manifest, PNG, scene, test or runtime state was
edited, and no Godot process was launched.
