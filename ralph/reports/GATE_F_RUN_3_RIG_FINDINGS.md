# Gate F run 3 — findings about the RIG

**Date:** 2026-08-28. **Branch:** `ralph/GATE-F-RUN-3`.
**Run directory:** `ralph/reports/gate-f-run-20260828T183531Z`.
**Candidate (the game):** `main@26f0db4`, unchanged for every segment.
**Companions:** `GATE_F_RUN_3_FINDINGS.md` (the game), `GATE_F_CAPTURE_LANES.md` (the unpaid frames).

Kept separate from the findings about the game deliberately. Round 1 of Gate F
captured 8% of what it was asked to and four of Phase B's findings turned out to
be the instrument; the only defence against repeating that is to say, of every
finding, which of the two it is about — before anyone has to guess.

Six of the eleven below were found by running; five were found by reading the
artefacts of segments that had already produced wrong answers.

**If only one of these is read, read RIG-7 — it contains RIG-3, RIG-4, RIG-5,
RIG-6 and RIG-11 as instances.**

**If a second is read, read RIG-11.** It is the reason there is not one
`combat_start` event in this entire run, and the reason the finding that looked
most like a dead end in the chapter turned out to be ours.

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

## RIG-6 — the derail mechanism is never invoked by any segment in the protocol

**Severity: BLOCKER for evidence quality. This is the most important finding in
this document.** Not fixed: it is an edit to eighteen step scripts.

RIG-5 explained *how* one unclosed panel could produce a false navigation
finding. This is why it produced **fifty-eight** of them.

S03 ran all 274 steps and recorded 64 failures. Sorted by where they fall
relative to the `SwapPanel` that opened at t=269.8 and never closed:

| | count |
|---|---:|
| failures **before** the panel opened | **6** |
| failures **after** it, every one a step pressing at a panel that owned input | **58** |

The 58 are not 58 findings. They are one modal, counted 58 times. Every
`move_to` among them fails from the identical position `(22.0, 1.0, -3.0)`;
every menu, build and map step fails with `context panel:SwapPanel`. Handed to
Phase B unlabelled they say: *the build system is broken, the map will not open,
the inventory will not open, focus navigation is broken, and there is a spot in
the village you cannot walk out of.* **All five are false.**

The harness already has the mechanism that prevents this, written after Phase B
refuted 202 of round 1's journey failures. The schema states it plainly:

> *"a failed `require_context` records **one** FAIL, at the step that could not
> [run] … Running the next forty steps anyway does not collect forty more
> findings; it collects forty fabrications."*

**Counted across all eighteen protocol segments:**

| form | derails? | occurrences |
|---|---|---:|
| `assert` with `check: input_context` / `context_prefix` | **no** | **307** |
| `assert_context` | yes | **0** |
| step-level `require_context` | yes | **0** |

Both derailing forms appear **only** in `selfcheck_context.json` and
`selfcheck_reach.json` — the two segments written to test that the mechanism
works. It does work. No segment that produces evidence has ever used it.

So round 2's headline fix is, as the protocol is actually authored, dead code.
Every one of the 307 context checks in the run takes the form that records a
FAIL and carries on to the next step.

**What it costs, measured on this run rather than argued.** S03 alone: 64
recorded failures, of which 6 are about the game and 58 are one modal. That is a
**9% signal rate** — and round 1's whole indictment was that it captured 8% of
what it was asked to. The number has not moved, and this is the mechanism.

**Recommended fix.** Convert the 307 `assert{check: input_context}` /
`{check: context_prefix}` steps to `assert_context`, which is what they were
always saying, and add `require_context` to the step classes that must not run
in the wrong place — every `move_to`, `open_menu`, `interact_with` and
`press` that assumes the world owns input. One derail and 57 honest SKIPs is a
segment a reviewer can read. Fifty-eight fabrications is not.

---

## RIG-7 — every primitive round 2 built to fix a coverage defect has zero callers

**Severity: BLOCKER for evidence quality. RIG-3, RIG-4, RIG-5 and RIG-6 are four
instances of this one fact.** Not fixed: it is an edit to eighteen step scripts.

