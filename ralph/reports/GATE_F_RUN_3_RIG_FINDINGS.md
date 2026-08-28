# Gate F run 3 — findings about the RIG

**Date:** 2026-08-28. **Branch:** `ralph/GATE-F-RUN-3`.
**Run directory:** `ralph/reports/gate-f-run-20260828T183531Z`.
**Candidate (the game):** `main@26f0db4`, unchanged for every segment.
**Companions:** `GATE_F_RUN_3_FINDINGS.md` (the game), `GATE_F_CAPTURE_LANES.md` (the unpaid frames).

Kept separate from the findings about the game deliberately. Round 1 of Gate F
captured 8% of what it was asked to and four of Phase B's findings turned out to
be the instrument; the only defence against repeating that is to say, of every
finding, which of the two it is about — before anyone has to guess.

Four of the five below were found by running. The other was found by reading the
artefacts of a segment that had already produced a wrong answer.

---

## RIG-1 — `objective_is` compared two different id spaces, and failed all 26

**Severity: BLOCKER for evidence quality.** Fixed, commit `82fd6c9`.

`data/progression/objectives.json` gives every main-chain entry two ids: an
`id` (`opening_first_catch`) and a `flag_id` (`opening:beat:road`). Protocol
§E.5 tracks "24 main-chain objectives from `opening_first_catch`", so all 26
`objective_is` asserts across ten segments were transcribed in **entry ids**.
`gate_f_probe.gd::tracked_objective()` returns the **flag id** — deliberately,
under its own smoke test, because a flag id is what Phase B can cite and check
against the store.

Found on the first segment of the first attempt. S01-12 asserted
`opening_first_catch`; the game was tracking that beat, with the right text on
screen — *"Catch your first wild creature."* — and the step recorded FAIL.

Neither side is wrong and neither should move, so the **comparison** resolves:
it accepts the flag id, or the authored entry id that names it, and its `actual`
text says which space it matched on so the two can never quietly become one.

Left unfixed this was 26 failures in ten segments, every one a finding about the
instrument wearing the shape of a finding about the game. **That is round 1's
failure mode exactly.** The five minutes of S01 that found it were discarded
rather than carried forward.

---

## RIG-2 (CD-7c) — the cost gate refused a segment for the cost of standing up its world

**Severity: BLOCKER.** Fixed, commit `435fbb8`. Primary evidence preserved at
`gate-f-run-20260828T183531Z/S03-superseded-1/`.

S03 BLOCKED at step 9 of 274, **91 seconds in**, predicting **11.6 hours** for a
segment that costs about half an hour.

The in-play recheck divides wall already spent by physics frames already ticked.
That is the right question between two boots and the wrong one across a scene
change. S03's Load press built the Meadows: 42.8 s of wall across the 122
physics frames that had ticked by then.

| | |
|---|---|
| measured by the recheck | **0.351 s/frame** |
| the scene's real in-logic price | **0.0166 s/frame** |
| ratio | **21×** |
| projected across | 119,472 remaining frames |
| predicted | 41,892 s (11.6 h) against a 14,400 s ceiling |

S01's own ledger shows the same shape and survives only by luck of having fewer
frames left to multiply: an in-play sample of **0.671 s/frame**, then **0.017
s/frame two seconds later**. The first number is not a price, it is a
construction.

Two changes, and the second is the load-bearing one:

1. **A load re-prices and resets the sampling window, exactly as a boot does.**
   §H's 2026-08-28 amendment says the harness "re-prices after **every** boot" —
   but a journey segment does not boot into its world, it **loads** into it, and
   nothing re-priced there.
2. **An in-play sample over the ceiling ARMS a refusal; the next 120-frame
   window confirms or clears it.** A scene that is genuinely unaffordable is
   still unaffordable 120 frames later and still blocks, at a cost of about two
   seconds of play. A transient disarms itself. Boot and load re-prices still
   refuse immediately — they stop and measure a settled scene — and disk is
   exempt, because bytes on disk are not a transient.

**Verified:** S03 blocked at 91 s before the fix, and reaches 578 s of play with
no `BLOCKER.md` after it.

Note that change 2 is what actually saved S03 — see RIG-3 for why change 1
could not have.

---

## RIG-3 — no segment in the protocol calls `await_load` or `await_save`

**Severity: coverage defect.** Not fixed; it is a change to eighteen step
scripts and a §I.4 measurement decision, not a lane's call.

