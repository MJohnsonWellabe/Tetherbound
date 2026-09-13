# Stronghold Approach — `final-stronghold-approach-03` independent visual judgment

## Verdict: POLISH — do not promote; retain R2 as the strict baseline

R3 is valid production evidence, and its middle sequence still establishes a coherent
faction-controlled road leading to Meadows Hall. It does not clear R2's promotion
condition. The replacement outer arrival moves roughly 183 m closer to the Hall yet
still contains no recognizable Hall crown, wall, gate, or fortified threshold; it
reads as a wooded road with pylons and wildlife. The final night frame still renders
most of the Hall facade and ramp as a black silhouette. Because R3 gives up R2's
canonical 560 m arrival without recovering destination identity, it should not replace
R2 as the retained evidence baseline and Stronghold Approach remains **POLISH**.

## Evidence integrity: PASS

- `manifest.json` reports `complete: true`, zero failures, the production Meadows
  scene, and four distinct day/night pairs.
- All eight declared 1280x720 PNGs are present, non-empty, and have eight distinct
  SHA-256 hashes. All eight were inspected at full resolution.
- The disclosure retains ordinary production Terrain3D, scatter, props,
  harvestables, encounters, collision seating, and the player. Clock/weather pinning
  and hidden capture UI are disclosed. No progress, encounter, route, or Hall content
  was injected.

## Strict findings

- **`01-outer-watch-arrival`: POLISH blocker and evidence regression.** At the
  recorded 377.33 m Hall distance, the camera shows a pleasant but generic tree-lined
  road, two pale creatures, and two pylon fragments. Dense trees close the forward
  axis, and no stronghold architecture is visible in either clock. At night the road,
  creatures, and most vegetation collapse toward black while the cyan cable becomes
  the only strong destination cue. Moving this proof closer than R2's 560 m arrival
  without revealing the Hall weakens route-scale coverage rather than closing the
  landmark-hierarchy blocker.
- **`02-road-drop`: strongest R3 improvement, still POLISH.** The distant crenellated
  Hall silhouette now sits directly on the road axis and is readable by day. Repeated
  pylons make the controlled route clear. The cropped foreground pylon at frame right
  and its cable still carry more visual weight than the Hall, however, and at night
  the architecture becomes a small black skyline while the moon and cable dominate.
- **`03-processional-reveal`: PASS for identity, POLISH for finish.** The bannered
  gate, fenced road, rising Hall, and downstream faction markers make the destination
  unmistakable. The left tree mass occupies nearly half the frame, the foreground
  gate is materially simple, and the night version loses the banner colour and most
  of the Hall's stone modelling.
- **`04-hallward-overlook`: PASS by day, POLISH by night.** Day clearly presents the
  Hall towers, ramp, occupied threshold, standards, fenced machinery, creature, and
  surrounding terrain at credible scale. At night the bright pylon, cyan cable, and
  magenta standards survive, but the Hall facade, ramp, and lower occupation planes
  remain largely crushed into black. The bounded facade retune has not made the
  architecture readable enough to close R2's night blocker.
- **Continuity and intentionality: PASS.** Frames `02` through `04` form a convincing
  escalation from machinery corridor to bannered threshold to fortified ramp. The
  oxblood/cyan faction language is consistent, wildlife remains present, and no new
  obstruction defeats the traversable route.
- **Named-location identity: POLISH.** The back three pairs are increasingly specific,
  but a strict named-location pass requires the ordinary outer arrival and both clocks
  to sustain the destination hierarchy. R3 does neither.

## Regressions versus R2

1. R3's first pair no longer proves the canonical 560 m outer arrival; it starts at
   377.33 m, reducing route coverage by about 183 m.
2. Despite that closer position, dense trees remove the open processional vista and
   the Hall remains completely absent from the first pair.
3. Night readability remains materially unchanged at the destination: Hall stone and
   ramp planes are still substantially less legible than the powered infrastructure.

## Reference-bar verdict

**A. Meadows key-art world fit: yes.** The broadleaf road, bright meadow, creatures,
fortified stone objective, and faction colour belong to the intended pastoral-fantasy
world. The blocked outer landmark read and crushed night values prevent closure.

**B. Palworld-kind-of-game fit: yes, below strict named-location finish.** The set
shows a traversable creature-populated route toward a large hostile objective, but the
commercial reference bar expects the destination silhouette to lead the composition
before close range and its major planes to remain readable after dark.

## Promotion condition

Retain R2's baseline and its clear middle/final progression. A passing revision still
needs an honest ordinary-player outer arrival in which a Hall crown, wall, gate, or
fortified threshold visibly outranks the pylon furniture, plus local night modelling
that separates the Hall facade and ramp without adding a global exposure change.

## Review-only scope

This review changes only this report. The authoritative ledger remains **POLISH** and
the current aggregate count is unchanged. No gameplay, source, capture tool, manifest,
PNG evidence, scene, test, or runtime state was edited, and no Godot process was
launched.
