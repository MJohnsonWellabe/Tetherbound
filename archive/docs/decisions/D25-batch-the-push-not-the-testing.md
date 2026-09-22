# D25 — Batch the push, not the testing

**Date:** 2026-08-11 · **Decided by:** the owner asked the question; the
measurements answered it.

## The question

The owner's words: *"I want to make Ralph more efficient. things seem to take
too long. at the very least have it kick off when the prior one finishes. at the
most just don't test or ship until an entire phase is done. what is the right
direction for faster implementation of everything that will be in our backlog"*

Two proposals, a floor and a ceiling. The floor is adopted. The ceiling is not,
and this document exists so nobody re-proposes it in six weeks without seeing
the arithmetic.

## What was actually measured

Before deciding, the loop's real costs were measured rather than assumed. Two of
the numbers everyone was reasoning from turned out to be wrong.

| Cost | Believed | Measured |
|---|---|---|
| A branch CI run | 8–9 min (`conventions.md`, `ci.yml:52`) | **5.2 min**, no queue |
| Idle between firings | — | **~25%** of a cycle |
| A dead firing | — | **~2 h** of stand-down, twice in one 5-hour window |
| A three-round visual pass | one push | **8 pushes, ~36 min of CI** |
| Cold start | — | ~9.5 min, mostly re-reading `BACKLOG.md` + `DONE.md` |

The loop had been optimising against a CI number 80% too high. That single
correction changes which lever is worth pulling: **CI is not where the time
goes.**

## The decision

**Adopted — batch the push.** Ship 1–4 finished items per branch instead of one.
Four items on one branch costs ~5 minutes of CI instead of ~20. Two limits:
never batch across `area:` boundaries, and never hold finished items hostage to
a broken one — push the green ones and leave the rest in the backlog.

**Adopted — chain, do not wait for the hour.** A firing that finishes at :12 and
idles to :49 wastes 37 minutes. Successors are scheduled 2–3 minutes out, and
the cron reverts to being what it always should have been: a heartbeat that
guarantees the loop survives a session dying, not the pacing mechanism.

**Rejected — batch the testing.** Test every item as it is finished, locally and
headless.

**Adopted, and larger than either proposal — iterate the visual critic locally.**
The blind pass is unchanged and still required; it simply runs in the firing's
own checkout, pushing once at the end. This is a 5–7× reduction in CI for
visual-affecting work, and **nearly every item in Phases -0.9 through -0.55 is
visual-affecting.** It costs nothing to adopt.

**Adopted — parallel lanes** (the owner's choice between the options offered).
Per-`area:` leases in `archive/ralph/STATUS.md`, one block per live firing, so disjoint
work runs concurrently. Honestly 2–3 lanes, not 5: `terrain` is one lane however
many items sit in it, because they share `terrain_playground.json` and a rebake.

**Adopted — a 40-minute lease expiry**, down from 90, made safe by checking the
task branch for recent commits rather than trusting the clock.

## Why phase-level batching was rejected

Not on principle. On three specific costs, any one of which outweighs what it
saves.

**It saves almost nothing.** Batching the *push* already captures the CI saving.
Withholding the *tests* on top of that saves zero minutes of CI, because the
tests run locally in seconds to a minute. It only saves the effort of running
them — which is not a cost worth optimising.

**A phase-sized red run is nearly uninformative.** CI reports that something in
ten changes broke; it does not say which. The work to find out is a bisect
across a phase's worth of commits, and it lands on the *next* firing, which has
no memory of writing any of them. Compare a per-item red: the failing item is
named, and its author is still in context.

**Every un-shipped item is an item the owner cannot play.** This is the real
argument. The loop's purpose is a game the owner voluntarily wants to keep
playing, and its worst failure to date was twelve hours and twenty-five commits
publishing nothing while the download link looked current. Phase-level shipping
makes the gap between "built" and "playable" the length of a phase by design.
The two P0 bugs that prompted this whole conversation were found by the owner
playing a build; a longer shipping cadence finds them later.

**The trade in one line:** batching the push trades ~15 minutes of CI for
nothing. Batching the testing trades ~0 minutes of CI for hours of bisecting and
a slower feedback loop with the only person whose opinion decides whether this
game is good.

## What this does NOT change

- The blind visual pass itself, and the rule that a firing's own read of a frame
  does not count. Only *where* the rounds run changed.

  ~~its three-round cap~~ — **superseded the same day.** The owner asked
  whether the critics were unbounded "so they will work until the game looks
  right", and the cap was replaced with a convergence test: keep iterating while
  the critic names a *new* defect or `frame_stats` shows measured movement, stop
  after two consecutive rounds with neither. The count was the wrong instrument
  — it cut off tasks that were still converging and spent rounds on tasks that
  were not. `conventions.md` has the rule.

  Worth pairing with D24 rather than reading alone: uncapped iteration does not
  make a scene look right by itself. R9.4 already ran uncapped and hit a wall
  that was missing assets, not insufficient effort.
- Never pushing to `main` directly; `ralph/**` → CI → fast-forward stays.
- Running only the tests a backlog item names.
- The honesty rules. A batched branch does not get to describe four items as
  done when three are.

## Where it is wired

`docs/AGENT_WORKFLOW.md` (leases per area, the batching rules, local critic iteration,
chained successors, the bookkeeping-rebase rule), `archive/ralph/STATUS.md` (multi-block
format, 40-minute expiry), `docs/AGENT_WORKFLOW.md` (the corrected 5.2-minute CI
figure, local iteration), `docs/CURRENT_STATE.md` (`area:` on every new item).
