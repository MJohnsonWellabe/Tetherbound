# The Old Quarry R19 — independent named-location verdict

## Verdict: POLISH — retain R19, do not promote to PASS

I reviewed `manifest.json` and all eight 1280×720 production frames at native
resolution, without inspecting source or capture implementation. The evidence set is
complete: all four matched day/night views exist, the manifest reports no failures,
and every player stand records grounded support. The disclosure does not claim scene
mutation during capture.

R19 materially improves the arrival. In `01-arrival-*`, the defining rear rock mass is
now exposed beside the route instead of disappearing behind the former central tree and
canopy wall. The lamp gives it a stable night anchor. `04-cut-face-*` also presents a
more continuous and taller boundary than R18, and the worksite retains useful dressing:
haul paths, retaining edges, spoil, supplies, signs, pylons, and a worker.

That improvement is not yet sufficient for the strict named-location PASS bar:

| Gate | Verdict | Evidence |
| --- | ---: | --- |
| Production evidence integrity | **PASS** | Eight declared production frames are present, day/night pairs match, `complete` is true, `failures` is empty, and all player stands are grounded. |
| Arrival readability | **POLISH** | `01-arrival-*` now exposes the destination and clears the R18 occlusion blocker. However, the pale, nearly textureless rock mass reads first as a large placed slab or bunker-like mound; its shallow upper steps do not yet make excavation activity immediately legible. The heavy right-edge trunks still compete for roughly a third of the composition, but no longer hide the subject. |
| Terraced excavation identity | **POLISH** | `04-cut-face-*` shows a continuous cut with improved height, yet its broad smooth faces and rounded low-poly modules resemble an assembled rock barrier. There are no convincing repeated working ledges, exposed strata, tool marks, or a cut-to-floor relationship. The lone shallow cap tiers visible in `01-*` are not carried through the interior views. |
| Worked-floor intentionality | **POLISH** | `02-*` and `03-*` contain authored worksite detail, but neither frame visually connects the floor to the rear cut. `02-*` faces a forested rise and pylon; `03-*` faces another forested path, so the core quarry operation is outside the frame. The straight grey slab in `03-*` still terminates abruptly in dirt and reads unfinished. |
| Day/night continuity | **POLISH** | Landmarks remain locatable across pairs, and the new cut is more legible in `01-arrival-night`. But `02-worked-floor-night` compresses the dark spoil and floor into near-black masses, while `03-conduit-head-night` is still organized by the luminous cyan cable rather than excavation form. |

## Three strongest gaps from the references

1. **Excavation silhouette and material language — `01-arrival-*`, `04-cut-face-*`.**
   The Meadows key art and the supplementary BOTW landmark comparison establish forms
   through layered silhouettes, material breaks, and terrain integration. R19's rear
   face is a smooth sequence of similarly grey modules with only token cap steps, so it
   reads as placed geometry rather than a tall, worked cut.
2. **A complete worksite composition — `02-worked-floor-*`, `03-conduit-head-*`.**
   Palworld's base and destination frames connect route, activity, props, and defining
   structure in one readable view. R19 has those ingredients but separates the defining
   cut from both interior worksite views; the viewer sees scattered construction and
   pylons without seeing what is being excavated.
3. **Night value hierarchy and finish — `02-worked-floor-night`,
   `03-conduit-head-night`.** The references preserve major terrain planes and route
   readability after dark. Here the floor and spoil collapse together, the cyan cable
   becomes the dominant line, and the bright straight slab remains an abrupt unfinished
   endpoint.

## Binding bar questions

**A. Does this belong to the world in the Meadows key art? No.** The surrounding oak
forest, wildflower ground, sky, and warm route palette belong to the same broad world,
but the quarry itself lacks the key art's authored landform hierarchy and integrated
material detail. The defining cut still reads as inserted modular geometry rather than
a place carved out of this terrain.

**B. Beside the Palworld references, would someone say this is trying to be the same
kind of game? No.** The colorful third-person world and dressed activity area point in
that direction, but the separated composition, smooth blockout-like excavation face,
crushed night floor, and unfinished slab keep the named location below the same
shipping-quality register.

For clarity, the Meadows key art and Palworld comparisons above are the binding bars.
BOTW's readable landmark/terrain integration is supplementary only. All remaining gaps
are fixable in-engine through scene composition, excavation geometry/material breakup,
floor-to-cut continuity, and restrained night hierarchy; this evidence does not imply a
need for a new asset family.

R19 remains **POLISH**. The authoritative named-location ledger and its aggregate count
are unchanged.

## Review-only scope

This review adds only `REPORT.md`; it does not alter the manifest, captures,
production art, source, tests, configuration, or ledger.