Counted mechanically across all eighteen protocol segments (`grep -o '"<action>"'`
over `S01–S10`, `X01–X08`):

| primitive | built for | callers |
|---|---|---:|
| `interact_with` | CD-5 — press `interact` only when the arbiter has a live prompt, and name what it could see instead | **0** |
| `move_to_entity` | reach a **thing**, re-resolved every frame, rather than a coordinate | **0** |
| `advance_dialogue_until_closed` | CD-3 — advance a modal by reading its line, not by a press count | **0** |
| `assert_context` | the derail rule, written after Phase B refuted 202 round-1 failures | **0** |
| `require_context` | same | **0** |
| `await_load` | §I.4's load duration — button to playable world | **0** |
| `await_save` | §I.4's save duration | **0** |
| `defect` | §C.1's first-class defect event | **0** |

And what the segments call instead:

| | count |
|---|---:|
| `press` with `control: interact` — blind, no prompt check | **263** |
| `move_to` — walk to a coordinate | **137** |
| `assert{check: input_context / context_prefix}` — records FAIL, does not derail | **307** |

`assert_context` and `require_context` appear in exactly two files in the
repository: `selfcheck_context.json` and `selfcheck_reach.json`, the self-checks
written to prove they work. They do work. Nothing that produces evidence calls
them.

**This is not an inference about intent — the harness says it out loud.**
`_step_interact_with`'s own header, on `main` today:

> *"The cost of not asking is on the record: S02-15 pressed `interact` 31 times
> through a floor, and **S02-32 pressed it once at a walked-to coordinate where
> the chapter's first wild fight was supposed to stage** — S02-34 then measured
> `input_context=world` and the whole rest of the segment ran without a fight
> having happened."*

S02-32 is still `{"action": "press", "control": "interact"}` on this candidate,
and in run 3 it did the same thing again. The defect was diagnosed, the fix was
written, the fix was documented against the exact step that needed it, and the
step was never changed.

**Measured consequence, this run.** At the two engage attempts that failed:

| | S02-32 | S03-32 |
|---|---|---|
| scripted target | (30, −40) | (30, −40) |
| where the player came to rest | (26.78, −38.32) | (27.77, −37.13) |
| distance from the scripted coordinate | 3.9 m | 3.6 m |
| nearest POI, 2D | 5.74 m | **6.57 m** |
| `encounter_director.gd` engage range, 3D | 6.0 m | 6.0 m |
| what the step did | blind `press interact` | blind `press interact` |
| what was recorded about why nothing happened | **nothing** | **nothing** |

S03's nearest point of interest was **outside** the engage range at the moment
the button was pressed. Whether the wild body was that POI or forty metres away
is not answerable from these artefacts — and *that* is the finding. `move_to_entity`
would have walked to the creature or failed saying "I arrived and nothing was
here"; `interact_with` would have named what the arbiter could see and how far
away it was, vertically and in plan. Both exist. Neither is called.