The schema defines `await_load` ("place immediately after the title screen's
Load press … emits a `load` event with the measured `duration_ms`") and
`await_save`. Counted across every segment:

| | `seed_save` | `await_load` | `await_save` |
|---|---:|---:|---:|
| S03–S10, X01–X06 | 34 | **0** | **0** |

Every seeded segment presses Load and then `wait`s a fixed 180 s. Three
consequences:

- **§I.4's load-duration measurement is never taken anywhere in the run.** The
  interval a player actually experiences — button to playable world — is one of
  the few numbers this envelope *can* honestly produce, and no segment produces
  it.
- **A failed load is discovered by a later assert**, several steps downstream,
  rather than at the step that was supposed to load.
- Every seeded segment spends a fixed 180 s of play regardless of what the load
  actually cost.

It is also why RIG-2's first change could not have saved S03 on its own: there
was no `await_load` for it to fire in.

---

## RIG-4 — a `seed_save` whose source is missing does not stop the segment

**Severity: SHIP for evidence quality.** Not fixed.

When S03 blocked, no `S03-exit.json` was written, and S04 started anyway:

```
t=0.25  load    FAIL seed source .../saves/S03-exit.json does not exist
t=0.25  defect  FAIL seed source .../saves/S03-exit.json does not exist
t=0.75  region_enter  ctx=title
...
164 route rows, every one of them in `title` context
```

The seed failure is a FAIL, so the run continues. The segment then booted the
title, pressed at an empty slot list, and spent its whole recorded trace on the
title screen — producing verdicts about a game it never entered.

This is the same class the schema's **derail** rule already exists for:

> *"A step whose required context does not hold is not a verdict on the game — it
> is a statement that the instrument is pointed at the wrong thing. Running the
> next forty steps anyway does not collect forty more findings; it collects forty
> fabrications."*

The save handoff is not covered by that rule. A segment whose **entry state does
not exist** has been pointed at the wrong thing before its first real step, and
should derail or BLOCK rather than FAIL and continue. Note the run-2 fix in
`_step_seed_save` repaired the *path resolution* half of this; the "what if it
genuinely is not there" half is still open.

---

## RIG-5 — a modal that owns input produces a false *navigation* finding

**Severity: BLOCKER for evidence quality.** Not fixed. This is round 1's
refuted-findings defect, still open, on the one step class the round-2 fix does
not cover.

Found live in S03. The sequence, from `events.jsonl` and `route.csv`:

```
t=269.3  walked 6.1 m to (22,-6)                       ctx=world
t=269.3  a DialoguePanel opens (Oskar)                 ctx=narrative_modal
t=269.4  press interact  -> flag oskar_trade_open
t=269.8  ctx=panel:SwapPanel   owner=SwapPanel   focus="1.  Moss  Lv 3"
t=271.2  press interact x10                            ctx=panel:SwapPanel
t=321.2  FAIL did not reach (16,-28) in 3000 walking frames;
         stopped 25.9 m short at (22.0, 1.0, -3.0)  (0 held)
t=372.5  FAIL did not reach (12,-22) in 3000 walking frames;
         stopped 21.7 m short at (22.0, 1.0, -3.0)  (0 held)
```

The player did not move a metre for **105+ seconds of play**. Read cold, those
two failures say *the village has a spot you cannot walk out of* — a SHIP-severity
world defect. **It is nothing of the kind.** Oskar is a creature vendor;
`sequence_director.gd::_maybe_open_shop()` opens `swap_panel.gd` for him;
`swap_panel.gd` closes on **`menu_cancel`**, and the step script pressed
`interact` twelve times and never pressed cancel. The game did exactly what it
should.

Two separate holes, and the second is the one that matters:

1. **The step script has no exit from a vendor panel.** It assumed `interact`
   dismisses what `interact` opened.
2. **`move_to` did not know the panel was there.** `stick_navigator.gd` decides
   "held" by asking `player.locomotion_enabled()`, and that flag is set by
   `sequence_director` for narrative modals, by `encounter_director` for combat,
   by `throw_aim`, and by `player_death` — **but not by any station or vendor
   panel**, which pause the tree instead. So the navigator saw locomotion as
   enabled, pressed the stick into a paused tree for 3,000 frames, and reported
   a *navigation* failure with `(0 held)`.

The schema promises the opposite: *"The FAIL message names the `input_context`
that held it."* It names it only when frames were counted as held — so the
message is silent in exactly the case where it was needed.

**Why this is the important one.** The schema's own derail rule was written for
this class after Phase B refuted 202 journey failures, of which *"118 in X01 and
21 in X02 … were the harness pressing at a modal it did not know was open."* The
round-2 fix routes `require_context` and `assert_context` through a derail. It
does **not** cover `move_to` / `move_to_entity`, and travel steps are where a
journey segment spends most of its time. The defect class that produced 139
refuted findings in round 1 is still live on the most common step in the
protocol.

**Recommended fix**, in the order they matter: give `move_to`'s held-detection a
second source of truth — the input context, treating any `panel:*`,
`narrative_modal` or `menu*` context as held, rather than only
`locomotion_enabled()`; then name that context in the FAIL text whether or not
frames were counted as held; then add the missing `close_menu` to the step
scripts that open a vendor.

---

## What these five have in common

None of them is about Tetherbound. Three of them — RIG-1, RIG-2, RIG-5 — would
have been read, in a Phase B that saw only the artefacts, as evidence about the
game: 26 objectives that never advanced, a chapter too expensive to play, and a
village with a spot you cannot walk out of. All three are the instrument.

RIG-3 and RIG-4 are quieter and the same shape: an instrument that does not
measure what it says it measures, and an instrument that keeps recording after
it has stopped pointing at anything.

RIG-5 deserves the last word, because it is not a new defect. It is the one
Phase B already found in round 1, already diagnosed, and already half-fixed —
and the half that was left is the half a journey segment spends most of its time
in. A rig that fixes the modal problem for asserts and not for walking has not
fixed the modal problem.
