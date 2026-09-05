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

## 4. Addendum, same day: the collider is not the mesh

Growing the trees caused one real, player-facing regression, caught by the landing
lane's `smoke_aggression` run and reproduced here: the scripted walk toward the
aggressor stalls at 53.7 m and never arrives. `tools/_probe_walk_block_0905.gd` walks
the same line with the same held input and names the blocker instead of guessing —
at (40.54, −65.82) a step in any direction is `test_move`-BLOCKED by
`CommonTree_1_Collision`, a trunk cylinder of **r = 1.21 m** whose axis is 1.61 m away.
That leaves a 0.40 m gap, narrower than the player. The same instance carried
**r = 0.89 m** before this lane. Nothing moved — the tree got wider.

The mechanism: `vegetation.gd::_make_collision_shape` sizes the trunk cylinder as
`collision_radius × placement scale`, so the obstacle grows with the mesh, and the
part of a tree a walking player actually touches is its widest — the root flare in
the model's lowest metre, which for a 2× tree is the lowest half-metre of local space.

**Decision: decouple collider growth from visual growth.** `collision_radius` is
scaled down by exactly the factor `scale_max` was scaled up — `trees` 0.6 → 0.435
(× 1.45/2.0), `grove` 1.1 → 0.70 (× 1.15/1.8). The consequence is the property that
matters: **the widest collider in the world is now identical to the widest collider
`main` already shipped** (0.974 m for the common fill, 1.071 m for the grove), and
every other instance's collider is strictly smaller than it was before. No tree
anywhere can block a line `main` did not already block.

The alternative — trimming `scale_max` back — was rejected: it undoes the lane, and
`CLAUDE.md` says grow, never shrink.

**The collider was never a snug fit, measured rather than assumed**
(`tools/_probe_trunk_radius_0905.gd`): the CommonTree trunk's own radius over its
lowest 2 m is **0.741 m** at scale 1.0 and TwistedTree_2's is **1.351 m**, so 0.6 and
1.1 were both already inside the visible trunk, and 0.435 and 0.70 still are relative
to their families. The honest cost: a player brushing the very largest trunks clips a
little further into the bark than before. That is a better trade than a wall across a
route the game asks players to walk.

**The general lesson for the next lane that scales a scatter layer:** in this codebase
a layer's visual size and its collision size are the same number. Changing one changes
the other, and the test that catches it is a walk, not a render.