**Recommended fix, in priority order.** Convert the 307 context asserts to
`assert_context` and add `require_context` to travel and menu steps (RIG-6 — it
alone turns S03's 64 failures into ~7). Then convert the engage/interact presses
to `interact_with` and the encounter walks to `move_to_entity` (this finding).
Then `await_load` (RIG-3). None of it is harness work. All of it is the step
scripts.

---

## RIG-8 — the instrument cannot see either of the two things that decide an `interact`

**Severity: BLOCKER for evidence quality.** Not fixed.

S02's most consequential FAIL was a press that did nothing. Reconstructing why,
from the artefacts alone, turned out to be impossible — and the two facts that
would have settled it in one row each are both absent from every event this run
recorded.

`scripts/debug/gate_f_probe.gd` records no:

- **deployed-creature state.** `encounter_director.gd::_engageable()` returns
  null when no creature is out, *before it measures any distance*, so "is a
  creature deployed" is the first gate on every fight in the game. The probe's
  `active_creature()` reads `Game.party.active()` — the party's active
  **member**, not the body standing in the world. S02's telemetry therefore says
  `"active_creature": "Moss"` on all 118 rows, and that is equally consistent
  with a creature standing beside the player and with no creature deployed at
  all. The distinguishing call, `ally_body()`, is public and never asked.
- **interaction prompt.** The single most informative thing on screen at the
  moment of a press is the line the game is offering, and
  `interaction_arbiter.gd::prompt()` / `winning_provider()` are both public.
  Neither is in `input_state`, which carries `owner`, `focus_text`,
  `combat_running`, `combat_aiming` and `mouse_mode`. A press that lands on the
  wrong provider, or on a non-actionable status line, is indistinguishable in
  the record from a press the game ignored.

The cost is on the record. `DIAG-S02-ENCOUNTER/FINDING.md` had to drive the
entire production opening in a purpose-built probe to establish something a
two-field addition to `input_state` would have shown in S02's own `events.jsonl`:
that the encounter works, and that what was missing was a deployed creature. And
even that probe cannot say which of the harness's own deviations left S02
without one twenty seconds after `adopt_starter()` demonstrably built it, because
the segment that would have to answer has already been run and cannot be
re-interrogated.

**A re-run of S02 is not worth taking until this is closed**, because it would
produce the same unreadable record.

---

## RIG-9 — a logic lane re-armed the §H recorder and marked itself INCOMPLETE

**Severity: SHIP for evidence quality.** Fixed, commit `4e23c92`.

`record_hz` is zeroed for a logic lane when the segment loads — the evidence
split doing its job. `_step_record_start` then set `_record_hz` straight from its
own args and re-armed the recorder anyway.

S05 is where it showed. The segment ran all 76 of its steps — 54 PASS, 9 FAIL,
13 DELEGATED, no derail, no harness error — and was written out **INCOMPLETE**:

```
46 continuous frames were planned and not written:
  {"headless: this process has no display server and cannot render a frame": 46}
```

on a lane that had undertaken to take none. That is the outcome §H.1 forbids in
its own words: a logic-lane segment *"is judged against what ITS LANE owes, and
is not 'capture-incomplete forever' for a frame it never undertook to take."*
S06, S07, S08 and S09 each declare the same two windows and would each have
inherited it.

The windows are now handed over on the same terms as a prescribed §G frame —
their own DELEGATED verdict, a `frames.delegated_windows` ledger in
`INVENTORY.json`, and a line in `DELEGATED.md` naming the window, its rate and
its step. Debt transferred and recorded, never erased: the pre-flight also
refuses a logic lane whose named capture lane opens no window of its own, which
is the guarantee the §G ids already had and these did not.

---

## RIG-10 — `save_out` promotes whatever is in the slot, including the save the segment was handed

**Severity: BLOCKER for evidence quality.** Not fixed.

`S03-exit.json`, `S04-exit.json` and `S05-exit.json` are **byte-identical**,
md5 `62344f09b811`. Two segments in a row handed on the save they had been given
and reported it as a PASS.

Neither S04 nor S05 ever reached the Save tab, and both said so in their own
notes:

```
S04-64  FAIL game_menu did not open the pause shell:
        context narrative_modal -> narrative_modal (owner=DialoguePanel)
S04-66  input_context=narrative_modal (wanted menu_save)          FAIL
S05-65  input_context=menu_backpack (wanted menu_save)            FAIL
```

and then:

```
S04-69  slot 4 copied to saves/S04-exit.json (1415100 bytes)      PASS
S05-69  slot 4 copied to saves/S05-exit.json (1415100 bytes)      PASS
```

`_step_save_out` checks only that the slot **file exists**:

```gdscript
if not FileAccess.file_exists(src):
    return "FAIL slot %d has no file at %s -- did the Save tab actually write?" % [slot, src]
```

That check can never fire, because `seed_save` put the previous segment's file in
that slot at step 3 of the same segment. The question it was written to ask —
*did the Save tab actually write?* — is exactly the question it does not ask.

This is CD-1's `file: null` PASS wearing different clothes: an artefact that
exists, is named for this segment, and was produced by a different one. Its
consequence is structural rather than cosmetic — **S05 did not start from the
world S04 left; it started from the world S03 left**, and §B's whole save-handoff
design, which exists so that a blocker restarts at the last gate rather than the
chapter, is silently not in force.

The fix is a hash or mtime taken at `seed_save` and compared at `save_out`, with
a FAIL when the slot is unchanged. It is **not** taken during this run: with
RIG-4 still open (a `seed_save` whose source is missing does not stop the
segment), failing the handoff would leave every following segment running on the
title screen, which is worse evidence, not better. What is taken instead is
`HANDOFF_PROVENANCE.md`, which states for every segment which save it actually
entered from.

---

## RIG-11 — no journey segment ever calls its creature out, so no journey segment after S02 can fight

**Severity: BLOCKER.** Not fixed. **This is the largest single evidence loss in
the run.**

There is not one `combat_start` event in this run. Not a fight that went badly —
no fight at all, across five completed segments including an entire tournament:

| segment | events | `combat_start` |
|---|---|---|
| S01 | 22 | 0 |
| S02 | 118 | 0 |
| S03 | 397 | 0 |
| S04 | 151 | 0 |
| S05 | 131 | 0 |

The harness does emit that type, on an edge of `combat_running`
(`operator_harness.gd:4748`), so the absence is real rather than an instrument
blind spot.

The mechanism is fully measured in `DIAG-S02-ENCOUNTER/FINDING.md`:

1. `_engageable()` returns null when no creature is deployed, before distance.
2. A load restores the party and deploys **nothing** — measured on S02's own exit
   save through `save_game.gd::load_slot()`: party 1, `ally_body()` null, zero
   `AllyCreature` nodes in the tree. `_sync_active_creature()` declines to summon
   when nothing is out, and says so: *"Nothing out to swap; the new active
   creature comes out on next recall."*
3. Every journey segment from S03 on begins with a load.
4. **`creature_recall` appears zero times in S01–S10.** It appears in `X01`,
   `X02`, `X03`, `X03C` and `X06`.

The game is not hiding this. With a party and no deployed body it shows a
**non-actionable** line naming the button — `[RB]  Call out Moss` — and
`interact`, which is X, correctly does nothing. The harness pressed X.

So every combat, catch, party-size, gate-flag and objective assertion from S03
onward is a statement about the rig. S04's tournament could not have been won by
any input; S05's South Bridge fight could not have been fought. **`tournament_won`
and `south_bridge_open` being unset are not findings about the chapter.**

This is RIG-7's thesis in its most expensive instance: the primitive exists, is
correct, and is never called.

---

## What these eleven have in common

None of them is about Tetherbound. Four of them — RIG-1, RIG-2, RIG-5 and
RIG-11 — would have been read, in a Phase B that saw only the artefacts, as
evidence about the game: 26 objectives that never advanced, a chapter too
expensive to play, a village with a spot you cannot walk out of, and an opening
whose first fight never happens followed by a tournament nobody wins. All four
are the instrument.

RIG-3, RIG-4, RIG-8 and RIG-10 are quieter and the same shape: an instrument that
does not measure what it says it measures, an instrument that keeps recording
after it has stopped pointing at anything, an instrument that cannot see the two
values that decide the verb it presses most, and an instrument that certifies a
handoff it did not perform.

RIG-7 is the one to carry forward, because it is not really eleven findings. It
is one, and it is not "the rig is broken" — the rig is in good repair. Every
primitive named in that table works, is documented with the defect it was built
for, and is exercised by a passing self-check.

**They are simply never called.** Round 2 of the rig fixed the harness and did
not rewire the protocol, and eighteen step scripts still say what they said
before the fixes existed. From Phase B's side of the wall a fix nobody invokes is
indistinguishable from a fix nobody made — and S03's ledger, 64 failures of which
58 are one unclosed panel, is exactly what that looks like when it arrives as
evidence.

RIG-11 is the same sentence with a larger number attached. `creature_recall` is
not a primitive the rig lacks; it is one five study segments use correctly and no
journey segment uses at all. One press, in ten places, is the difference between
a run that can evidence the chapter's combat and a run that cannot.

The corollary is the thing to be careful about next time. Run 1 was judged by
what fraction of the backlog it recaptured. Round 2 answered by improving the
instrument. The measurement this run adds is that improving an instrument nobody
points differently changes nothing you can see in the artefacts: S03's signal
rate is 9%, against round 1's 8%, on a harness with six more safeguards in it.
