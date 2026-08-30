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

---

## GAME-F4 — every creature loaded from a save loses its base stats, and the first level-up after that destroys it

**Severity: BLOCKER.** **Measured in play, reproduced in one second, and
confirmed by arithmetic to four significant figures.** **Not fixed** —
`scripts/` is frozen for this lane. This is the most consequential thing this
run found and, on the evidence below, it is very likely a large part of why six
previous Gate F attempts produced downstream evidence that did not mean
anything.

### What the chapter did

S03 loads S02's exit save through the production title-screen Load path, which
is how every segment after S01 begins and how every real player begins a second
session. Moss, the chapter's starter, then won a fight and levelled up:

```
t=496.6   party ((Moss, L3, hp 18.27, max_hp 117.60), (Bramblebun, L5, 28.15, 124.22))
t=498.0   level_up  "Moss reached level 4"
t=498.0   party ((Moss, L4, hp  0.18, max_hp   1.18), (Bramblebun, L5, 28.15, 124.22))
```

**117.60 → 1.18.** One hit ended it. `attack` went 26.40 → 1.15 and `defence`
18.70 → 1.15 in the same frame. Both of the player's creatures were fainted by
the end of the segment, `encounter_director.gd::summon_active_creature()`
refuses to deploy a fainted creature, and the rest of the village ladder — the
beds, the sleep, the feeding — could not run. Evidence:
`ralph/reports/gate-f-full/S03-superseded-1/telemetry/events.jsonl` and
`saves/S03-exit.json`, which records `{"level": 4, "hp": 0.0, "max_hp": 1.18,
"attack": 1.15, "defence": 1.15}`.

### Why

`scripts/save/save_game.gd::_party_to_array` writes 34 keys per creature. Three
that `creature_instance.gd` needs are **not among them**: `base_hp`,
`base_attack`, `base_defence`. `_array_to_party` therefore never sets them, and
`creature_instance.gd:62` declares the class default:

```gdscript
var base_hp: float = 1.0
var base_attack: float = 1.0
var base_defence: float = 1.0
```

The loader restores the *stored* `max_hp`, `attack` and `defence` directly, so a
freshly loaded creature looks completely correct — right level, right HP, right
name. The damage is latent. It lands the first time anything calls
`_apply_level_stats()`, which recomputes every stat **from the base stats** and
not from itself (deliberately — D30, so growth does not compound):

```gdscript
max_hp = PROGRESSION.stat_at_level(base_hp, level, growth.hp)
       * PROGRESSION.individuality_multiplier(iv_hp, cfg) + boost_hp
```

With `base_hp = 1.0`, level 4 and `growth.hp = 0.06`, that is
`1.0 × (1 + 0.06 × 3) × 1.0 = 1.18`. The observed value is **1.18**. With
ripplet's real `base_hp` of 105.0 it is **123.90**. Attack: `1.15` observed
against `27.60` expected. Defence: `1.15` against `19.55`. Every figure matches
to the last digit printed.

**Four things call `_apply_level_stats()`, and all four are ordinary play:**
`gain_xp` (winning a fight), `set_level`, `drink_elixir` (D47's vitality
elixirs), and `evolve_into`.

### The repair that two comments promise and nobody wrote

`save_game.gd:751` says the missing field is *"repaired from species.json the
same way every other species-owned field on this class is repaired ... on the
next `apply_species_definition`."* `creature_instance.gd:40` says the same.

**`apply_species_definition` does not exist.** A grep of every `.gd` file in the
repository returns exactly two hits, and both are those comments. There is no
such function, nothing calls one, and the repair described in two places has
never been implemented. That is why nothing looked wrong to a reader of either
file: each one points at the other's promise.

### Reproduction — one command, about one second, no world

`tools/gate_f/diag/probe_base_stats_after_load.gd`, added by this lane:

```
godot --headless --path . --script tools/gate_f/diag/probe_base_stats_after_load.gd
```

