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
## RIG-T5-4 — the gate moved too, and `GATE_AT` is now dead code

**Severity:** RIG. **Same integration failure as RIG-T5-3, second half.**
**Fixed by this lane, because it blocks the run.** **The game is not at fault
and this was proved, not assumed.**

With RIG-T5-3 fixed, the S02 re-run took the key correctly
(`pickup:castle_gate_key` set, `castle_gate_key n=1` in the satchel) and the
gate *still* did not open — and the key was **still in the satchel** in the exit
save. `item_gate.gd::try_open` consumes the key on success, so an unconsumed key
proves `_on_tried` never ran: the press never reached the gate.

**Measured, not reasoned** — `tools/gate_f/diag/probe_road_gate.gd`, added by
this lane, on this candidate:

```
gate node   : RoadGate at (38.70, -2.66, -19.90)
gate prompt : radius=4.00  label=Try the gate  enabled=true
gate key    : (30.70, 0.48, -15.90)

stand-off |   3D dist | offer | drawn | winning label
     0.8  |      1.15 |   YES |   YES | Try the gate
     2.9  |      2.90 |   YES |   YES | Try the gate
     3.6  |      3.61 |   YES |   YES | Try the gate
     4.0  |      4.03 |    no | other | Learn TM: Stone Rush

PASS 3 — key in hand, pressed through the real arbiter at 2.9 m:
  arbiter.activate()=true   road_gate_open=true   key held=0
```

**The gate works.** Given the key and a player within reach, it opens, says its
line and consumes the key. What failed is where the rig stood:

| | position |
|---|---|
| gate, as actually built | **(38.7, −19.9)** — `data/config/village_boundary.json`, RoadGate entry, the computed road/outline intersection |
| `S02-51` walk target | **(27.5, −16.0)** = `playground_world.gd::GATE_AT` |

**11.9 m apart, against a 4.0 m prompt radius.** The press landed on open ground.

**`GATE_AT` is now dead code.** `ralph/T5-OPENING` replaced the hand-placed gate
with the config-driven village boundary; the constant is still declared in
`playground_world.gd:90` and places nothing. Its neighbouring comment — *"far
enough from `GATE_AT` that the two interactables' radii (4.0 m gate, 2.4 m key)
do not overlap"* — now describes a geometry that no longer exists. A dead
constant that still reads like the answer is exactly the trap the rig fell into.

**Fix applied (instrument only):** `S02-51` walks to the config's RoadGate `at`,
and `close_enough` tightened 3.0 → 2.0 because the probe shows a neighbouring TM
pickup outbidding the gate from 4.0 m out.

**Recommended, not done here (game-side, out of this lane's scope):** delete
`playground_world.gd::GATE_AT` and its stale comment, or make it read the config.
Leaving a dead coordinate that names the chapter's first gate will catch the
next reader too.

---
## COST-T5-5 — the village now costs 4× what it cost at run 5, and it stops the chapter

**Severity:** BLOCKER for the run. **Open question — game or instrument —
being measured, not asserted.**

S03 stopped at **step 136 of 406** on the harness's own cost gate:

```
BLOCKER — S03 is too expensive to finish here
re-priced at in-play, the REST of this segment predicts 20488 s (5.7 h)
against 13354 s of the 14400 s ceiling left: 101063 planned frames at a
MEASURED 0.203 s/frame in THIS scene.
```

**The measured frame cost, same box, same binary, same instrument:**

| segment | where the player is | in-scene s/frame |
|---|---|---|
| S01 | Grandpa's house / dooryard | **0.0167** |
| S02 | village edge, meadow, road gate | **0.0473** |
| S03 | the village proper | **0.2027** |
| *run 5's S04, 2026-08-30* | *the village proper* | *0.0479* |

Two readings of the same number, and they are not the same finding:

- **Within this run**, walking from the village edge into the village proper
  costs **4.3×** more per frame. That is location, not drift.
- **Against run 5**, the village proper costs **4.2×** what it cost days ago on
  the same container with the same instrument.

`ralph/LAND-0830I` landed T1-VILLAGE, T1-HALL-3, T1-CAST, T1-RIG-2,
T1-VARIANTS-2, T3-DENSITY, T3-ACTIVITIES and T5-CAMPS between those two
measurements.

**This is not yet a claim about the game.** The harness's own per-frame
telemetry tick walks the party, the quest log and the point-of-interest cache
every frame, and T3-DENSITY and T5-CAMPS both add POIs — so an instrument that
scales with content is a live hypothesis with a motive. `--gatef-mode=overhead`
(telemetry off vs on vs recording, six windows, order reversed to cancel drift)
is running to separate them. **No device claim is made either way**: this is CPU
frame time on this container, headless, software only. ROG Ally frame rate is
[OWNER-ONLY].

---

## GAME-T5-6 — the starter faints in the village and the team never reaches three

**Severity:** SHIP candidate. **Observed, not yet root-caused** — S03 was cut
off at step 136 by COST-T5-5, so this is what 136 steps showed, not a verdict.

During the village team-building ladder, with the party at 2 (Moss the L3
ripplet and the caught L5 bramblebun), the run recorded **eight consecutive**
engage refusals of the same shape:

```
the live prompt is "Ripplet is out of the fight.", which does not contain
"Engage" -- pressing here would activate a different provider. Not pressed.
```

followed by:

```
the team is three   ->  FAIL: party size 2 (wanted >= 3)
```

The starter is down, the prompt the world offers is the fainted-ally line rather
than an engage offer, and the third catch never happens. The tracked objective
at that moment reads *"Build your full team of five for the village tournament"*
— clear direction the player cannot act on.

This is the same shape `ralph/reports/SPAWN_REQUEST-T2-GATEF-2026-08-30.md`
described as *"a fainted party from S03 that nothing ever heals"*, reproducing
on a newer candidate.

**What is not yet established, and matters:** whether a player would be stranded
or would simply heal and continue. S03 contains creature beds, sleep and feeding
later in its script — past step 136. Whether the recovery the chapter offers
arrives *before* the tournament demands three is exactly the question the rest of
S03 answers, and it has not run. **Do not close or escalate this on the evidence
here.**

Also recorded from the same partial run, one live instance of the
modal-holds-locomotion class the brief names:

```
the world owns input before this walk  ->  FAIL: input_context=narrative_modal
the world owns input before this walk  ->  FAIL: input_context=combat_aim
```

---
