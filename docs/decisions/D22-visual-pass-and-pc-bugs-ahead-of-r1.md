# D22 — Two PC bugs and the visual pass jump the queue, ahead of R1–R8

**Date:** 2026-08-10 · **Decided by:** the owner, explicitly, after playing
the published build on PC.

## The decision

Owner: *"the game on pc doesn't allow you to look around with the mouse...
The character when running or walking doesn't have an animation. Do the
fixes from the visual pass until the visual pass work is done, then go onto
R1-R8."*

`docs/CURRENT_STATE.md` gained two new phases ahead of Phase 1:

- **Phase -1** — the two owner-reported PC bugs (mouse look, no locomotion
  animation), each with an investigation head start so the first firing
  isn't starting cold.
- **Phase -0.5** — every scene-fixable finding from the two 2026-08-09
  blind reviews (site-frames critique and the full R0.8.5 pass), gathered
  into one sequence: the two broken review-harness tools first (fixing them
  is a prerequisite for verifying everything after), then day/night
  (R5.1), wayfinding and landmarks (R7.1), village/interior dressing
  (R7.2), closing with a re-run of the visual-judge cohesion pass (R9.4) as
  the checkpoint for "the visual pass work is done."

R5.1, R7.1, R7.2 and R9.4 were **relocated**, not duplicated — their
original slots in Phase 5/7/9 carry a pointer note instead of the item
content, so there is exactly one live copy of each and `DONE.md` can cite
whichever ID without ambiguity.

## What deliberately did NOT move

The creature/human art-pipeline style mismatch (Paddlenewt/Pipwing/Ripplet
and the Warden reading as different games from the rest of the roster) is
the largest single finding across both reviews, and it stays parked in
`BLOCKED.md` as a design question. Rework vs. replace is an art-direction
call `CLAUDE.md` forbids inventing — D21 turned off the play-gate stops,
it did not turn off that rule.

## Why this ordering and not, say, folding it into Phase 0

Phase 0 already reads as "shipped and closed" (its own text says so). A
third phase inserted before Phase 1, ahead of the numbered work, keeps the
history readable: Phase 0 is the overhaul's record, Phase -1/-0.5 are this
session's, and neither has to be reopened or renumbered to make room for
the other.