```
fresh  L3  base_hp=105.0  max_hp=117.60  attack=26.40  defence=18.70
loaded L3  base_hp=1.0    max_hp=117.60  attack=26.40  defence=18.70
levelled +1 -> L4         max_hp=  1.18  attack= 1.15  defence= 1.15
expected     L4           max_hp=123.90  attack=27.60  defence=19.55
```

It drives the production `_party_to_array` / `_array_to_party` pair and the real
`gain_xp`, with `autoload/party.gd` as the container — not a copy of any of
them. Exit code 1 while the defect stands, 0 when it is fixed.

### What it costs a player

Everything, from their second session onwards. A save/load is not an edge case
in this game: it is how a session ends and how the next one starts, and the
Meadows chapter is explicitly built around it. The failure is silent at the
moment of loading and arrives later, attached to a *reward* — the player wins a
fight, sees "reached level 4", and their creature is now a one-hit kill with no
message, no cue, and nothing in the UI that says a stat changed for the worse.
There is no in-game recovery: the base stats are gone from the instance and the
next save writes the collapsed numbers back out, so the damage is **persisted**
and compounds on the following load.

### Why no test caught it

`tests/smoke_save_persistence.gd` exercises the real save/load lifecycle and
checks that a creature comes back — which it does, correctly. Nothing in the
suite **levels a creature up after loading it**, which is the only moment the
defect is observable. That is the whole gap, and it is one test.

### Suggested fix (game-side, not made here)

Two changes, both small, and the second is the one that matters:

1. **Restore the base stats on load.** The save already carries `species_id`,
   so no format change is needed and no old save is lost:
   `_array_to_party` reads `creature_species.definition(species_id)` and sets
   `base_hp` / `base_attack` / `base_defence` from it — which is exactly the
   `apply_species_definition` the two comments describe. Writing that function
   on `creature_instance.gd` and calling it from the loader would also make both
   comments true for the first time, and would repair `secondary_type` and
   `creature_type` on old saves the same way, which is what they were written
   about.
2. **Make the missing test exist.** `tools/gate_f/diag/probe_base_stats_after_load.gd`
   is the shape of it and needs no world: round-trip a creature through the
   production pair, level it up, and assert its stats equal the same creature
   levelled without a save. Promote it to `tests/` as the fix's acceptance
   criterion. Without it this comes back the moment somebody adds a field.

**A note on scope, since it is tempting.** Sourcing the base stats from
`species.json` on load is correct for every creature the game currently makes,
because base stats are species-owned and nothing mutates them — `evolve_into` is
the only writer and it sets them from the new species' own definition. If that
ever stops being true, the base stats have to be written into the save instead,
and the round-trip test above is what would catch the difference.

---

## GAME-F5 — one sweep of the village's authored nodes does not pay for the home, and the run never built one

**Severity:** SHIP candidate, **stated as an open question rather than a verdict**
— two facts found while checking it cut against the simple reading, and they are
below. **Not fixed** — `data/` is frozen for this lane.

### What the run measured

S03's gathering ladder walks all twenty band-1 harvest nodes in the village
area and works each with two taps. Eighteen were reached (two were not — see
GAME-F1). Result, from `S03-superseded-1/saves/S03-exit.json` after three
pieces had been placed:

```
satchel: fiber 8, wood 5, stone 0   (floor + wall + door already paid: 11 wood, 6 stone)
S03-105  flag home_materials_gathered NOT set        FAIL
S03-173  flag home_built              NOT set        FAIL
S03-205  flag creature_bed_built_3    NOT set        FAIL
S03-228  flag player_slept_at_home    NOT set        FAIL
```

The home was never built, so there was nothing to sleep in and nothing to feed
the team beside; the last third of the village ladder could not run.

### The arithmetic, from the real catalogue and the real node table

Costs from `data/items/buildables.json`, availability from
`data/config/bands/band1_lower_meadows/harvest.json`:

