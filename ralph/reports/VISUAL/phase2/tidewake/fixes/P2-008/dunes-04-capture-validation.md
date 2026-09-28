# Dunes-04 capture validation

Source recorded by all four compact manifests:
`0930716acaf88f4827576b050e782c32fb46269e`. Windows Compatibility/OpenGL3,
GTX 1060 3GB, seed 2042. All sixteen source JPGs were independently checked
as 1920×1080. The capture descriptions record fullscreen operation. These
are teleported, time-pinned visual fixtures using the production camera and
physics, not walked routes, earned progression, Ally hardware or performance
evidence. The pictures suppress the HUD; the raw manifest's generic
"ordinary gameplay HUD" disclosure does not establish HUD visibility.

| Round | Planned / captured | Complete | Capture failures | Rejected stand candidates |
| --- | --- | --- | --- | --- |
| dunes-04-before-locations | 4 / 4 | true | 0 | 0 |
| dunes-04-after-locations | 4 / 4 | true | 0 | 0 |
| dunes-04-before-routes | 4 / 4 | true | 0 | 6 |
| dunes-04-after-routes | 4 / 4 | true | 0 | 6 |

Raw manifests and images remain local under
`.artifacts/phase2/p2008-dunes-04-{before,after}-{locations,routes}/`.
Retained compact sheets and manifests are in the corresponding
`dunes-04-{before,after}-{locations,routes}/` directories beside this report.
Each contains four 320×180 tiles. All four `verify_round` checks passed.
Every raw-manifest SHA-256, source-image SHA-256, per-frame capture dictionary
and top-level capture metadata matches its retained compact record.

Before captures used both dune gates false; after capture descriptions record
only `water_dune_terrain.json` and `water_dune_cover.json` enabled. Both files
were checked false at this audit. Reproduction settings and fixture disclosures
are retained in each compact manifest; raw images are not committed evidence.

## Pair comparison

All eight required catalog sightings are present in both sets. Recorded player
XYZ and selected stand XZ match exactly in every pair. Maximum before/after
camera-position difference is **0.000011445 m**; maximum absolute camera-basis
component difference is **0.000000045**. Every accepted frame reports LAND,
on-floor, not dead and not drowning, with zero recorded horizontal displacement
from its selected stand. No equality of creature poses or all simulation state
is claimed.

| Sighting | Player difference (m) | Camera difference (m) |
| --- | --- | --- |
| First Shore welcome close | 0 | 0.000008530 |
| Shellwatch jetty close | 0 | 0.000011445 |
| Sluice pumps close | 0 | 0.000007630 |
| Gull beach close | 0 | 0 |
| First Shore horizon route | 0 | 0 |
| Brine Steps walk03 | 0 | 0 |
| Salt Crown walk01 | 0 | 0 |
| Sluice pumps route | 0 | 0 |

The two Sluice sightings are nearly the same composition, not independent
coverage of two island forms. Optional Salt Crown walk02/03 are excluded;
the catalog requires Salt Crown walk01 only.

## Corrected Brine Steps pair

Both runs rejected six candidate stands: offsets 5 m and 8 m, each at lateral
0, -5 and +5 m. The rejected receipts remain in both raw and compact manifests.
All six failed settled-displacement validation; several correctly observed
HUMAN swimming and no floor contact. They are rejected candidates, not missing
or accepted frames. The first was the old drifting stand at
XZ `(365.228027, 849.813110)`, approximately 5.56 m displaced.

The seventh candidate was accepted in both runs: offset **12 m**, lateral
**0 m**, selected XZ **`(369.056335, 843.952698)`**. Resolved ground is
`-0.307310313 m`; player XYZ is
`(369.056335, -0.284028202, 843.952698)`. This is a supported shallow-water
land stand, not a dry beach claim. Both snapshots report LAND, on-floor and
floor-normal Y `0.945744395`, with no death or drowning. Camera XYZ is
`(371.838074, 2.547115, 839.694397)` and player/camera separation is
`5.821217060 m` in both captures. Stamina fractions differ slightly after the
failed swim candidates (`0.7634` before, `0.7662` after); body/camera matching
does not imply identical resource histories.

This fresh supported before/after pair replaces the invalid older Brine
comparison. It does not rehabilitate the old drifting image or prove traversal.

## Visual disposition and scope

[Independent visual review](dunes-04-visual-judge.md) inspected all sixteen
native images and four sheets. **P2-008 PARTIAL; surface direction PASS;
coastal ecology/transitions PARTIAL; limited regional Bars A/B No/No.**
Remaining defects include angular pale cap/bank boundaries, smooth steep
island spans, regular grass ribbons/fans, weak midground structure and thin
shore-to-interior ecological transitions. Creature and distant-landmark gaps
remain visible but are not silently converted into acceptance of other items.

Veilfall's separate terrain treatment and static mountain vegetation/authored
groves remain excluded from the dune replacements. The shared camera-relative
ground-grass profile can still affect eligible flat grass at Veilfall; this
round contains no Veilfall stand and proves no blanket Veilfall exclusion.

The evidence completes the eight-sighting comparison, not the item, chapter,
motion, popping, traversal or performance acceptance. Both dune gates remain off.
