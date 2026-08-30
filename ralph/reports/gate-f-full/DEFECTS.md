# GATE-F-FULL — defects, live log

Run: `ralph/reports/gate-f-full`, branch `ralph/GATE-F-FULL`, candidate
`453107fb` (LAND-0830J landed on `main` 2026-08-30).

Severity words follow the Gate F protocol: **BLOCKER** (the chain cannot
proceed), **SHIP** (a player-facing defect a real player would report),
**RIG** (the instrument, not the game).

Per `ralph/NEXT_COORDINATOR_FULL_STATE_AUDIT.md` this lane may fix the RIG and
may not touch the GAME. Every GAME entry below is therefore written down and
left alone, with the fix proposed rather than made.

---

## GAME-F1 — two of the first day's twenty harvest nodes now stand outside the village fence

**Severity:** SHIP, minor-but-real. **Found from config, before the run
reached it.** **Not fixed** — `data/config/` is frozen for this lane.

`data/config/bands/band1_lower_meadows/harvest.json` places twenty gathering
nodes in the village area — the first day's tutorial gathering, and the exact
list `tools/gate_f/segments/S03.json` walks in steps S03-65 … S03-103.
Tested point-by-point against the outline in
`data/config/village_boundary.json`:

| node | inside the fence? |
|---|---|
| eighteen of them | yes |
| **(44, −24)** | **no** |
| **(52, −30)** | **no** |

The boundary was authored on 2026-08-30 (`OP-0830-1`, then rerouted the same
day by the straddle fix). Its own test, `tests/test_village_boundary.gd`,
carries a hand-written `MUST_BE_INSIDE` list — the farmhouse, the well, four
named villagers, the tournament board, the practice bramblebun, the farm
plots — and the harvest nodes are not on it. Nothing else checks them either.
The comment above that list says why the list is hand-written: *"a loader would
silently start including whatever moved into range later."* The cost of that
choice is this: the line moved, and two nodes it was never asked about fell
outside.

**What it costs a player.** The gate is open by the time S03's gathering ladder
runs, so neither node is strictly unreachable — but the chapter's first
gathering lesson sends the player through their own village gate and back for
two of its twenty stops, and the fence is a hard `StaticBody3D`, so the
straight walk between them does not exist. A player who has not yet found the
key cannot reach either node at all.

**Suggested fix (game-side, not made here).** Either move the two nodes inside
the line — they are on the fence's own doorstep, (44,−24) is 4.6 m outside and
(52,−30) 3.9 m — or add the twenty nodes to `MUST_BE_INSIDE` and accept that
the outline must contain them. The second is the one that stops it recurring.

**Expected rig consequence, recorded before it happened:** the leg S03-81 →
S03-83 crosses the fence at (48.5, −31.5), **15.2 m from the RoadGate**, so the
harness's straight-line walk has a fence between it and its target. Whether
`stick_navigator.gd`'s wall-slide finds its way round is the run's to answer.

---

## GAME-F2 — the GAME-11 level pin is gone from `main`; the practice fight rolls its band level again

**Severity:** SHIP, and the highest-value finding of this run's first three
segments. **Measured in play, then traced in git.** **Not fixed** —
`data/config/` is frozen for this lane.

### What the run measured

`ralph/reports/gate-f-full/S02/telemetry/events.jsonl`, the chapter's first
fight, this candidate:

| | |
|---|---|
| opponent | Bramblebun, **level 5**, **124.2 max HP** |
| starter after the fight | Moss (ripplet L3), **45.2 of 117.6 HP** |
| the catch | landed, on the second `catch_throw` |

Run 7 on 2026-08-30 measured the same fight, with the pin in place, at
**level 2 / 93.7 HP** and the starter finishing at **67.9 of 117.6**. Run 6
measured it unpinned, over five fresh saves, at a rolled **level 2–6** and the
starter **FAINTING in four of the five**.

This run survived. It survived at 38% of the starter's health, on the roll that
run 6 measured as a four-in-five loss.

### Where the pin went

`scripts/combat/encounter_director.gd:438` still reads
`int(spawn.get("level", 0))` — **the code half of run 7's fix landed and is on
`main`.** The data half is not:

```
b02f6e8f  GAME-11: pin the practice fight ...   level=2   radius=15.0  centre=[30,0,-40]
2596dd36  RUN7: merge LAND-0830I                level=2   radius=15.0  centre=[30,0,-40]
5ecc93b0  put the practice cluster on one side  level=2   radius=8.0   centre=[38,0,-50]
55e9bb64  Re-site the practice cluster          level=2   radius=7.0   centre=[20,0,-64]
cfce9d54  Stop moving the practice cluster      ABSENT    radius=5.0   centre=[30,0,-40]
841cdd42  Revert the practice-cluster attempts  ABSENT    radius=15.0  centre=[30,0,-40]
5cc2819e  Route the village outline ...         ABSENT    radius=15.0  centre=[30,0,-40]
453107fb  (main, this candidate)                ABSENT    radius=15.0  centre=[30,0,-40]
```

