# D91 — the hour of day is saved state, and a New Game clears it

**Date:** 2026-09-05
**Lane:** N14-ROUTED-FOLLOWUPS-0905
**Supersedes nothing. Closes the routed half of** `docs/decisions/D87-the-dark-semantic-is-narrower-than-the-visible-night.md`
**(N13-NIGHT-RESUME) and of CL-O2.**

> **Decision-number note.** D87 was written four times over on 2026-09-05 —
> N04, N07, N09 and N13 each took it, because each brief said "D87 is next free"
> and none knew the others were running. Those four files are left exactly as
> their lanes wrote them; renumbering them is the landing lane's call, not this
> one's. This decision takes **D91**, the next number clear of all four.

## What was decided

The in-game clock is **saved state**, carried on the `Game` autoload as
`clock_elapsed_seconds` and written into the save format at VERSION 19.

A **negative** value is the "no carried clock" sentinel and means *open the world
at the authored morning*. It is what a New Game sets, and what a save written
before VERSION 19 migrates to.

## Why it needed deciding at all

N13-NIGHT-RESUME root-caused the owner's *"There is no night time"* and found the
clock had no memory of any kind: `world_look.gd::_ready()` ended in an
unconditional `apply_time("day")`, `save_game.gd` had no clock key, and
`game_state.gd::enter_realm()` rebuilt the scene from nothing. Night begins 350
real seconds into an unbroken run, so a Continue, a realm crossing or a load each
restarted that walk — and a player could play for hours without the world ever
reaching hour 22.

N13 could see the one-line half of the fix from inside its own file and
deliberately did not take it. Its reasoning is the thing this decision is
recording, because it is the whole design question:

> I considered doing the session half alone from `world_look.gd` with a `static
> var` (the same static-carry pattern this file already uses for the
> emission-floor setters). I did not, and the reason is specific: a static would
> also survive **New Game**, so a player who reached 23:00, quit to the title and
> started a fresh game would begin it at 23:00.

That is the decision. "The clock persists" and "a new game starts in the morning"
are both required, and a mechanism that cannot tell those two cases apart is not
a fix. So the value lives on `Game` — which outlives the scene rebuilds that were
losing it, and which has a `reset_for_new_game()` that can clear it — rather than
on the node that owns the live clock.

## What this does NOT decide

- **What hour a new game starts at.** Still 08:00, `art.json`'s `day` keyframe,
  unchanged. N14's brief is explicit that inventing a different opening hour
  would be exactly the kind of unrequested design call `CLAUDE.md` reserves for
  the owner.
- **What a rest does.** `reset_to_morning()` still snaps to 08:00 and is still
  called by `night_rest.gd` and `player_bed.gd`. That was already deliberate; it
  now also clears the carried value, so the next scene rebuild after a rest does
  not restore the evening the player just slept through.
- **How long a day is.** `day_length_seconds` 600 is untouched.

## Consequence worth knowing about

`apply_time(name)` pins `_elapsed_seconds` to the named preset's authored hour —
its own R5.1 comment says so, and every capture tool depends on it. That was
harmless while every world opened at 08:00 anyway, and became a real defect the
moment a world could open at 19:40:
`playground_world.gd::_reapply_look_after_ground_materials()`, whose own comment
describes its intent as *"a plain re-push of the SAME preset, not a new one"*,
was snapping a resumed evening back to `golden`'s 18:00 on every boot (measured:
exactly 18.00 where 19.67 was expected).

`world_look.gd::reapply_current_look()` now exists for that intent: it pushes the
current look off the live clock instead of writing to it. `apply_time()` itself is
unchanged, and the pinning contract capture tools rely on still holds.

Anything else that re-pushes the look after a scene builds should call
`reapply_current_look()`, not `apply_time(time_of_day())`.
