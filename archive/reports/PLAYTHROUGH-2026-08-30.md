# Tetherbound — the Meadows, played end to end

**Lane:** `ralph/T5-PLAY`, from `origin/ralph/LAND-0830I`
**Date:** 2026-08-30
**Status:** **PARTIAL — the run is still executing.** Band 0 is played and
measured. S03 is in flight. S04–S10e have not run.

**This file is written to be safe to read at any moment**, including if this
lane is stopped mid-run. Everything below is either measured or explicitly
labelled as not yet measured. There is no projection anywhere in it.

The headline question — *is this a 3–4 hour first chapter someone would want to
finish?* — **cannot be answered yet, and is not answered below.** Saying
otherwise on band 0 of five would be exactly the kind of evidence
`MEADOWS_EXIT_CRITERION.md`'s evidence rule was written to stop.

---

## What actually ran

| segment | span | verdicts | state |
|---|---|---|---|
| **S01** | boot → title → New Game | 12 P / 1 F | **complete** |
| **S02** | wake → starter → first fight → first catch → road gate | 76 P / 6 F | **complete** |
| **S03** | village ladder: tools, team, training, gathering, home, beds, sleep, feed | — | **in flight** |
| S04–S10e | tournament, five bands, Warden, legendary, release, world healing | — | **not run** |

Three S02 attempts appear in `CHAIN_LOG.tsv`. The first two were stopped by this
lane and are kept as `S02-superseded-1/-2`; the third is the evidence. Why they
were stopped is `RIG-T5-3` and `RIG-T5-4` below.

---

## Method, and what this evidence can and cannot show

The run drives the **real game through the real front door**: title screen,
Start New Game, synthetic controller input from there on. No teleporting, no
debug spawns, no scene booted past the title.

`tools/gate_f/run_chain.sh` (added by this lane) plays S01 → S10e into one run
directory, each segment's exit save seeding the next through the production
title-screen Load path — so the chapter is one continuous save lineage from a
wiped `user://`. Six previous Gate F attempts ran segments one at a time by
hand; none finished the chapter.

**The clocks are kept apart, and the difference matters:**

| clock | what it is |
|---|---|
| **play** | `Engine.get_physics_frames() / physics_ticks_per_second` — the game's own duration |
| **wall** | real seconds on this container: rig cost, **not** a player-time estimate |

**Limits, stated up front so nothing below has to be discounted later:**

1. **Play time is a floor, not a forecast.** The harness walks straight lines to
   named anchors, never hesitates, never re-reads a menu, never gets lost, and
   takes the optional content its script names rather than what a curious player
   would find. Its clock is *the critical path executed perfectly*.
2. **Logic lane, no display server.** Mechanics, pacing, cadence, reliability and
   progression are measured. **Look is not** — this run takes no frames, so
   §B–§E and §J of the exit criterion are out of scope here and are not claimed
   either way.
3. **Dead travel is the harness's definition** (`_is_meaningful`): a run of
   movement ending on any of sixteen interaction types *or* on passing within
   30 m of a point of interest. Passing a wild creature ends a dead walk whether
   or not the player stops — the right definition, and a generous one. This
   report additionally discards any stretch the player did not actually walk
   ≥5 m through, because otherwise the metric is dominated by the ~180 s world
   stand-up at each segment boot, which is instrument cost, not a dead walk.

---

## Measured so far

| seg | play_s | wall_s | walked | longest dead stretch | P | F |
|---|---|---|---|---|---|---|
| S01 | 181 | 716 | — | — | 12 | 1 |
| S02 | 307 | 815 | 136 m | **17 s / 38 m** | 76 | 6 |
| S03 | *in flight* | | *1404 m so far* | *402 s / 124 m — see below* | | |

**Front door.** Process start → title interactive: **476 ms**. The title focuses
a control, and Start New Game goes straight into the world with no overwrite
prompt on a fresh install. §K3 asks for no core-verb reliability failure; the
front door is not one.

**World stand-up.** New Game → playable costs roughly **90–180 s** of terrain
build and prop scatter. This is real, player-facing, and happens on the first
thing a new player ever does. It is not a defect this lane can rank without the
rest of the chapter for context, but it is recorded.

**Band 0 pacing.** The opening (S02) runs **307 play-seconds** — about five
minutes — against `MEADOWS_PROGRESSION_SPEC.md`'s **20–40 minutes** for BAND 0
HOMEBOUND. That gap is expected and is not by itself a finding: the harness takes
the critical path only. What it does establish is that the *required beats* of
band 0 occupy about five minutes of unavoidable play, and the other 15–35 comes
from the player choosing to do more.