**`cfce9d54` is where it goes.** That commit reverted the cluster to its
authored centre by restoring the pre-pin entry wholesale, and its own message
says, in as many words:

> *"Species, count, level pin and the GAME-11 rationale below are untouched."*

They were not. `"level": 2` and its `_why_game_11` rationale string both went
with the revert, and the later revert `841cdd42` put `radius` back to 15.0
without noticing the level was missing too. Nothing failed: the code half
treats an absent `level` as "roll it", which is exactly the pre-fix behaviour,
so the regression is **silent by construction**.

### Why nothing caught it

`tests/test_band_content.gd` compares the live band files against
`tests/fixtures/band_split_baseline/spawns.json`. Run 7 mirrored the pin into
that fixture (`e611720a`) precisely so a future drift would fail there — but
the mirror was reverted alongside the live file, so the two agree **on the
unpinned value** and the test is green. A baseline that moves with the thing it
baselines cannot catch a regression in it.

### What it costs a player

The chapter's teaching fight. `data/config/progression.json`'s own award
comment states the intended curve — enemy levels *"run 2 at the practice fight
to 22 in the stronghold gauntlet"* — and the fight is currently the band roll,
2 to 6. At the top of that roll a level-3 starter loses, which is what run 6
measured; losing costs one of the two Revive draughts the opening satchel
grants, before the player has met a trainer or a shop. `ralph/T5-PLAY`'s
GAME-T5-6 is the same economy concern from the other side, and it was filed
against a fight the player usually *lost*.

### Suggested fix (game-side, not made here)

Re-apply run 7's two lines to `data/config/bands/band1_lower_meadows/spawns.json`
`spawns[0]` — `"level": 2` and the `_why_game_11` rationale, byte-identical to
`b02f6e8f`'s — and re-mirror them into `tests/fixtures/band_split_baseline/spawns.json`
per that fixture's own documented policy for a deliberate balance retune. The
code half needs nothing; it is already on `main`.

**And a second fix worth more than the first:** the pin's value belongs in a
test that does not move with it. `progression.json` already writes the number
down in prose; a test that reads "2 at the practice fight" from the curve and
asserts the practice cluster carries it would have failed at `cfce9d54` and
would fail again at the next revert. As things stand the only instrument that
catches this is a played fight.

---

## RIG-F1 — the catch asserts race the catch by half a second

**Severity:** RIG. **Fixed by this lane, in the instrument.**

`S02-45` ("the catch counted") and `S02-46` ("the chain advanced to the road")
both FAILed in this run against a segment whose **own exit save carries the
caught creature**:

```
S02-45  party size 1 (wanted 2)                          FAIL   t=267.47
S02-46  tracked objective id=opening:beat:road ...       FAIL   t=267.47
        catch_result "party grew 1 -> 2"                        t=268.00
        combat_end, objective -> road_gate_open                 t=268.00
```

`S02-43iw` waits 360 physics frames (6.0 s of play) after the fourth throw. The
throw resolved to a verdict at t=265.38 and CombatManager granted the creature
at t=268.00; the wait ran out at t=267.47. **The asserts read the world 0.53 s
of play before it became true.**

This is CD-3's rule — *no step may encode a guessed repetition count for a
state-changing UI; reach a state, then assert it* — applied to `wait` rather
than to `press`, and the protocol had no vocabulary for it: `assert` asks once,
and the only way to wait for an asynchronous result was a guessed frame count.

**Fixed by adding the missing half.** `wait_until` (in
`tools/gate_f/operator_harness.gd`, documented in
`tools/gate_f/SEGMENT_SCHEMA.md`) polls the same `check` vocabulary `assert`
uses, PASSes the instant the predicate is true and reports how many physics
frames that took, and FAILs at its budget naming the last thing it saw. It is
priced in `_predict_frames` at its full budget, like a walk, so the cost gate
cannot be fooled by an early exit. A check the envelope cannot evaluate is
returned as a SKIP immediately rather than polled.

**Nothing about the game moved.** The catch works, the party grew, the objective
advanced, and the exit save is healthy. What was wrong was an instrument that
asked its question too early and recorded the answer as a defect — three
previous runs have reported this shape.

---

## RIG-F2 — the aim assert reads a toggle at the wrong parity

**Severity:** RIG. **Recorded, NOT fixed** — the honest fix needs a primitive
this protocol does not have, and the underlying behaviour is worth reporting
rather than papering over.

`S02-40` ("the aim owns input") FAILed: `input_context=combat (wanted
combat_aim)`. The telemetry shows why, and it is not that aiming is broken:

```
t=238.33   ctx=combat_aim      <- the aim is ALREADY armed when the block begins
t=239.35   S02-39 presses interact x2   -> ctx=combat
t=239.35   S02-40 asserts combat_aim    -> FAIL
t=239.58   S02-42 presses interact x1   -> no catch_throw
t=245.63   ctx=combat_aim
t=246.63   S02-43d presses interact x2  -> ctx=combat, catch_throw at 246.68
```

