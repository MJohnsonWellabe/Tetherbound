# The Old Quarry R18 — independent named-location verdict

## Verdict: POLISH — retain R18, do not promote to PASS

I reviewed `manifest.json` and all eight 1280×800 frames at native resolution,
without inspecting gameplay or capture implementation. The package is complete:
all four matched day/night views exist, the manifest reports no failures, every
stand records grounded production-scene support, and the disclosure does not claim
scene-art, collision, or progression mutation.

R18 retains a coherent quarry worksite. `02-worked-floor-*` and
`03-conduit-head-*` show a continuous dirt work area, low retaining walls, spoil,
signage, supplies, pylons, and an open haul route. The conduit establishes a clear
industrial focal line, and `04-cut-face-*` is materially better than the earlier
detached three-boulder face: its grey masses now overlap into one laterally
continuous rear boundary.

That improvement does not yet meet the strict named-location PASS bar:

| Gate | Verdict | Evidence |
| --- | ---: | --- |
| Production evidence integrity | **PASS** | Eight declared production frames are present, day/night pairs match, `complete` is true, `failures` is empty, and the player stands are grounded. |
| Arrival readability | **FAIL** | In `01-arrival-day` and especially `01-arrival-night`, a near production tree trunk and dense canopy occupy the centre and much of the right half of the frame. The arrival camera therefore hides the defining cut face and most of the worked floor even though its geometric ray checks report clear samples. At small size the destination reads as forest foreground with a partial pylon/work patch, not an Old Quarry arrival. |
| Worked-floor intentionality | **PASS with polish** | `02-*` and `03-*` establish a deliberately dressed work area with a route, retaining edges, supplies, spoil, and linked machinery. The isolated straight grey slab in `03-*` still ends abruptly in dirt, and the bright cyan cable dominates the night hierarchy. |
| Terraced excavated-face identity | **POLISH** | The joined mass in `04-*` closes the detached-boulder problem, but its uniformly rounded, smooth blocks form a low rock berm. It lacks a legible vertical cut, exposed strata, repeated working ledges, or enough height variation to read immediately as a terraced quarry wall. The trees and ordinary grassy slope still carry more silhouette weight than the excavation. |
| Day/night continuity | **POLISH** | The same structures remain locatable in each pair, but the quarry floor and dark spoil compress heavily at night. `01-arrival-night` becomes predominantly black foreground foliage, while `03-conduit-head-night` is organized more by the luminous cable than the excavation. |

The three strongest remaining gaps are:

1. `01-arrival-*`: move only the evidence lens to an ordinary, unobstructed route
   position that shows the face, worked floor, and haul path together; the current
   central tree makes the destination unreadable.
2. `04-cut-face-*`: give the connected rear mass unmistakable excavation language —
   a taller exposed cut, visible stepped working shelves, or strata-like breaks —
   instead of a uniformly rounded boulder-bank silhouette.
3. `03-conduit-head-*`: finish or visually ground the abrupt grey slab and preserve
   enough floor/face separation at night that the cable supports rather than replaces
   the quarry identity.

Against the project references: **A. No**, the set does not yet carry the key art's
clear landmark-led pastoral composition because the arrival is occluded and the
excavation has weak silhouette hierarchy. **B. No**, beside the Palworld references
the worksite dressing points toward the same kind of colorful creature-adventure
world, but the low-detail rock berm, abrupt slab, and crushed night values still read
as unfinished scene assembly. These are scene-composition and authored-landform gaps,
not evidence that a new asset family is required.

R18 is valid evidence and a real structural improvement, so the Old Quarry remains
**POLISH** rather than FAIL. The authoritative named-location ledger is unchanged.

## Review-only scope

This review adds only `REPORT.md`; it does not alter the manifest, captures,
production art, source, tests, configuration, or ledger.
