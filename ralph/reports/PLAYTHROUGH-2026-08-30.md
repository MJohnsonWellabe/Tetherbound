# Tetherbound — the Meadows, played end to end

**Lane:** `ralph/T5-PLAY`, from `origin/ralph/LAND-0830I`
**Date:** 2026-08-30
**Status:** IN PROGRESS — the run is executing. Nothing below the method
section is verified yet, and anything not yet measured says so.

This is the run record `ralph/ACTIVE_GAME_PLAN.md` §5 asks for, against the
chapter as a whole, and the evidence `ralph/MEADOWS_EXIT_CRITERION.md` §K names
for K1–K3. It ends with a plain answer to the question the project turns on.

---

## Method, and what it can and cannot show

The run drives the **real game through the real front door**: title screen,
Start New Game, synthetic controller input from there on. No teleporting, no
debug spawns, no scene booted past the title. That is the Gate F operator
harness's own prime directive and the reason it is the rig used here.

**What runs.** `tools/gate_f/run_chain.sh` (added by this lane) plays
S01 → S10e in order into one run directory. Each segment's exit save is the
next segment's entry save, restored through the production title-screen Load
path, so the chapter is one continuous save lineage from a wiped `user://` to
the post-victory walk-back. Six previous Gate F attempts ran segments one at a
time by hand; none finished the chapter. The chain script exists because a
chain nobody could run in one command was never going to be run.

**The clocks are not interchangeable, and this report keeps them apart:**

| clock | what it is | what it is good for |
|---|---|---|
| **play** | `Engine.get_physics_frames() / physics_ticks_per_second` | the game's own duration — the pacing number |
| **wall** | real seconds on this container | rig cost; *not* a player-time estimate |

Wall clock here is dominated by a software renderer and a cold world stand-up
(~90 s per segment boot, fourteen times). It says nothing about how long a
person would take.

**The honest limits of this evidence.** Stated up front so nothing below has to
be discounted later:

1. **Play time is a floor, not a forecast.** The harness walks straight lines
   to named anchors, never hesitates, never reads a menu twice, never gets
   lost, and takes the optional content the script names rather than the
   content a curious player would find. Its play clock is the *critical path
   executed perfectly*. A real first clear is longer — the question this report
   can answer is whether the critical path's shape and content could plausibly
   carry 3–4 hours, not whether a stopwatch says so.
2. **Logic lane, no display server.** The chapter's *mechanics, pacing,
   cadence, reliability and progression* are measured. Its *look* is not: this
   run takes no frames. `MEADOWS_EXIT_CRITERION.md` §B–§E and §J are out of
   scope here by construction and are not claimed either way.
3. **Dead travel is measured the harness's way** —
   `operator_harness.gd::_is_meaningful` — a run of movement ending on any of
   sixteen interaction types *or* on passing within 30 m of a point of
   interest. Passing a wild creature ends a dead walk whether or not the player
   stops, which is the right definition and a generous one.

---

## Timeline

_pending — filled from `CHAIN_LOG.tsv` and each segment's `route.csv`._

## Pacing against the 3–4 hour target

_pending._

## Dead travel

_pending._

## Team progression

_pending._

## Encounter cadence

_pending._

## Where a real person would stop

_pending._

## Defects, ranked by player impact

_pending._

## The fix, and the replay

_pending._

## Verdict — is this a 3–4 hour first chapter someone would want to finish?

_pending._
