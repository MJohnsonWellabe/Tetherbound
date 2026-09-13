# Stronghold Approach — `final-stronghold-approach-04` independent visual judgment

## Verdict: POLISH — retain R4, but do not promote to strict named-location PASS

R4 clears R3's outer-arrival blocker. At the ordinary 377.33 m arrival, the opened
canopy now exposes a recognizable crenellated Hall and tower on the road axis, with
the pylon chain leading toward rather than replacing the destination. The set is a
material improvement and should replace R3 as the retained evidence.

It does not close the other explicit promotion condition. In the final night view,
the Hall facade and most of the ramp remain a near-black mass while the cyan pylon,
cable, lit creature eyes and magenta standards carry the value hierarchy. The small
cool accents on the facade do not recover its major planes or a readable ramp. Since
the named location still fails at its closest night proof, Stronghold Approach remains
**POLISH**.

## Evidence integrity: PASS, with bake provenance disclosed here

- `manifest.json` reports `complete: true`, zero failures, the production Meadows
  scene, and four distinct day/night pairs. All eight declared 1280x720 PNGs are
  present, non-empty, visually distinct, and were inspected at full resolution.
- The manifest discloses ordinary player, live Terrain3D, scatter, props,
  harvestables and encounters, collision-surface seating, pinned clock/weather and
  hidden capture UI. No progress, encounter, route or Hall content was injected.
- The capture ran from the current valid world source while a concurrent, unrelated
  Long Water terrain/vegetation edit made the serialized scatter bake stale. The
  current vegetation configuration was therefore generated at runtime rather than
  loaded from stale bins. That changes no authored Stronghold content and is
  production-equivalent for this visual judgment. The manifest says `live scatter`
  but does not spell out that transient bake state; this report preserves the supplied
  provenance explicitly rather than silently treating the bins as current.

## Strict findings

- **`01-outer-watch-arrival`: PASS and the decisive R4 improvement.** Day and night
  now show the Hall crown, crenellated wall and tower through a continuous aperture.
  The road, three stepping pylons, wildlife and destination form a legible near/mid/
  far sequence. The Hall is smaller and darker than the nearest pylon, appropriately
  for distance, but no longer absent or hidden behind a tree wall. At night its
  skyline survives against the horizon while the cable keeps the route connected.
- **`02-road-drop`: PASS for route escalation, POLISH for night modelling.** The dirt
  road and pylon rhythm lead directly to the Hall. The right-edge cropped pylon and
  cyan cable still carry excessive foreground weight, and the Hall becomes a largely
  black silhouette at night, but its fortified shape and destination position remain
  readable.
- **`03-processional-reveal`: PASS.** The bannered threshold, fenced route, Hall,
  ramp and powered occupation read as one authored faction-controlled approach. The
  night frame preserves the Hall silhouette and scattered warm/cool occupation cues.
  Its gate posts are dark and materially simple, but this does not erase the location.
- **`04-hallward-overlook`: PASS by day, POLISH blocker by night.** Day clearly
  presents the dominant Hall towers, central facade, climbable ramp, work perimeter,
  standards, pylon, creature and surrounding terrain at credible scale. At night the
  facade's small cool seams and window accents are visible, but the broad tower faces
  and ramp remain crushed together as black. The brighter pylon, cable and banners
  become the primary subjects, so the destination's architectural modelling does not
  survive the closest proof.
- **Continuity and intentionality: PASS.** The four pairs progress coherently from
  ordinary outer arrival through infrastructure corridor and occupied threshold to
  the Hall ramp. The first pair's aperture is visibly authored rather than a random
  empty scatter patch, and no frame loses the traversable route.
- **Named-location identity: POLISH.** Destination identity now begins at the outer
  arrival and holds through every daytime view. The final night hierarchy still fails
  the explicit requirement that the Hall facade and ramp separate from the powered
  furniture.

## Movement versus R3

1. **Resolved:** the 377.33 m outer arrival now exposes a recognizable Hall crown,
   wall and tower instead of ending in dense trees.
2. **Resolved:** the nearest pylon no longer acts as the only destination; its chain
   points toward a visible fortified objective.
3. **Not resolved:** at 80.89 m after dark, the Hall facade and ramp remain mostly
   black and are visually subordinate to cyan/magenta occupation elements.

## Three largest remaining gaps to the references

1. **Night architectural value separation (`04-hallward-overlook-night`).** The
   references keep the hero structure's large planes readable with selective local
   light; here the Hall and ramp fuse into one dark mass while small emissive props
   dominate.
2. **Material and silhouette refinement (`03-processional-reveal-night`,
   `04-hallward-overlook-day/night`).** The Hall's repeated square towers and broad
   planar ramp read more modular and less materially layered than the reference
   landmarks, especially once daylight texture contrast disappears.
3. **Foreground competition (`02-road-drop-day/night`).** The cropped pylon and
   high-contrast cable consume the right edge and out-rank the distant Hall more than
   the references' route furniture competes with their destination landmarks.

## Reference-bar verdict

**A. Meadows key-art world fit: yes.** The open meadow road, layered broadleaf edges,
wildlife, fortified objective and restrained faction colour belong to the intended
pastoral-fantasy world. The close night value collapse prevents strict location finish,
not overall world fit.

**B. Palworld-kind-of-game fit: yes, below strict named-location finish.** The set
clearly depicts a creature-populated journey into a large hostile landmark with a
coherent faction language. It remains less finished than the commercial reference bar
at night, where the hero architecture loses its readable surface hierarchy.

## Promotion condition

Retain R4's outer aperture and complete route sequence. A passing revision needs a
bounded local night treatment that separates the Hall's major facade planes and the
ramp from one another without raising global exposure or making the cyan machinery
brighter. No further outer-arrival camera or vegetation change is justified by these
frames.

## Review-only scope

This review adds only `REPORT.md`. The authoritative named-location ledger and its
aggregate count remain unchanged because the strict verdict is **POLISH**. No gameplay,
world source, capture tool, manifest, PNG, scene, test or runtime state was edited, and
no Godot process was launched.
