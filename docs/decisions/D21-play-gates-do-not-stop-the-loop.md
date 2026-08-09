# D21 — Play gates no longer stop the Ralph loop

**Date:** 2026-08-09 · **Decided by:** the owner, explicitly.

## The decision

The owner, restarting Ralph after the D18–D20 overhaul shipped: *"restart
Ralph and don't have it stop for a play test. just keep running through the
backlog with no intervention."*

`▶` items in `ralph/BACKLOG.md` change meaning from **gate** (the loop parks
until the owner plays) to **checkpoint** (the loop lists the pending playtest
in `BLOCKED.md`'s play-gate section for the owner and keeps building past
it). The owner plays in parallel, on their own schedule, and their feedback
arrives as new backlog items — exactly as the R0.10 playtest did, whose
feedback became the entire D18–D20 overhaul.

For `▶`-marked *work items* (R9.1–R9.4, the on-Ally feel passes), the loop
does everything automatable inside them and records what genuinely needs
hands on the device, rather than parking.

## The one exception

**R9.5, the Meadows exit gate, still stops the loop.** `GAME_DESIGN.md`
§33's twelve criteria are subjective and only the owner can call them, and
`CLAUDE.md`'s hard rule — no Biome 2 work until Meadows passes its exit
gate — sits above this decision. When nothing remains but R9.5, the loop is
done, not blocked.

## What this trades away

The gate mechanism existed so subjective feel questions got answered before
systems were built on top of unvalidated ones (D07's reasoning). The owner
is deliberately trading that safety for throughput: work built on something
a later playtest rejects may need rework. That risk is accepted, named, and
the owner's to accept — the backlog order still puts the riskiest
subjective systems (combat feel, building) ahead of the systems that stack
on them, which bounds the rework.

## Where it is wired

- `ralph/PROMPT.md` — loop step 1, the blocked-reasons list, and successor
  scheduling.
- `ralph/BACKLOG.md` — the legend.
- `ralph/BLOCKED.md` — the play-gate section becomes the owner's playtest
  queue.
- `ralph/MANUAL.md` — manual task 5.
- The Routine's firing prompt (edited outside the repo, on the Routine
  itself).
