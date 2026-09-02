# D56 — The river's crossing is open by HEIGHT, not by a hole, and that is now pinned

**Date:** 2026-08-17 · **Decided by:** `RIVER-GATE`, against
`docs/decisions/D46-the-river-divides-the-map-and-costs-one-spoke.md`,
`docs/specs/MEADOWS_PROGRESSION_SPEC.md` §3 Band 3, and `OW5-walk`'s measurements

## The decision

**No opening is punched in `river.gd`'s recovery chain.** The Old Mill
Crossing is already traversable, the chain is already correct, and the
relationship that makes both true — the deck standing above the volumes'
ceiling — is now asserted by `tests/test_river_crossings_stay_open.gd` instead
of holding by luck.

This overturns the premise `RIVER-GATE` was filed on, so the measurements come
first.

## What was believed, and what is actually true

`OW5-walk` walked the corridor with a real body and logged **712 recovery
teleports at the Old Mill Crossing**, with `get_slide_collision()` returning
zero colliders — nothing touching the body, because the thing stopping it was
an Area3D writing `global_position`. It concluded that `river.gd`'s chain spans
the crossing and that *"the river is a one-way wall: you cannot get south past
it here, ever, in either lock state."*

The first half is true. The second is not.

**The chain does span the crossing in plan.** The middle 11.0 m of the 18.4 m
span sits inside two recovery volumes, seen from above.

**The crossing works anyway, and it works because of a height.** A volume's
ceiling is `lip_y − LIP_CLEARANCE`; at the narrows that puts it at y −7.01,
and the deck surface is at −1.91. Measured in the real baked world
(`tools/_probe_river_gate.gd --mode=survey`), the deck stands **5.10 m** above
the highest volume beneath it, so a body walking the span never enters one.

**Walked, in the real scene, both crossings and both lock states**
(`--mode=walk`, `smoke_traversal.gd`'s own start-back and frame counts):

| | locked | unlocked | world teleports |
|---|---|---|---|
| South Bridge | −9.1 m | +22.9 m | 0 |
| Old Mill Crossing | −8.0 m | +23.7 m | 0 |

Locked, the body is stopped short of the gap with the crossing in front of it.
Unlocked, it walks across and stays across. South Bridge reproduces `OW5C`'s
own −9.1 / +23.3 measurement. Nothing is teleported at either crossing in
either state. **The gate is the only thing gating this crossing, which is what
Band 3 and D46 ask for.**

## So what were the 712 teleports?

**The authored spine does not use the bridge.** `trail.bands[]`'s Band 3
crosses the river as a straight leg from (−150, 4170) to (−150, 4235), and the
deck's centreline is at x = −152: `OW5C`'s WALL1 seam workaround shifted the
crossing and the river's narrows −2 m in x and left the spine where it was.
Measured directly — **11 m of authored Band 3 trail, from (−150, 4198) to
(−150, 4208), lies inside a river recovery volume.**

So a body following the spine walks into the channel two metres east of the
bridge and is correctly put back on the bank it came from. That is the failsafe
doing exactly its job about a route that does not go over the crossing. The
fix is two waypoints in `trail.bands[]`, which this work deliberately did not
touch — it is `SPINE-LAYOUT`'s, and the spine's shape is settled.

## Why no opening was punched

An opening was built, measured, and thrown away. It subtracted each crossing's
deck footprint from the chain, derived from the crossing's own `crossings[]`
entry and its bridge prefab's own collider list. It worked: 3.04 m of course
opened at the deck, everything else covered, the South Bridge untouched.

It was rejected on the measurements:

- **It changed nothing a player can experience.** The walk is identical with
  and without it — −8.0 m locked, +23.7 m unlocked, 0 teleports either way.
- **It cost real coverage.** Inside the 3.04 m opening, a body standing on the
  channel floor *under the bridge* is in no recovery volume; before, it was.
  It self-recovers by stepping 1.5 m along the course, so it is a small loss
  — but it is a loss, bought with nothing.
- **It answered a question nobody had.** The plan-view overlap is inert. What
  is worth defending is the 5.1 m of clearance, and a test defends it without
  moving any geometry.

## What is defended instead

`tests/test_river_crossings_stay_open.gd`, five assertions over the volumes
`river.gd` actually builds:

- the chain covers the whole 2,300 m course with no gap a body could land in
  (D46's division, which no test asserted at all);
- the whole deck run stands clear of every volume it passes over, with the
  measured margin printed;
- the channel *under* that deck is still covered, so the crossing is a bridge
  over a wall rather than a hole in one;
- the river never reaches the South Bridge's own gully, 2,870 m away.

Verified failable, twice, in the two directions that matter: raising the
volumes' ceiling above the deck fails the clearance assertion by the exact
margin it should (6.06 m above), and dropping one course segment from the chain
fails the coverage assertions with the point coordinates that would have been a
free crossing. It is the deck-versus-ceiling *relationship* that is asserted,
never either height, because those two come from different places — the deck
from the crossing's `flats` abutment pads, the ceiling from the river's own
`depth` and `rim` at that reach — and each has been re-tuned independently
before.

That is the shape of failure this repo keeps paying for: `tether_relay`'s
`deck_y` was calibrated against a site that had since moved, and
`smoke_boss.gd`'s `BARRIER_LIMIT_M` was 18 m by config arithmetic and 28.3 m
when somebody finally measured it. Here the symptom of the margin closing would
be a body teleporting off a bridge with nothing touching it — which took a
purpose-built teleport counter to see the first time.

## The honest remainder

**One other place the chain swallows something it should not, and it is not the
river's.** `severed_spokes.gd` hangs the same volume off the storm road's
collapsed-bridge carve, a 146 m × 16 m box at (−34.1, 7535.6) recovering to
(−34.0, 7513.5). **16 m of Band 5's authored spine, from (7, 7530) to
(4, 7545), lies inside it.** That recovery coordinate is character-for-character
`OW5-walk`'s finding 4 — *"stronghold gate approach, (−34.0, 7513.5) … ending
BLOCKED with `on_floor=false` and zero colliders … the last 57 m to the
stronghold gate is not walkable."* Same signature as the crossing: no collider,
because nothing is touching the body. It is filed as terrain and it is very
likely not terrain. Left alone here — the spine running through a deliberately
severed spoke is a routing question, not a failsafe one.
