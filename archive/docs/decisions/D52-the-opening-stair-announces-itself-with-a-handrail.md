# D52 — The opening stair announces itself with a handrail

**Date:** 2026-08-16
**Items:** `PT-03` (make the opening staircase readable)
**Status:** built, and cheap to overrule

---

## 0. Who decided this, and why it is written down

`docs/CURRENT_STATE.md`'s PT-03 says **the owner picks the affordance** among three:
a warm light at the stair head, geometry that frames rather than avoids the
opening, or a look-toward bias on the interior camera profile. He was not
available per-decision and asked the loop to keep moving, so the coding session
picked one. This file exists so that picking one costs him a paragraph to
reverse rather than a re-investigation.

PT-03 is tagged `model: fable`. It ran at **opus**, because the owner has no
Fable usage left. Recorded plainly rather than left to look like it ran at its
tagged tier.

## 1. The defect is occlusion, not darkness

Two testers — one of them the owner, twice — could not leave the first room of
the game. `archive/reports/docs-reviews-full/2026-08-15-full-blind-playtest/PLAYER_LOG.md` beats
16–20 record what that actually looked like: a 4×90° panorama from the get-up
spot that found no stairs, then a jump over the mezzanine rail, then a player
balanced on the rail cap.

The report's own root-cause note listed three contributing absences — no light
at the stair head, no distinguishing geometry, no marker. Measuring the room
says the ordering matters, and that the first of those could never have worked
alone:

- the loft floor is a slab from the west wall to `x = -0.1`, and the player
  stands on top of it;
- every tread of the flight sits **below** that slab's east edge — the top
  tread's top is `FLOOR_H` (3.2), the loft floor's walking surface is 3.45;
- so the sightline from a standing eye on the loft, grazing that edge, passes
  **above** the treads for the entire 3.4 m run. At `x = 1.0` the sightline is
  at 2.92 and the tread is at 2.24; at `x = 3.3` the sightline is at 1.80 and
  the tread is at 0.32.

The stairs are not dim. They are **not in the frame at all**. What is in the
frame is a floor edge with a shallow ledge under it, which is what a parapet
looks like, which is what two testers reported seeing.

That kills "a warm light at the stair head" as a solution on its own: lighting
something the loft floor is standing in front of changes nothing an eye on the
loft can see.

### Why the tester's own panorama could not have saved them

Beat 17 of the log is a deliberate 4×90° panorama from the get-up spot, run by
a tester who had correctly decided to map the room's exits. It found nothing,
and the room's numbers say it was never going to.

The stair head sits at bearing **−51°** from the get-up spot — east-north-east,
almost exactly between two of the four cardinal turns a panorama takes. The
interior camera profile runs a **65° FOV**, a 32.5° half-angle. So the pure-east
turn only just catches the stair head at the very edge of frame and the pure-north
turn just misses it, and that is *before* the spring arm collapses against the
west wall on the eastward turn, which is what the log records as half the
panorama coming back as the inside of the player's hair.

This is worth writing down because the obvious later reading of PT-03 — "the
testers did not look properly" — is wrong, and someone will reach for it. They
looked in the four directions the room invites you to look in, and the answer
was in none of them.

## 2. What was chosen

**Geometry that frames the opening**, because a handrail is the one part of a
staircase that rises *above* the occluding edge.

`grandpa_house.gd::_build_stair_rail()` adds, in the room's existing timber
colour and its existing primitive vocabulary:

- a handrail raked to the flight's own pitch line (through the tread nosings,
  `RAIL_ABOVE_NOSING` = 0.85 m above them);
- a **head newel** on the loft, where the existing loft rail stops, tall enough
  to meet the raked rail's cap;
- a **foot newel** on the ground slab, so the flight also reads from below;
- five balusters, each running from just under the rail down through the pitch
  line and into the step solid, so the rail reads as a stair rail rather than a
  plank floating at 43°.

The same arithmetic that condemned the treads clears the rail: it stands above
the loft-edge sightline from the loft edge out to `x ≈ 1.9`, over half the run.
The result is a long descending diagonal, and **nothing else in this room is
diagonal**. A parapet cannot be mistaken for one.

The head newel is the other half of the read. Before it, the loft rail simply
stopped; the loft beam already "deliberately stops short of the opening", so
the geometry at the one place a player has to walk to was an absence. Now the
rail arrives at a post and continues downward. That is a landing.

## 3. The light stays, as support, not as the answer

`_build_lights()` gains a third omni at the stair head — the one the report
correctly noted was missing. Its job here is narrower than the report implied:
it lights **the rail**, which is above the occluding edge, and puts a warm pool
on the loft floor at the corner the player has to walk to. Shadows stay on, as
on the other two; unshadowed it would spill through the north wall onto the
village square.

Both halves are in one change on purpose. Geometry nobody can see is not an
affordance, and light falling on geometry nobody can see is not one either.

## 4. What was explicitly not chosen

**The camera look-toward bias.** It was rejected on three grounds:

1. It only fires while the interior profile is active and while the player has
   not taken the stick, which is precisely the window a confused player leaves
   immediately. It teaches nothing that survives the first input.
2. Moving a third-person camera the player did not move is the failure mode the
   same playtest already reported as its **dominant** impression — beats 4, 5,
   11, 17: head-clips, corner blocks, a panorama that produced two distinct
   views out of four. Adding another authority over that camera in that room is
   the wrong place to spend goodwill.
3. It solves nothing for the player who is already looking the right way and
   still sees a parapet, which is the actual reported failure.

**A torch or lantern prop at the stair head.** `scripts/world/torch_prop.gd`
exists and would be the in-family way to make the new light diegetic. It was
left out: a burning brand a metre from the bed the player just left is a new
art and story claim, and PT-03 is not the item that gets to make one. If the
owner wants the light sourced, that prop is where it comes from.

**Anything from a new asset family.** No pack, no Meshy generation, no
reference board (`CLAUDE.md`, D24). Every piece added here is a `BoxMesh` in
`COL_TIMBER`, the same material the loft beam and loft rail already use.

## 5. Nothing added here is solid

Rail, newels and balusters are all visual-only. Two reasons, in order:

1. The interior camera's spring arm collapsing against this room's geometry was
   the loudest single finding in the blind playtest. A handrail is the worst
   possible place to add fresh collision — head height, arm's length, beside a
   player walking a 1.2 m flight.
2. It is not needed. The rail sits 0.11 m inside the flight's south face and
   the walked lane (`stairs_top` → `stairs_bottom`, which `tests/smoke_opening.gd`
   drives) runs down the middle of the flight.

The consequence is that a player hugging the south edge can clip the rail. That
is the same trade the room's rugs and surface clutter already take
(`_clutter()`'s own default), and it is strictly better than making a known
camera problem worse.

## 6. What the regression test can and cannot say

`tests/smoke_opening.gd::_the_way_down_is_marked()` asserts two things, both of
which go red if this change is reverted:

- some mesh **contained within the stair footprint** rises at least 0.4 m above
  the loft floor plane (before PT-03 the tallest was the top tread, below it);
- an `OmniLight3D` stands above `FLOOR_H` inside that same footprint (before
  PT-03 the nearest light was the ground-floor omni, a storey down).

Containment rather than overlap is deliberate: the walls, the loft slab and the
roof all cross that z band and would each satisfy a looser test while telling
the player nothing.

It does **not** assert that a stranger finds the stairs. No headless test can,
and PT-03's done-condition — "a player who has never seen the room finds the
stairs without being told" — is answered by a person, not by this file.
