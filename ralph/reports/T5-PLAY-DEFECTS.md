# T5-PLAY — defects found while playing the chapter

Live log. Each entry says what was observed, where, and what it costs a player
(or, for a RIG entry, what it costs the evidence). Ranked at the end of
`PLAYTHROUGH-2026-08-30.md`, not here.

Severity words follow the Gate F protocol: **BLOCKER** (cannot proceed),
**SHIP** (a player-facing defect that would be reported), **RIG** (the
instrument, not the game).

---

## RIG-T5-1 — every logic-lane run in a fresh run directory refuses at step 0

**Severity:** RIG, BLOCKER-shaped for anyone trying to start a run.

`operator_harness.gd::_freeze_display_claim()` reads two places, nearest first:
the run directory's own `RUN_METADATA.json`, then the global
`ralph/reports/gate-f-candidate/RUN_METADATA.json`. That global record is the
2026-08-27 freeze. It carries a **flat** `"display_server": "X11 under
xvfb-run"` and **no `lanes` block** — so a logic-lane segment run headless is
compared against a claim of X11 and refused by CD-8b:

```
gate-f harness ERROR: capture pre-flight BLOCKER: the freeze record
contradicts this process: the freeze record at
ralph/reports/gate-f-candidate/RUN_METADATA.json says
display_server=X11 under xvfb-run; this process has none
```

Every segment fails this way, in about one second, before a single step runs.
S01 and S02 both did on this lane's first attempt.

**Why it matters beyond this lane.** The refusal is correct behaviour — CD-8b
exists because a run once claimed X11 while producing headless artefacts — but
the *default* is wrong: the nearest freeze record is a stale global one that
contradicts the lane the harness itself calls normal ("the evidence split makes
a run that is headless for its logic lane and X11 for its capture lane the
normal shape"). So the documented, supported way to run is refused unless the
operator already knows to hand-write a per-run freeze record first. Nothing in
`run_segment.sh --help` says so, and `run_segment.sh` does not write one.

**What this lane did:** wrote
`ralph/reports/gate-f-run-T5-PLAY/RUN_METADATA.json` declaring the logic lane
honestly, *before* the run started — which is what the harness's own comment
requires ("a run that wants a logic lane must SAY SO IN THE FREEZE RECORD
BEFORE THE RUN"). Not amended mid-run.

**Suggested fix (not made here, out of scope):** either give the global
candidate record a `lanes` block naming the headless logic lane, or have
`run_segment.sh` write a run-local freeze record from the invocation it is
actually about to make.

---
## RIG-T5-2 — S01 expects an objective rung the opening no longer starts on

**Severity:** RIG. **The game is better than the script expects.**

S01-12 asserts the first tracked objective of a fresh game is
`opening_first_catch` (game flag `opening:beat:road`). Measured:

```
tracked objective id=opening:beat:choose text=Go down and hear Grandpa out.
```

`ralph/T5-OPENING` added earlier rungs to the opening ladder, so a fresh save
now tracks a clearer, earlier instruction than the one the 2026-08-27 segment
script was written against. A player waking upstairs is told to go down and
hear Grandpa out, which is the right first line. **No player-facing defect** —
`tools/gate_f/segments/S01.json` step S01-12 is stale and should track
`opening:beat:choose`.

Recorded rather than fixed: editing a segment mid-run changes the instrument
during the measurement, and this lane's job is the account.

---

## Measured, not a defect — front-door cost

| | |
|---|---|
| process start → title interactive | **476 ms** (30 settle frames) |
| title → world playable (New Game) | inside the segment's 180 s budget; world stood up, player spawned at (0.0, 2.9, 0.0) in `grandpas_village` |

`MEADOWS_EXIT_CRITERION.md` §K3 wants no core-verb reliability failure. The
front door is not one: it is fast, it focuses a control, and Start New Game
goes straight into the world with no overwrite prompt on a fresh install.

---
## RIG-T5-3 — the chapter's first gate never opens, because two landed lanes disagree about where the key is

**Severity:** RIG (a stale rig coordinate) with **BLOCKER consequence** for the
chapter. **Fixed by this lane, because it blocks the run.**

**What happened.** S02 played the whole opening correctly — starter chosen and
named, first fight staged and won, first catch landed, party 2/5 — walked 36.5 m
to the key, pressed interact, walked to the gate, pressed interact, and ended
with:

```
S02-54  the road gate is open  ->  FAIL: flag road_gate_open NOT set
```

The exit save carries 12 orbs and **no key**.

**Root cause, and it is an integration failure, not a bug in either lane.**

| | key position |
|---|---|
| `playground_world.gd::GATE_KEY_AT` (current) | **(30.7, −15.9)** |
| `tools/gate_f/segments/S02.json` step S02-49 walk target | **(31.2, −8.4)** |

`ralph/T5-OPENING` moved the key in `7da75ac7` — *"OP-0830-1: the village gate
now gates, because the village has an edge"*. `ralph/T2-GATEF-RUN6` fixed S02's
fight and catch on a branch that still carried the old coordinate. Both landed
into `ralph/LAND-0830I`. **Each lane was individually correct; together they
leave the chapter's first gate shut** — which is precisely the failure
`MEADOWS_EXIT_CRITERION.md` §K4 names: *"do not accumulate individually-successful
changes that fail together."* This is the first time anything has run far enough
to notice.

The old anchor stands **7.5 m** from the key against its **2.4 m** interact
radius, so the press hit nothing at all.

**Why it stops the chapter rather than costing one assert.** `road_gate.gd`
builds a `StaticBody3D` leaf with sealed wings out to `seal_half_width`. A
closed gate is a *hard physical block*, not a flag. `road_gate_open` unset in
S02's exit save is inherited by S03 → S04 → S05, and S05's whole span is
"leave village". The run cannot leave band 0.

**Fix applied (instrument only, no game code):**

1. `S02-49`'s anchor now reads `GATE_KEY_AT`'s current value.
2. New step **`S02-50a`** asserts `pickup:castle_gate_key` immediately after the
   press. A `press` step passes when input is *injected*, not when anything
   received it — the same root shape T5-FEEL named for the engage asserts — so
   without this the failure stays silent for five steps and then surfaces at
   S02-54 looking like a gate defect, which is what it did here and what it is
   not. If the two coordinates drift apart again, the run now fails at the key.

**Not fixed, and deliberately:** nothing in the game moved. The key placement,
the 2.4 m radius and the gate are all as their authors intended.

**Standing risk this leaves open, for someone else to decide.** No test ties
`GATE_KEY_AT` to the rig anchor, and none ties it to anything else either. The
same drift can happen again on the next lane that nudges the village edge.

---
