# The Rise identity R2 — production review (2026-09-11)

## Final disposition

**POLISH. Retain the improved distant/profile hierarchy; do not count a hard
PASS.** The enlarged pale wind-shaped tree now owns the upper ridge more clearly
from the route approach and west-foot profile, and the reduced three-stone group
no longer competes with the whole landform at those distances. The canonical
close road-end view is still crowded by foreground boulders, ordinary trees and
the sign, however, so the named hero does not yet control the gameplay frame.

## Evidence receipt

`manifest.json` is internally consistent and was left unchanged:

- production scene: `res://scenes/world/meadows_playground.tscn`
- named location: `The Rise`
- complete: `true`; failures: none
- eight PNGs listed and present, four authored views in day/night pairs
- every image is 1280x720
- route approach hero distance: 54.64m
- road-end/matched hero distance: 29.09m
- west-foot profile hero distance: 40.97m
- ordinary trainer, live Terrain3D, authoritative scatter/props/encounters and
  both authored roads; clear weather and frozen clocks; no injected content or
  progression

## Frame review

- `01-road-approach-night` has the cleanest distant hierarchy: the pale hero
  tree and small stone shoulder separate from the moonlit rock crown, with the
  darker ordinary tree belt below.
- `04-west-foot-profile-day/night` confirms the retained gain from another
  gameplay-scale bearing. The hero sits high against sky, the rise reads as a
  steep landform rather than a prop pile, and no new floating or road obstruction
  is evident.
- `01-road-approach-day` is too dark for a dependable commercial-daylight
  verdict. A large cloud places almost the whole landform and tree belt in heavy
  shadow even though the manifest correctly records the authored `day` clock and
  clear-weather capture setup. This is a valid production frame, not evidence of
  a bright daytime result.
- `02-road-end-crown-day/night` makes the enlarged hero canopy readable above
  the ridge, but a nearer ordinary tree fills the lower centre and another canopy
  fills the right edge. The view is vertically stacked and lacks a clean arrival
  reveal.
- `03-region-standing-matched-day/night` preserves the canonical close question
  and remains the blocker. Foreground boulders occupy the lower centre/right,
  ordinary tree masses crowd both sides, the trainer is bottom-cropped, and the
  fingerpost overlaps the rock/tree field. The hero is visible at the top but
  does not command the frame.

## What this proves and does not prove

R2 proves a bounded improvement to the tree/stone hierarchy at approximately
41–55m without changing terrain, roads or scatter. It does not prove the ordinary
29m road-end experience meets the location bar, and it does not close the broader
Meadows night-fill or cloud-exposure concern. The Rise therefore remains in the
POLISH ledger.

## Evidence-only finalization

This review adds only this `REPORT.md`. It does not modify `manifest.json`, any
PNG, gameplay/config/source/test/harness file, generated scatter or staging state.