`interact` **toggles** the aim. The segment's fixed pattern — "aim" as
`interact x2`, then "throw" as `interact x1` — lands on a different parity
depending on whether the aim happened to be armed when the block started, and
in this run **two of the four throw blocks emitted a `catch_throw` and two
emitted none**. The four-block retry ladder is what absorbed that: it threw
twice, and the second throw caught.

**Why it is not fixed here.** The correct rig fix is "press until the context is
`combat_aim`", and the step vocabulary has no press-until-predicate action —
`wait_until` waits, it does not act. Writing one is a real instrument
improvement and a bigger change than this lane should make mid-run.

**Worth an owner's eye regardless of the rig.** A toggle bound to the same
button as throw means a player who taps twice quickly arms and disarms the aim
with no throw, and nothing in the telemetry distinguishes the two states except
`input_context`. Whether that reads well on a controller is an [OWNER-ONLY]
question this envelope cannot answer.

---

## RIG-F3 — S02's two floors are stale, and this run is the second to say so

**Severity:** RIG. **Recorded, NOT changed** — moving a floor to match the
number that failed it is how a floor stops meaning anything.

```
S02-59  walked 143.4 m this segment (wanted >= 150.0)   FAIL
S02-60  route.csv has 567 rows (wanted >= 900)          FAIL
```

Both PASSed in run 7 on 2026-08-30, so the segment genuinely got shorter
between that run and this one, and the floors were derived from a version of
the segment that no longer exists. `ralph/reports/handover-GATE-F-RUN7-2026-08-30.md`
§9.4 already asks for exactly this — *"re-derive S02-59 and S02-60's floors
against the segment as it now behaves, and record which run each number came
from"* — and this run is the second data point, not the derivation.

**What a derivation needs, so the next lane does not have to work it out:**
three or four S02 runs (~7 min each on this box), the distance and row count
from each, and a floor set below the observed minimum with the run ids written
into the step's `expected`. Two samples is not a floor.

---

## GAME-F3 — the chapter's teaching fight shares its ground with a gathering node, and the node wins the button

**Severity:** SHIP candidate, **needs an owner's judgement rather than a fix**.
**Measured, ten times in one segment.** **Not fixed** — `data/` is frozen for
this lane, and the mechanism is behaving as documented.

### What happened

S03's team-building ladder walks to a wild bramblebun in the Practice Meadow
and challenges it, up to ten times. All ten refused:

```
walked 0.7 m to bramblebun  ... player at (27.27, -44.89)
FAIL the live prompt is "  Gather deadwood", which does not contain
"Engage" -- pressing here would activate a different provider. Not pressed.
```

and then, for the remaining eight, from a standstill at **(26.03, −44.01)**.

**That is the deadwood node's own coordinate.** `data/config/bands/band1_lower_meadows/harvest.json`
order 1: `{"item": "wood", "label": "Gather deadwood", "at": [26.0, -44.0]}`.
It sits 5.7 m from the practice cluster's authored centre (30,−40), well inside
the cluster's 15 m radius, so a bramblebun can and did spawn beside it.

### Why the node wins

`scripts/world/prompt_arbiter.gd`: *"Highest priority first, then nearest, then
first registered."* `encounter_director.gd`'s engage offer carries **priority 0**
— deliberately, and the comment above it explains why: it used to carry priority
100 and that made a fainted-ally line outrank every prompt in the world (GAME-0).
`interactable.gd`'s default is also 0. So engage and gather are peers, and the
tie goes to distance: a node at ~0 m beats a creature at 1–4 m, every time.

### What it costs a player

The player standing on the deadwood is offered the deadwood. Stepping back a
metre would fix it, and a human would. But the chapter's own first team-building
lesson happens on this ground, and the game gives no way to cycle the offer —
one button, one winner, chosen by distance. The failure mode is silent: nothing
says "there is also a creature here."

**This run's cascade was total.** The team stayed at 2, `S03-39` ("the team is
three") failed, and `tournament.json` requires `min_party_size: 3` — so the exit
save S04 would inherit cannot enter the tournament. The chain was stopped here
rather than run on it.

### What is honestly unknown

Whether a human player hits this at all. The cluster is randomised per boot
(`wild_creature.gd` randomises spawn positions), so how often a member lands
within a metre or two of (26,−44) is a question about the seed distribution,
and one run cannot answer it. **What is certain is that it can happen and that
nothing recovers from it except the player moving.**

### Options, for the owner rather than for this lane

1. Move the deadwood node out of the practice cluster's disk — it is one
   coordinate in `harvest.json` and the meadow has nineteen other nodes.
2. Give the engage offer a small priority edge over a harvest node *within
   engage range only*. Cheap, but priority is the mechanism GAME-0 was caused by
   and the comment in `encounter_director.gd` is a warning worth heeding.
3. Accept it: a player steps back. The cost is a confusing first minute in the
   one place the chapter is teaching.

Recorded, not chosen. Option 3 is defensible and the other two are one-line
changes; that is precisely the shape of decision this audit is meant to hand
over rather than make.
