# S03-205: camp and creature bed prompts overlap -- possibly production-side, STOPPING per instruction

**Author:** operator agent, `ralph/GATE-F-S03-CATCH-LOOP`.
**Candidate:** `a3b0d4b7` (this branch), run
`ralph/reports/gate-f-run-20260902T134520Z-s03full2` (post S03-105 fix,
confirming the segment now runs much further: party of 5 PASSes, home and
creature bed both build successfully -- S03-105/173/205 no longer fail).

## In one line

Reporting per your explicit instruction, not fixing: this may be the same
defect underlying the owner's two open findings ("player sleep was
impossible", "creatures never get out of bed / never appear rested"), or
it may be a harness-arrival-tolerance artifact that would not affect a real
player the same way. I could not tell which from this evidence alone, and
you named this exact code area as off-limits to work around rather than
report.

## What happened

`S03-205a` ("walk to the creature bed just built") reports arriving with
0.0m left to travel. The very next step, `S03-205b` ("put a creature to
bed"), FAILs: the live interact prompt at that position is **"Rest until
morning"**, not **"Rest a Creature"**.

Both strings are real, and belong to two DIFFERENT interactables:

- `scripts/build/creature_bed.gd:399` -- `prompt.call("configure", "Rest a
  Creature", 2.6, true)` -- the creature bed's own prompt.
- `scripts/build/camp.gd:163` -- `prompt.call("configure", "Rest until
  morning", 2.6, true)` -- the CAMP's (the player's own home/tent) prompt.

So the live prompt at the creature bed's own position is coming from the
CAMP, not the bed. The interaction arbiter (nearest-wins at equal priority,
same 2.6m radius on both) picked the camp over the bed the player had just
walked up to.

## Measured, from this run's own save (`S03/saves/S03-exit.json`)

```
placed_buildings: camp @ (-4.0, -40.0), creature_bed @ (0.0, -40.0)
```

Camp and creature bed are **4.0m apart** — inside the sum of their own two
2.6m prompt radii (5.2m), so their catchment zones genuinely overlap in a
real physical band between them, roughly 1.4m-2.6m from either. The
player's actual position when `S03-205b` fired (from `events.jsonl`):
`(-2.77, -39.27)` — **1.43m from camp, 2.86m from the bed**. Both distances
are inside camp's 2.6m radius; only the shorter one (bed's) is inside the
bed's own. Camp wins on nearest-of-equal-priority, correctly by the
arbiter's own rule, at a position that is NOT on top of either building --
it is in the real overlap band between two buildings the game itself
places 4.0m apart.

## Why I am not calling this either way myself

Two honest readings, and I don't have enough to pick one:

1. **Harness artifact.** `move_to_entity`'s `within` tolerance (the
   `S03-205a` step's own arrival radius) may simply be more generous than
   how a real player, deliberately walking up to a specific bed and facing
   it, would naturally stop -- a real player closing the last 1-2m by eye
   would likely end up much closer to the bed they are looking at than to
   the camp behind them, out of the overlap band entirely, and never see
   this collision at all.
2. **Real, structural.** Camp and creature bed are placed 4.0m apart by
   design (whatever code chose that position for this run), with equal
   2.6m radii on both prompts, on purpose or not. That is a real, physical
   overlap in the built game, not a synthetic-input artifact -- any player
   who approaches from the camp side, or stops to think a moment before
   pressing interact, stands a real chance of landing in the same band this
   run did. This is exactly the shape of thing that would read to a player
   as "I couldn't get a creature into the bed" or "nothing happened when I
   tried to rest" -- which is close to both open findings' own wording.

I have not looked at `ralph/OWNER-0901-PLAYER-SLEEP-V2` or
`ralph/OWNER-0902-REST-VISIBILITY`'s own diffs/state, per your instruction
not to touch or duplicate that work -- so I don't know whether they have
already found and are already fixing this exact collision, a different
cause with the same symptom, or something else entirely. Recommend
whoever owns those lanes checks this specific pairing (camp prompt radius/
placement vs. creature bed prompt radius/placement, and whether the
build-placement code that put them 4.0m apart in this run does that
consistently or by chance) against what they've already found.

## Where this leaves S03

Not fixed, not worked around. The segment's own script (`S03-205b`
onward) will keep FAILing here until either (a) this gets a real answer
from whoever owns the sleep/rest code and I apply it, or (b) I'm told this
specific prompt-collision reading is wrong and the fix belongs somewhere
else (e.g., purely `S03-205a`'s own walk tolerance). Downstream failures
(`S03-206`, `S03-228` player_slept_at_home NOT set, `S03-229`, `S03-260`
tournament_team_fed NOT set) are the direct cascade of this one blocking
step, same shape as the S03-105 cascade -- not separate defects.

Two smaller, unrelated FAILs also remain in this run, not investigated
(neither touches the sleep/rest area): `S03-25w` (a pre-existing
narrative_modal timing issue, unchanged from every prior run), and
`S03-315`/`S03-317` (tournament entrant-list focus movement, in the
segment's tail past the bed/sleep chain).