**Encounter cadence, band 0.** Over S02's five minutes: 8 dialogues, 5 objective
changes, 4 catch events, 1 fight, 3 landmark discoveries, 2 gathers. S03 so far
adds 18 dialogues, 11 gathers, 3 fights, 1 catch, 1 build. **The opening is
dense.** Nothing in band 0 goes flat.

**Dead travel, band 0: 17 seconds / 38 metres.** That is the longest stretch in
the entire opening with no interaction and no point of interest within 30 m.
There is effectively no dead travel in the opening. A7 is satisfied for band 0
and nowhere else yet.

**S03's 402 s / 124 m stretch is unexplained and is not yet a finding.** The
segment is still running; the number is read from a partial `route.csv` and may
be an artefact of where the run currently is. It is flagged here so it is not
lost, not because it has been established.

---

## Team progression so far

| after | party | roster |
|---|---|---|
| S02 | **2/5** | Moss (ripplet) L3, 37/118 · Bramblebun L5, 85/124 |

The caught creature is **two levels above the starter** and has more HP. That is
a genuinely interesting shape for a first catch — the thing that nearly beat you
becomes the strongest thing you own — and it is the only roster data this run
has. A2 and A8 need the full chapter and cannot be spoken to.

---

## Reliability

**No freeze, no input loss, no save/load failure across S01–S02.** Every
save handoff through the production title-screen Load path worked.

Two live instances of the **modal-holds-locomotion** class the brief names were
caught in S03's partial run, by the diagnostic asserts `4de89a11` added for
exactly this purpose:

```
the world owns input before this walk -> FAIL: input_context=narrative_modal
the world owns input before this walk -> FAIL: input_context=combat_aim
```

They did their job: they name the cause at its origin instead of letting it
surface many steps later as a walk that "did not reach". Neither stranded the
run.

One open question, not yet chased: **S02-40** expected `combat_aim` to own input
while aiming a catch orb and measured `combat` instead. Whether that is
player-visible is unestablished.

---

## Defects

Full detail, with evidence, in **`ralph/reports/T5-PLAY-DEFECTS.md`**. Ranked by
player impact:

| id | what | severity | state |
|---|---|---|---|
| **RIG-T5-3 / RIG-T5-4** | The chapter's first gate never opened. Two lanes that both landed in `LAND-0830I` disagreed about where the gate key and the gate are. A closed `road_gate` is a `StaticBody3D` with sealed wings, so the chapter **could not leave band 0**. | BLOCKER (rig) | **fixed** |
| **COST-T5-5** | The Gate F cost gate extrapolates one 120-frame window across a whole segment. It refused S03 at step 136/406 predicting 5.7 h against a sustained rate its own `route.csv` puts at 29 minutes — wrong by ~12×. Plausible contributor to six unfinished attempts. | BLOCKER (rig) | **fixed (CD-7d)** |
| **RIG-T5-1** | The global freeze record claims X11 with no `lanes` block, so every fresh headless run is refused one second in, before step 1. | BLOCKER (rig) | worked around; **routed to GATE-F-RUN7** |
| **GAME-T5-6** | The first hour leans on a Revive draught the opening grants two of, against a starter-faint RUN6 measured at 4-in-5. | SHIP candidate | **observed, not root-caused** |
| **RIG-T5-2** | S01/S02 expect an objective rung the opening no longer starts on. The game is *clearer* than the script expects. | RIG | recorded |

**Two of my own claims were wrong today and are corrected in place**, because a
report that quietly drops its errors is not evidence:

- I proposed the harness's per-frame POI scan as the cause of a cost regression.
  **Measured 1,045 POIs at run 5 against 1,090 here — plus four percent.**
  Cannot produce 4×. Hypothesis dead.
- I reported a **4× village performance regression**. There is none. Those
  figures were single 120-frame windows containing one-off costs; I compared two
  artefacts. `route.csv` carries both clocks and puts the sustained rate at
  **wall/play ratio 1.0, 0.0167 s/frame, flat**. The game runs at real time.

---

## Not measured, and therefore not claimed

Everything the chapter is actually about:

- the village tournament;
- bands 1–5 and whether they feel like distinct places (A5);
- trainer escalation and whether the ladder holds;
- the five-creature roster pressure (A2), and whether the end team feels earned
  and different from the start team (A8);
- the Warden as a climax (A9);
- the legendary and the release ceremony (A10);
- post-Warden world healing (A11);
- **total chapter duration against the 3–4 hour target** (K1);
- **where a real person would stop playing**;
- dead travel anywhere past band 0 (A7).

---

## Verdict

**Withheld.** Band 0 is dense, reliable, clearly directed and free of dead
travel, and the opening's shape — nearly lose the first fight, then catch the
thing that nearly beat you — is good. That is a real and encouraging result, and
it is one fifth of the question.

The chapter now *can* be played end to end; before this lane it could not leave
the village. Whether it *should* be played end to end is not yet knowable from
what has run.
