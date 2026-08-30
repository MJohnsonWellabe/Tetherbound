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
## COST-T5-5 — the cost gate refuses affordable segments, and it stopped the chapter

**Severity:** RIG, **BLOCKER** — it is what stops the run reaching the Warden.
**Fixed by this lane.** **There is no game performance regression. I said there
was; I was wrong, and the correction is below.**

### What happened

S03 stopped at **step 136 of 406**:

```
BLOCKER — S03 is too expensive to finish here
re-priced at in-play, the REST of this segment predicts 20488 s (5.7 h)
against 13354 s of the 14400 s ceiling left: 101063 planned frames at a
MEASURED 0.203 s/frame in THIS scene.
```

### What I claimed first, and why it was wrong

I read `measured_frame_cost_s_in_scene` across the segments and reported a
world-performance regression:

| segment | in-scene s/frame | what I said |
|---|---|---|
| S01 | 0.0167 | Grandpa's house |
| S02 | 0.0473 | village edge |
| S03 | 0.2027 | "the village proper — 4.3× the edge" |
| run 5's S04 | 0.0479 | "so the village got 4.2× more expensive" |

**Every one of those numbers is an artefact of the defect, not a measurement of
the world.** They are single 120-frame windows that happened to contain a
one-off cost. Comparing two of them compares two artefacts.

### What is actually true, measured from both clocks

`route.csv` carries play time and wall time on every row, so the sustained rate
can be read directly rather than inferred:

```
=== S03: 891 rows ===
  play_s   wall_s   ratio  s/frame  region
      38      485    13.1   0.2185  grandpas_village   <- the world stand-up
      75      522     1.0   0.0167  grandpas_village
     186      634     1.0   0.0169  grandpas_village
     348      799     1.0   0.0169  grandpas_village
     588     1044     1.0   0.0168  grandpas_village
```

**Wall/play ratio 1.0.** The game runs at real time, headless, in the village,
for the whole segment. The only expensive interval is the first sample, which
contains the ~450 s cold world stand-up — a cost the segment had already fully
paid before the gate fired.

**Sustained cost: 0.0167–0.0172 s/frame.** True cost of S03's remaining 101,063
frames: **about 29 minutes**, not 5.7 hours. The gate was wrong by ~12×.

S02 shows the identical shape (first sample 0.330, then a flat 0.0163–0.0176),
which is why its `in_scene` figure reads 0.047 while its sustained rate is the
same 0.017 as everything else. **The village is not expensive. Nothing is.**

### The mechanism

`_apply_price` predicts as `remaining_frames × now`, where `now` is one
120-frame window from `_cost_recheck`. Any one-off inside that window — a fight
staging, an arena build, a region streaming in — becomes the price of every
remaining frame.

CD-7c already saw this coming and added an arm-then-confirm: an over-budget
in-play sample arms, and the next window decides. **That was not enough**, and
S03 is the proof: a one-off that spans *more* than 120 frames reads high in two
consecutive windows, and the second confirms the first.

### The fix (CD-7d, instrument only)

1. The prediction now uses the **median of the last nine** in-play windows
   instead of the latest one. A sustained cost still refuses — capture mode's
   10.5 s/frame is sustained, so its median is 10.5 — while one or two spikes
   move a nine-sample median by nothing.
2. A refusal additionally requires **at least three samples**, so the first
   window after a scene change cannot decide a whole segment.
3. The raw window price is still written to the ledger as `observed_window_s`
   beside the median. **Smoothing a spike out of the evidence would hide a real
   regression starting**, which is the opposite of the point.

### Why this matters beyond one segment

This gate is a plausible contributor to Gate F's six unfinished attempts. It
refuses *late* — 136 steps in, after the expensive world stand-up is already
paid — so every attempt pays full price for a segment and then throws it away,
and the refusal names "a GPU or a split evidence lane", which sends the reader
after capacity that was never the problem.

---

## GAME-T5-6 — the starter faints early, and recovery costs one of two Revives

**Severity:** SHIP candidate, **downgraded from my own first reading of it** —
see "what I got wrong" below. **Observed, not root-caused**: S03 was cut off at
step 136 of 406 by COST-T5-5.

**What the run recorded.** During the village team-building ladder, with the
party at 2 (Moss the L3 ripplet, and the caught L5 bramblebun), eight
consecutive engage attempts were refused with the same shape:

```
the live prompt is "Ripplet is out of the fight.", which does not contain
"Engage" -- pressing here would activate a different provider. Not pressed.
```

and `S03-39 the team is three` failed at `party size 2 (wanted >= 3)`.

**What I got wrong, corrected against the rest of the same segment.** I first
logged this as the "fainted party that nothing ever heals" stranding. It is not,
on this evidence. The very next steps ran the game's own designed answer, through
the real Satchel UI a player would use, and **all of them passed**:

```
S03-39e  open the Satchel                          PASS
S03-39f  focus the Revive draught                  PASS
S03-39g  try to use it on whoever needs it         PASS
S03-39h  confirm the target if a picker opened     PASS
S03-39k  the world owns input again                PASS
```

and the run then walked to Bryn on the practice ground, challenged him, staged
the fight and **switched pilot mid-fight** — every one of those a PASS — before
the cost gate stopped it mid-fight at S03-51.

**So the honest finding is narrower and still worth having:** the chapter's own
first hour leans on the Revive draught, of which the opening satchel grants
**two**. The starter going down is not an edge case — `ralph/T2-GATEF-RUN6`
measured the opening fight fainting the starter in 4 of 5 runs (GAME-11), and
this run's own village stretch spent one Revive before the first trainer. Two
consumables, no resupply named before the tournament, against a failure mode
that reproduces. Whether that is tuned or merely survivable is a **pacing and
economy question for a tuning lane**, and it needs the rest of S03 — the beds,
the sleep, the feeding — which has not run.

**Do not close, and do not escalate, on the evidence here.**

**Also recorded** from the same partial run, two live instances of the
modal-holds-locomotion class the brief names — a walk step beginning while
something other than the world owned input:

```
the world owns input before this walk  ->  FAIL: input_context=narrative_modal
the world owns input before this walk  ->  FAIL: input_context=combat_aim
```

Both are the diagnostic asserts `4de89a11` added for exactly this, doing their
job: they name the cause at its origin instead of letting it surface later as a
walk that "did not reach".

---