| | wood | stone | fiber |
|---|---:|---:|---:|
| **available** — all 20 village-area nodes, one pass, worked to exhaustion | **28** | **9** | **32** |
| of which outside the fence (GAME-F1) | 4 | 3 | 0 |
| available without leaving the village | 24 | 6 | 32 |
| **needed** — `progression.json` `home.required_pieces` (camp) + three creature beds | **30** | 8 | **34** |
| **needed** — what S03 actually builds (camp+floor+wall+door+roof + three beds) | **45** | **17** | **34** |

Even on the *minimum* the game itself requires, a single pass of every authored
node — including the two behind the fence — is **2 wood and 2 fiber short**. On
what the segment builds it is 17 wood and 8 stone short. The owner directive of
2026-08-23 that S03's own step quotes is:

> *"the village gatherable budget must afford three beds before sign-up — the
> journey verifies that budget by actually paying it."*

On one sweep, it does not.

### The two facts that cut against the simple reading, stated because they matter

1. **The nodes respawn.** `harvest_node.gd::RESPAWN_SECONDS = 60.0`. A player
   who circles the village a second time gets the whole table again. The sweep
   itself took about 180 s of play, so some nodes were already back before it
   ended.
2. **The world is full of other harvestables.** The boot log reports
   `scattered 382817 props ... 59165 harvestable`, and
   `vegetation_harvest_point.gd` makes scatter trees gatherable. Wood, at
   least, is not confined to the twenty authored nodes.

So this is **not** "the materials do not exist". It is: **the authored budget
does not cover the ladder in one pass, and the ladder is written as one pass.**
Whether that is a tuning miss or a deliberate "go round again" is a design call.

**What does not rescue it:** buying the shortfall. `data/config/trade.json`
gives Mira `wood {"buy": 4, "sell": 1, "stock": 0}`, and the same `stock: 0`
for stone and fiber — she *buys* materials from the player and has none to
sell. The 30 coins in the exit satchel cannot close the gap.

### The open question this run could not answer

**Eleven `gather` events fired across eighteen reached nodes.** Seven nodes were
walked to, had the right tool equipped, were pressed twice with a 90-frame
settle between — and produced no gather event. That is either a node needing
more swings than two, a tool/amount interaction, or a real swallowed interact.
One run cannot tell which, and it changes the number above materially. **A
lane wanting to settle the economy should start here**, because until it is
settled the measured shortfall and the authored shortfall are not the same
claim.

---

## MEASURED-F6 — there is no village frame-cost regression. Settling COST-T5-5 with the second and third samples it asked for

**Not a defect.** Recorded because `ralph/reports/handover-GATE-F-RUN7-2026-08-30.md`
§9.6 names it as the thing that will stop the next run, and asks for exactly
this measurement: *"Settle COST-T5-5 with a second measurement. It currently
rests on one lane's one sample."*

`route.csv` carries play time and wall time on every row, so the sustained rate
can be read directly. Three segments on this box, this candidate:

| segment | play | wall | the one stand-up in it | wall−stand-up ÷ play |
|---|---:|---:|---:|---:|
| S01 | 180.3 s | 262.0 s | 80.4 s | **1.007** |
| S02 | 296.5 s | 346.0 s | 48.4 s | **1.004** |
| S03 (attempt 1) | 1114.3 s | 1174.0 s | 44.2 s | **1.014** |

**The game runs at real time, headless, in the village, for the whole of every
segment.** All the excess wall clock in a segment is one cold world stand-up of
44–80 s, paid once, before the first step.

`ralph/T5-PLAY`'s COST-T5-5 reached the same conclusion from one lane's samples
and was left explicitly unreplicated by run 7, which had no number of its own.
These are the samples it wanted, taken independently on a different box and a
later candidate, and they agree: **the `measured_frame_cost_s_in_scene` figures
that read 0.20 s/frame are single 120-frame windows containing a one-off, not a
measurement of the world.** The village is not expensive. The cost gate's CD-7d
median fix is doing its job — it refused nothing in this run.

**What this does NOT settle:** anything about the game's cost on real hardware
with a real renderer. This is a headless logic lane and every number here is
about simulation, not about frames on a screen. Device frame rate, GPU time,
VRAM and thermals remain [OWNER-ONLY].

