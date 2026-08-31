# GATE-F-CAPSTONE-1 — defects, live log

Run: `ralph/reports/gate-f-capstone-1`, branch `ralph/GATE-F-CAPSTONE-1`,
candidate `88df9f47` (nine Gate F leg lanes consolidated onto `main`,
CI green, 1675 tests).

Severity words follow the Gate F protocol: **BLOCKER** (the chain cannot
proceed), **SHIP** (a player-facing defect a real player would report),
**QUALITY** / **POLISH**, and **RIG** (the instrument, not the game).
Severity here is a *candidate* only — section C.1 gives the final call to Phase B.

Per protocol section 13 / section J this lane changes **no game code, data or
config** and does not diagnose root causes. Every entry is what happened, with
the evidence that shows it.

---

## CAP-1 — the opening's "cannot fail twice" catch failed four times, the starter fainted, and the chapter carried on regardless

**Severity candidate:** SHIP. **Segment:** S02. **Steps:** S02-42 … S02-46.
**Status:** recorded, not fixed (game frozen for this lane).

### What the game promises

`data/config/opening.json` -> `encounter`:

```json
"species": "bramblebun",
"max_catch_failures": 1,
"_comment_catch_bound": "docs/OPENING_SEQUENCE.md says the tutorial catch
  cannot fail twice. This bounds only landed, otherwise-legal throws at this
  configured species while the opening is on its encounter beat."
```

`scripts/story/sequence_director.gd:1171-1180` opts this exact encounter into
`CombatManager.configure_tutorial_catch_assist()` on combat entry, behind an
`_is_tutorial_catch()` beat-and-species predicate.

### What happened

From `S02/telemetry/events.jsonl`, play-clock seconds:

| t | event |
|---|---|
| 224.02 | `combat_start` — Ripplet "Moss" L3, 117.6 HP vs bramblebun 106.2 HP |
| 229.32–230.45 | charged + quick attacks land: opponent 106.2 -> **63.5** |
| 234.07 | throw 1 — `lost [orb_basic -1]`, no catch |
| 240.65 | throw 2 — `lost [orb_basic -1]`, no catch |
| 247.18 | throw 3 — `lost [orb_basic -1]`, no catch |
| 253.65 | throw 4 — `lost [orb_basic -1]`, no catch |
| 230.83–270.60 | **18 consecutive unanswered hits** on Moss, ~6.5 dmg each |
| 270.60 | `faint` — "Moss fainted", opponent still at 63.5 HP |
| 272.22 | `combat_end`, `input_context` combat -> world |

Four landed-or-missed throws, no catch, against a documented bound of one
failure. Orb stock 15 -> 11 confirms four throws were actually spent.

### The limit on this claim, stated rather than papered over

The bound counts **landed** throws on purpose — a physical miss is not a failed
catch. **This run cannot tell a landed throw from a miss**, because the harness
emits no `catch_throw` and no `catch_result` event for an in-combat throw; the
only trace of each throw is an inventory delta. So this entry does **not** assert
the bound is broken. It asserts the promise did not hold in play, and names the
instrument that prevents the run from saying which half failed. See **CAP-2**.

A bounded reproduction (protocol section J, budget 3) is owed and is run in a
SEPARATE run directory so the capstone save lineage stays untouched.

### What it costs the player, and why the consequence is worse than the fight

The consequence is not the lost fight. It is the state the chapter then carried
forward. `S02/saves/S02-exit.json` — the real exit save S03 is chained from:

- party of **1**, `"fainted": true`, `"hp": 0.0`
- progression flags **without** `opening:beat:road`
- progression flags **with** `road_gate_open`

`data/progression/objectives.json` gives `opening_first_catch` the flag
`opening:beat:road`. So **main-chain rung 4 of 27 is still open while rung 5 is
complete**: losing the tutorial fight gates neither the key nor the gate, and the
player walks into the village behind a tracked line that still reads *"Catch your
first wild creature."* Nothing in the run offered a defeat, consequence or
recovery beat — `combat_end` handed world control straight back with a 0 HP
creature (protocol section E.1 CB-07 expects a defeat -> consequence -> recovery
loop; none ran here because the loss was not the scripted one).

S03's span requires a team of three and a training ladder. It is entered here
with one fainted creature.

### Not a defect, checked and discarded

The harness line `tracked objective id=opening:beat:road text=Catch your first
wild creature.` is **not** an id/text mismatch. The harness reports the
objective's `flag_id`, and `opening_first_catch` legitimately carries
`flag_id: "opening:beat:road"`. Recorded here because it looks like a defect and
is not.

---

## CAP-2 — an in-combat orb throw emits no `catch_throw` and no `catch_result`

**Severity candidate:** RIG. **Segment:** S02 (and every catch in the run).
**Status:** recorded, not fixed (rig frozen during the run, section J).

Both types are in the section C.1 enum. Across S02's four tutorial throws the
only `catch_result` in `events.jsonl` is the **starter grant** at t=204
("party grew 0 -> 1"); the four real throws produce nothing but an
`inventory` delta on a `note`.

This is the failure class CD-6 exists to name: *a schema field that no code
writes is an instrumentation defect, and Phase B may not treat its absence as
evidence.* Its concrete cost is already visible one entry up — CAP-1 cannot
separate "the bound did not hold" from "three of four throws physically missed",
and the section E.2 study's required per-throw record (aim time, distance,
target species/size, hit/miss and stated reason, shown percent, result) has no
source at all.

---

## CAP-3 — section H's continuous record for S01/S02 has no implementing action

**Severity candidate:** RIG. **Segments:** S01, S02. **Status:** recorded.

Section H makes S01+S02 mandatory continuous-evidence segments ("PNG every 2 s
(0.5 Hz) plus a forced frame on every JSONL event"). The step vocabulary in
`tools/gate_f/SEGMENT_SCHEMA.md` has no background-recorder action —
`capture_seq` is a bounded, blocking run of frames, not a recorder that runs
while other steps play. S01's own step S01-01 records the gap rather than
claiming the record exists, which is the right behaviour; the consequence is
that section H's continuous-evidence clause is **unpaid on this run**, as it was
on previous ones.

---
