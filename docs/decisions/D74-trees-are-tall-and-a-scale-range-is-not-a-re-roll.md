# D74 — Trees are tall, and a scale range is not a re-roll

**Date:** 2026-09-04 · **Decided by:** lane W05-TREELINE-0904, under the COMMON
lane rule ("make the smallest defensible call, record it, continue"), implementing
`docs/FINISH_THE_MEADOWS.md` §1.2 and closure plan CL-B2's tree slice.

## 1. The finding that unblocks the item

Three documents claimed widening the `trees` layer's corridor-wide
`scale_min`/`scale_max` would re-roll the whole corridor's RNG stream, and the item
was declined on that basis for weeks. Checked against
`scripts/world/scatter_rules.gd::_consider` on 2026-09-04: the scale, model and yaw
draws happen unconditionally, in that fixed order, after every rejection test, and
nothing reads the scale before them. A wider range consumes the same draws, so every
placement, model and yaw is identical and only the sizes change. `vegetation.json`'s
own Band 2 note had said exactly this. What genuinely re-rolls: an anchor's `count`,
a per-layer `band_scale`, a layer `seed_offset`, the top-level `seed`. Those were not
touched.

## 2. The size hierarchy, in metres against the 1.80 m trainer

Measured off the committed bake with `tools/_probe_tree_heights_0904.gd` before the
change: corridor-fill common trees p5 4.2 m, median 7.7 m, p95 12.4 m; 6.6 % cleared
12 m; the p5–p95 spread was 2.98×. Two blind judges read those lines as "one lollipop,
repeated".

Decided ranges (all "grow, never shrink": no `scale_min` moved down):

| Family | Layer key | Was | Now | Tallest instance |
|---|---|---|---|---|
| common broadleaf fill | `trees.scale_min/max` | 0.5 – 1.45 | 0.5 – 2.0 | CommonTree_3 18.9 m, _1 16.3 m, _2 13.1 m |
| lone landmark common | `trees.heroes` | 1.7 – 2.1 | 2.2 – 2.7 | CommonTree_3 25.5 m |
| ancient oaks / cherry | `grove.scale_min/max` (× base 0.85) | 0.6 – 1.15 | 0.6 – 1.8 | TwistedTree_2 29 m, CherryBlossom_3 22 m |
| grove heroes | `grove.heroes` | 1.15 – 1.35 | 1.6 – 1.9 | TwistedTree_2 30.6 m |
| dead trees | `deadfall.scale_min/max` (× base 0.7) | 0.45 – 1.15 | 0.45 – 1.6 | DeadTree_3 14.9 m |
| mushrooms (same layer) | `deadfall.model_scale` | — | 0.72 | held at their previous top |
| saplings | `saplings` | 0.25 – 0.5 | unchanged | 4.7 m — the understorey stays young |

Band 1's authored `trees` anchors that carry their own range (the TREE-SILHOUETTE
copse peaks and bodies, the frame trunk, the crest pair, the comp4 pin, the basin and
far-rim treelines, station 04) are lifted by the same 2.0/1.45 factor so each composed
silhouette keeps its relationship to the fill around it. Shoulder pairs (deliberately
young, `scale_max` ≤ 0.85) are untouched. Bands 2–5 anchors are untouched: the judged
stands are Band 1's, and those anchors' job (fill an empty part of a frame) is not
changed by their neighbours growing.

The ordering is the point: common fill tops under 19 m, a lone common hero stands above
the fill, an ancient oak stands above the hero. The old file's own words — the grove is
"at twice the height of a common tree" — only stay true if the grove grows with the
fill.

## 3. What this does not decide

Whether the installed trunk-plus-blob forms can ever read as oaks (closure plan
CL-A1's "one branching tree form, with reference art") is untouched. This is scale and
spread inside the installed nature family, nothing more.
