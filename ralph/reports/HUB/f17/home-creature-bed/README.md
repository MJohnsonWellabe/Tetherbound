# Home creature bed (owner ruling 2026-10-04)

One free creature bed at Grandpa's house: the installed `creature_bed.gd` nest, built through rest_point's
path (`build_real(false)`, reserved index -40), so it carries the same occupancy and heal path, the same
multiplayer and save semantics, and no new mesh.

## Function: PASS
`tests/smoke_home_creature_bed.gd`, 12/12 PASS on 46da85cb:
- the bed is the installed component, at its authored spot and grounded;
- it uses reserved index -40 and shows the ordinary "Rest a Creature" prompt;
- it gives no credit toward the tournament's Build a Creature Bed rung;
- the whole visible-rim footprint (5.0 x 4.3 m) is clear of colliders, and grass is kept off the pad;
- a hurt creature put to bed heals to full in `creature_bed.full_heal_seconds` (120 s), and can be woken early.

Hint text: no hint says creature beds exist only at camp, so none was changed.

## Judged frame: PARTIAL (r3)
| Round | Code | Verdict |
|---|---|---|
| r1 | 6f172fd4 | NO as a creature bed: a log-edged garden plot, squeezed against the wall and bench (`codeblind-review.md`) |
| r2 | ccbe52b6 | FAIL: the 4.9 x 4.2 m visible rim (only the 2.4 m pad had been measured) crowded the wall, bench, crates and stool; grass came through the pad; the rim disappeared at night (`r2/codeblind-review.md`) |
| r3 | 46da85cb | PARTIAL: findable, creature-scale, uncrowded, readable at night under its lantern, but it reads as a sandpit or stage before a nest (`r3/codeblind-review.md`) |

What r3's remaining defects need: the square plank deck inside the round ring, and the ring being one log high. Both belong to
the shared `creature_bed.gd` form that every camp bed also uses. That file already records the clean straw, weave and nest
texture or mesh as missing art, which is a Codex/Meshy item (`../meshy-handoff/README.md`). F17 doesn't reshape the shared component
beyond its judged camp form. The home copy gets only home-scoped dressing: grass clearing, straw bedding, a bucket and crate,
and a lantern.
