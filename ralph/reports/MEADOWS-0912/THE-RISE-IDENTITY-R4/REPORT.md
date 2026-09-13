# The Rise identity R4 review (2026-09-12)

## Verdict

**POLISH — do not promote The Rise to named-location PASS.** R4 preserves the
accepted wind-shaped crown and fixes R3's duplicated evidence composition, but
the submitted pixels still do not make the road-end-to-crown climb unmistakable.
The route disappears into a steep, largely unmarked grass/rock face; the sparse
dark stones do not resolve into a continuous trail or cairn sequence in either
day or night views.

## Evidence integrity

- `manifest.json` reports `complete: true` with no failures, and all eight listed
  1280x720 PNGs are present as four matched day/night pairs.
- The disclosure identifies the production Meadows scene, ordinary trainer,
  live Terrain3D, authoritative scatter/props/encounters and authored roads. It
  explicitly says the installed trail and fork torch are production content and
  that no scene content, light, material, pose or progression was injected.
- Frame roles, player positions and hero/fork distances are populated. As in R3,
  the manifest supplies no mechanical camera collision/occlusion certificate;
  native inspection shows no obvious invalid camera placement, so this remains
  a proof-strength caveat rather than an evidence invalidation.

## Native-frame findings

- `01-road-climb-approach`: the maintained road is finally visible in the lower
  foreground and the crown tree remains identifiable at 63.71 m. However, the
  road does not visibly continue onto the hill. The day frame is again nearly
  night-dark across the landform, while its night mate is substantially brighter
  and cooler, so R3's unstable day/night value problem is not resolved.
- `02-road-end-trailhead`: daylight is clear enough to inspect the surface, but
  it shows a broad, steep bare mound rather than an obvious trailhead. The few
  dark stones are isolated and read as ordinary scatter; there is no readable
  line from the road end toward the crown. Night preserves terrain separation
  but does not reveal the route.
- `03-west-foot-climb`: this is now a genuinely distinct side composition, so the
  R3 near-duplicate blocker is fixed. It nevertheless presents a steep diagonal
  hillside with trees and rocks, not a confidently walkable authored shelf or
  climb. The near ground collapses heavily at night and the large white moon
  keeps the presentation harsh.
- `04-crown-arrival`: the single wind-shaped hero tree remains the clean focus in
  day and night and the close crown is not re-obstructed. The low uphill framing
  shows only an undifferentiated final mound, however, so it proves the retained
  crown identity rather than an arrival path into it.

## Promotion boundary

R4 earns retention for its intact crown and four compositionally independent
views. PASS still requires a plainly continuous, walkable visual route from the
maintained road through the trailhead/contour shelf to the crown, visible without
manifest labels, plus stable daylight and calmer night values. The Rise therefore
remains **POLISH**, not FAIL: its named hero landform is recognizable and the
evidence set is valid, but its required crown/trail pair is not yet proven.

## Review-only scope

This review adds only `REPORT.md`; it does not modify evidence, production,
configuration, tests, capture code, generated scatter or staging state, and no
Godot process was run.
