# S03 post-merge: both targeted fixes confirmed correct; a broader, merge-introduced variance is now the limiter

**Author:** operator agent, `ralph/GATE-F-S03-CATCH-LOOP`.
**Candidate:** `5a6c0cd1` (this branch, merged forward to `main@b03cdb94`), run
`ralph/reports/gate-f-run-20260902T152429Z-s03postmerge2`.

## The two fixes you asked for: both confirmed working

**hotbar_4 (knife equip):** fiber gathering is flowing again post-merge --
this run gathered fiber at 4 of 8 nodes (16 fiber), where before the fix it
was 0 of 8. Confirmed the mechanism, not just the outcome.

**Camp-split adaptation (tent/campfire/bedroll):** this run's own save
(`S03/saves/S03-exit.json`) shows all three placed successfully:

```
placed_buildings: tent @(-6,-42), campfire @(-6,-46), bedroll @(-6,-48)
```

No FAIL anywhere in the three new build blocks (`S03-121*`/`S03-131*`/
`S03-141*`). The `focus_move(right, 1)` relative-navigation approach works
as designed.

## What's actually still blocking: terrain/scatter, not either fix

`S03-105` (`home_materials_gathered`) FAILs this run: wood=16/18, fiber=
16/18, stone=8/8 (short by 2 wood, 2 fiber). Sufficient to afford tent+
campfire+bedroll alone (12/8/10) but not the full bill once `creature_bed`
(+6 wood/+8 fiber) is added -- which is exactly what happened: tent/
campfire/bedroll placed, `creature_bed` never got armed (unaffordable),
and everything from there cascades (`S03-173`/`205`/`206`/`228`/`229`/
`260` all FAIL as direct downstream consequences, not separate bugs).

The gather shortfall traces to node reachability, not the knife/hotbar
fix: of 7 wood nodes, 3 came up empty this run (matches the 2 already-
flagged-unexplained ones from `FINDING-S03-105-...md`'s wood investigation,
now joined by others); of 8 fiber nodes, only 4 succeeded (down from 8/8
in the pre-merge verification run with the identical hotbar_4 fix); of 3
stone nodes, 2 succeeded. The catch loop also lost one attempt this run to
the identical failure SHAPE (`S03-32a`: "reached ... in plan view (2.00 m)
but it is 2.02 m away in 3D -- 0.28 m ... vertical", the pre-existing
RIG-F5 class) though it still converged to party 5 on the other 9
attempts.

**This is very likely PR #20 (Meadows Visual Parity, merged same tree) --
"sky, ground, vegetation, corridor, places and life all changed, plus its
own scatter re-bake."** `move_to` (used for every gather walk) tracks
terrain height at its target X/Z but only checks X/Z arrival by default
(no `close_3d`); if the VP re-bake shifted ground height at some of these
fixed coordinates, a walk that used to land flush with a node can now stop
short in 3D even while reporting "close enough" in the plane -- the exact
shape `S03-32a`'s FAIL message describes directly, and consistent with
more nodes failing now than before the merge (which only ever had this
happen at 2 specific wood coordinates, already flagged and partly
explained as genuine steep terrain).

`S03-205a`'s own FAIL this run ("stopped 1906.4 m short... nearest of 7
CampCreatureBed") is a further, correctly-explained cascade, not a new
defect: since the player's own creature_bed was never placed (unaffordable
this run), `move_to_entity`'s script-path search for `creature_bed.gd`
matched the nearest OTHER thing running that script in the whole map --
some other camp's bed nearly 2km away -- rather than a bed that does not
exist. The `within:1.2` prompt-collision fix from the previous checkpoint
is simply untested by this run; there was nothing built to walk to.

## Where I'm stopping

I don't think chasing individual gather-node coordinates one at a time is
the right level for this -- it's the same underlying cause (terrain
shifted under fixed script coordinates) showing up at a growing number of
positions as VP's world changes land, not a fixed, countable set of bugs.
Two honest options I can see, and I don't have enough visibility into VP's
own re-bake to pick between them:

1. **Harness-side:** add `close_3d` awareness (or a taller vertical
   tolerance) to the gather `move_to` steps generally, the same class of
   fix `move_to_entity` already has -- would very likely restore full
   yield, but only if the real vertical gaps here are small (sub-metre,
   like the S03-32a case), not because a node is now somewhere genuinely
   unreachable.
2. **World-side:** if VP's scatter re-bake meaningfully moved harvest node/
   wild-creature placement at specific spots the Meadows tutorial ladder
   depends on, that may be worth VP's own coordinator knowing about --
   this segment is about the only thing in the repo that walks to every
   one of these exact coordinates and checks arrival precisely.

Not fixing either myself yet -- reporting per the same pattern as the last
two findings, since option 2 touches code/data this session doesn't own.

## Numbers for the record

This run: 17 FAILs (was 11 before the merge, 12 before that -- both of
those numbers are superseded, per your own instruction). The regression
from 11 to 17 is entirely the materials-shortfall cascade above, not new
defects in either of this session's own fixes.
