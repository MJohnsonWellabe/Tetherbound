# D75 — Test-relocation lesson: driving into a low roof reads exactly like a physics bug

**Date:** 2026-09-05
**Items:** `OP-0904-3` / `CL-O3`, lane `W14-RIDING`
**Not a design decision.** A process finding, recorded because it cost real
time and will cost more if the next person re-derives it from scratch.
**Status:** resolved

---

## The finding

`tests/smoke_riding.gd`'s mounted-jump check measured a hop that consistently
rose 0.89 m against a configured 1.60 m — a hard, deterministic clamp,
identical to three decimal places across every retry, independent of which of
three different world coordinates the mount was relocated to before jumping.
That repeatability looked exactly like a code defect: `creature_body.
request_jump()`/`_physics_process()`'s vertical launch and gravity integration
proved correct in complete isolation (a bare `CharacterBody3D` over a flat
`StaticBody3D` floor reached 1.677 m against the same 1.6 m ask, clean parabola,
every time) — so the discrepancy had to be something about the full world.

It was not a code defect. `CharacterBody3D.get_slide_collision()`, read on
every frame of the rise, found a `(0, -1, 0)` contact normal — a ceiling — on
the exact frame the rise stopped, bracketed by a steady sideways wall-normal
contact on every frame before and after. The test's own relocation helper was
driving the mount `move_back` from world origin into `data/config/
village.json`'s `workshop` prefab's own **south-west-facing open arch bay** (a
real, low, roofed porch, named in that file's own layout comment) — a spot a
creature can walk *into* at full, unobstructed speed, which is exactly why the
horizontal peak-speed measurement that ran right before the jump check read as
completely clean (10 m/s peak, matching the configured ride speed exactly).
Distance never mattered: 90 frames of `move_back` and 130 both produced the
identical clamp, because once wedged under the eave, holding the stick longer
does not move the body any further into it.

`move_left` off the same spawn point clears with zero slide collisions for the
whole rise and reaches 1.68 m. It works for the reason the fix has to be
empirical rather than reasoned about from `village.json`'s numbers: nothing in
that file describes the vertical extent of a roof overhang, only wall
footprints, so a coordinate "measured clear of every structure" can still sit
under one's eave.

## Why this gets a decision file instead of just a commit message

Two dead ends preceded the real fix, and both are the kind of trap that costs
a fresh investigator the same hours:

1. **A coordinate read off structure positions is not proof of open ground.**
   `village.json`'s `at: [x, z]` entries are footprints. `square_oak_a` at
   `[31.5, 1.5]`, 28.9 m from a test coordinate, sounds like clearance; it says
   nothing about whether that coordinate sits under a roof, in a fenced
   corridor, or past the map's own collision-streaming edge (two of three
   coordinates tried here failed for exactly that last reason — Terrain3D's
   dynamic collision follows the tracked body rather than existing everywhere
   the heightmap covers, and `place_on_ground()` silently no-ops, returning
   `false`, wherever it has not streamed in; both failures went unnoticed
   because the test never checked that return value).
2. **A direction proven clear for ONE purpose is not proven clear for
   another.** `move_back` is the exact heading `_the_stick_moves_the_creature`
   already presses and already measures as clean horizontal travel. It is
   NOT clean overhead. A creature can walk under a low roof at full speed
   forever; only something that asks about the vertical axis — a raycast, a
   shapecast, or (what actually found it) reading the collision normal a real
   jump produces — can tell the difference.

The general lesson, for any future test that has to relocate a body to "open
ground" it cannot simply spawn on: **the claim needs the same class of evidence
the thing under test needs.** A horizontal speed check proves horizontal
clearance. Proving vertical clearance for a jump needs a vertical probe, not a
faster horizontal one.

## What changed

- `tests/smoke_riding.gd::_onto_open_ground()` drives `move_left` instead of
  `move_back`.
- The jump check now reads `get_slide_collision()` on every frame of the rise
  and fails by name if any contact's normal is a ceiling (`normal.y < -0.5`)
  while still rising — so a future relocation that drives back into an
  overhang fails with the collider's name, not a bare height number nobody
  can act on without repeating this whole investigation.
- `tools/_capture_riding.gd` drives the same corrected heading, so the
  render evidence and the smoke test relocate to the same real spot.

No production code changed as a result of this investigation. `creature_body.
gd`'s jump implementation was correct throughout; nothing here revises D74.
