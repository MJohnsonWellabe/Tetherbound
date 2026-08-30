# `party_count_after_catches`: the practice cluster straddles the village fence

**Status:** open, measured, NOT fixed. Handed on deliberately after four attempts
on the landing branch, each of which broke something else. Written by the
coordinator landing `ralph/LAND-0830J`, 2026-08-30.

## What is wrong

`data/config/bands/band1_lower_meadows/spawns.json`'s first cluster — the
Practice Meadow, the chapter's teaching fight — has three bramblebuns around
(30, −40) with a 15m radius. `T5-OPENING` (7da75ac7) later gave the village an
edge, and **the fence runs through the middle of that cluster**:

```
Wild_bramblebun_0_1   at  41.3, -48.2   OUTSIDE the outline
Wild_bramblebun_0_2   at  22.3, -42.2   inside
Wild_bramblebun_0_3   at  33.7, -39.8   inside
```

`smoke_party_count_after_catches.gd` needs three catches out of this one
cluster, and stages the player at (48, 0, −58) — a point
`smoke_catching.gd::_leave_the_farmhouse()` chose to clear the farmhouse wall,
years of commits before the village had an edge. That stand is now outside the
fence, so two of the three are behind a wall and the test catches one.

`tools/_probe_catch_stand.gd` (added in this consolidation) sweeps the player's
own collision shape along the straight line from a candidate stand to each
member and names the first blocker. **No stand reaches all three:**

```
stand  48,-58 -> 1/3   0_2, 0_3 behind FencePanelCollision_35/36
stand  30,-30 -> 2/3   0_1 behind FencePanelCollision_37
stand  34,-28 -> 2/3   0_1 behind FencePanelCollision_38
stand  20,-40 -> 2/3   0_1 behind FencePanelCollision_35
```

From outside you reach one; from inside you reach two. The cluster is split.

## Four attempts, and what each one proved

Recorded so the next lane does not repeat them. Every one of these was pushed
and run in CI, so these are measurements, not predictions.

| attempt | change | result |
|---|---|---|
| 1 | cluster → (38,−50) r8, outside the fence | fixed the straddle; **crowded the catch stand** — clearance fell from the authored 10.5m to 4.8m, and `wild_creature.gd` randomises spawn positions per boot, so it blocked the player's body on some seeds. Passed locally and on one CI run, then failed twice. |
| 2 | cluster → (20,−64) r7, 21.6m from the stand | fixed both clearances; **broke the opening** — `smoke_gate_a_opening_segment.gd`: *"natural travel did not reach and engage the tutorial Bramblebun"*. The opening walks to this cluster from Grandpa's house and the authored position is where that walk arrives. |
| 3 | cluster radius 15 → 5 (centre unchanged), all four catch tests restaged (48,0,−58) → (30,0,−28) | **reachability solved** — 0/3 from the old stand, 3/3 from the new, and `gate_a_opening_segment` and `authored_camps` both went green. But the catch minigame then failed: *"could not catch … in 25 throws"* on all three. Three creatures inside a 5m radius is too tight for the throw to resolve. |
| 4 | — | reverted to authored, landed with this job red. |

**The lesson attempt 2 paid for: this cluster cannot move.** The opening's own
walk depends on it, so the fix has to be one of the three below, not a
relocation.

## What the fix probably is, in preference order

1. **Widen the gap in the fence, or route the outline so the Practice Meadow is
   wholly on one side.** `data/config/village_boundary.json`'s outline is
   computed; one cluster straddling it is a boundary-authoring problem, not a
   spawn problem. This is the only option that fixes the *player's* experience
   as well as the test — a wall through the teaching meadow is visible.
2. **Split the cluster in two** — one inside the outline for the opening's walk,
   one outside for the meadow — keeping three catchable individuals on the
   player's side of whichever wall they meet first.
3. **Restage the test inside AND keep a workable radius** (attempt 3, but with a
   radius around 8–10 rather than 5, so the three do not overlap). This fixes
   the test only; the wall through the meadow remains.

Do not attempt any of these on a landing branch. Each round costs a full CI
run, and three of the four attempts above broke a job that had been green.

## Related, and probably the same family

`smoke_authored_camps.gd` failed twice today at `trail_camp` (346, 935) with the
prompt OFFERED and the press activating nothing, then passed on re-run and again
on the next run. T5-CARE hit the same signature with the build verb, and
LAND-FIX-2 investigated and cleared it for the engage prompt. Three sightings of
"the arbiter shows a prompt that the press does not activate" is a pattern worth
one lane rather than three write-ups.
