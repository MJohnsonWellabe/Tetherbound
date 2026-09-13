# Old Mill Crossing — `final-old-mill-01` independent visual judgment

## Verdict: POLISH — retain, not a strict named-location PASS

The production set clearly establishes Old Mill Crossing as a real destination: a
tall half-timbered mill anchors the water cut, the road terminates in a gated timber
crossing, a wheel is attached to the mill, and signage and practical lamps make the
route legible. It is safely above FAIL. It does not yet earn strict PASS because the
mill mechanism is never shown as a convincing water-powered system and the site has
too little integrated work activity to feel like a functioning old mill rather than
a mill-shaped building placed beside a bridge.

### Evidence integrity: PASS

- `manifest.json` reports `complete: true`, eight frame records, and zero failures.
- All eight native PNGs are present, unique, non-empty 1280x720 files. Four distinct
  production camera stands each have a visibly different day/night capture.
- The manifest identifies `res://scenes/world/meadows_playground.tscn` and discloses
  an ordinary player, live Terrain3D, authoritative scatter, props, harvestables,
  crossing mechanics, and encounters. It also discloses the frozen authored clock,
  clear weather, hidden HUD/overlay, and collision-surface seating.
- It explicitly states that progress, crossing, mill, route, vegetation, and
  encounters were not injected. Per-frame player/camera and mill-distance receipts
  are present. No source SHA or per-source hashes are embedded, so the manifest
  proves production-scene/capture provenance but not commit identity by itself.

### Strict visual findings

- **Arrival and landmark silhouette: PASS.** In `01`, the road points directly to a
  tall, distinct half-timbered tower above the river valley. The strong vertical
  silhouette, masonry base, gridded windows, and attached wheel edge prevent it from
  reading as another village cottage. The mill remains recognizable at night.
- **Crossing and route: PASS.** `02` and `04` show the fenced timber span as the
  continuation of the authored road, with a clear entry threshold and readable
  opposite bank. Lamps and the lit mill window preserve the route axis at night.
  The steep, smooth-sided terrain cut beneath it is visibly procedural, but it does
  not erase the crossing read.
- **Wheel/water mechanism: POLISH blocker.** The ten-paddle wheel is physically
  attached to the mill and visible at the right edge in `02` and `04`, resolving the
  earlier disconnected-sculpture problem. No view clearly shows the wheel meeting a
  millrace, sluice, falling water, or a readable flow channel. In `03`, where the
  water axis could establish that relationship, a large foreground tree hides the
  bridge and wheel. The result is an attached wheel, not a demonstrated watermill.
- **Authored mill activity: POLISH blocker.** Barrels, benches, crates, a small work
  rack, signposts, fence rhythm, and lamps provide basic service dressing. They are
  sparse and sit as separate roadside objects; there is no strong grain/loading
  area, sack or cart flow, timber race hardware, spillway wear, or concentrated
  workyard surface to explain how the mill operates. The immediate ground remains
  predominantly ordinary meadow scatter.
- **Composition: mixed.** `01` is a clear arrival frame and `02` is the strongest
  structure/crossing frame. `04` cleanly proves the crossing axis but shows only a
  narrow edge of the wheel. `03` gives useful river context yet lets a central tree
  obscure the very mill-to-crossing relationship the angle should prove; the large
  creature cropped at the left adds further competition.
- **Day/night treatment: PASS with limits.** The four night frames preserve mill,
  road, water, bridge, window, and lamp separation without an injected evidence
  wash. The south approach in `01-night` is very dark and the wheel nearly vanishes,
  so night supports navigation more strongly than mechanism detail.
- **Named-location identity: POLISH.** A viewer can name both “mill” and “crossing”
  from the set. The remaining gap is depth and causal coherence: the building,
  wheel, water, bridge, and work site must read as one operating place.

## Promotion condition

Retain this set as the current baseline. Strict PASS requires unobstructed ordinary
player-height day/night proof that visibly connects wheel to moving water or an
authored race/sluice, plus bounded mill work/service wear that belongs to the site.
Preserve the accepted tower silhouette, road-to-crossing axis, bridge clearance,
signage, lamps, live water, and production crossing state.