---

## GAME-F3, second pass — it is not one deadwood node. The meadow itself outbids the fight

**Amends GAME-F3 above with S03 attempt 2's evidence.** The rig fix (RIG-F4)
worked: attempt 1 of the ladder now engages cleanly —

```
S03-32a2  pressed `interact` on "  Engage Bramblebun" (provider 'EncounterDirector'):
          context world -> combat
```

— so the ten-identical-attempts artefact is gone and what is left is the game.
What is left is broader than one node:

| attempt | what won the interact button |
|---|---|
| 1 | **Engage Bramblebun** — the fight staged |
| 6 | `Gather deadwood` |
| 9 | **`Strip meadow grass`** |
| 2,3,4,5,7,8,10 | `Ripplet is out of the fight.` — see below |

**`Strip meadow grass` is the ground.** `vegetation_harvest_point.gd` makes the
scatter harvestable and the boot log reports **59,165 harvestable props** in the
world. So the competing offer is not a single authored node the chapter could
move — it is the meadow, and a wild creature standing in grass is competing
with the grass it is standing in, on equal priority, decided by whichever is
nearer.

That does not make it a bug. `prompt_arbiter.gd`'s nearest-wins rule is
deliberate, `encounter_director.gd`'s priority 0 is deliberate and the comment
above it explains what happened the last time it was not, and a player who
steps forward gets the creature. **But it is the shape of the thing to decide
about**, and it is bigger than the one-coordinate fix option 1 above proposes.
A fourth option belongs beside the three: give the engage offer a priority edge
over *harvestables specifically* while inside engage range, leaving trainers,
doors and villagers untouched.

## GAME-F2, second pass — the cost of the missing level pin, measured directly

Attempt 2's first engage staged the fight and **the starter lost it**:

```
t=202.8 .. 224.5   Moss (ripplet L3) 45.2 -> 39.0 -> 32.0 -> 25.4 -> 18.2 -> 12.2 -> 6.3 -> 0.0
```

Seven hits, no recovery, and every one of the ladder's remaining attempts was
then refused with `"Ripplet is out of the fight."` — which is
`encounter_director.gd` doing exactly what GAME-0's fix asks of it, correctly
and legibly. **The team never reached three in either attempt, for two entirely
different reasons.**

Moss entered S03 at **45.2 of 117.6** because S02's practice fight was against a
band-rolled level-5 bramblebun instead of the level-2 the chapter's own curve
documents — GAME-F2. A starter that leaves the opening at 38% health loses the
next fight. That is what the missing pin costs, and this is it measured on the
played path rather than argued from a table.

## RIG-F5 — two side-effects of this lane's own ladder fix, recorded against it

**Severity:** RIG. **Recorded, not re-tuned** — a second speculative pass at the
same ladder in the same run would be tuning against one sample.

1. **`within: 1.8` is below the 3D tolerance the ground needs.** Attempt 6:
   *"reached bramblebun in plan view (1.80 m in x/z) but it is 1.81 m away in 3D
   — 0.22 m of that is vertical."* CD-5's `close_3d` is right to refuse, and 1.8
   simply has no room for a creature standing 22 cm up a slope. **2.0 is the
   floor a future pass should use**, not 1.5 or 1.8.
2. **A high rank can resolve a creature outside the village.** Attempt 7 took
   rank 4 and walked 38.4 m before stopping at (−9, 26) — which is the village
   outline between its `[3,26]` and `[-15,27]` points. The fence stopped it, the
   same way it stopped S03-83 and S03-85 (GAME-F1). **Ranks above 2 reach past
   the practice cluster**, and a future pass should either cap the rank at the
   cluster's own `count` (3) or give those attempts a `poi:wild` search bounded
   to the meadow.

Both are cheap to fix and both are this lane's own doing. Written down rather
than adjusted, because the ladder has now been changed once mid-audit and a
second change would leave nobody able to say which version produced which
number.
