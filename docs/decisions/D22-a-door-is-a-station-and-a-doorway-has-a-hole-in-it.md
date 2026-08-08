# D22 — A door is a station, and a doorway has a hole in it

**Status:** accepted
**Milestone:** M8 follow-up, from play
**Reported by:** the owner, directly — *"On the pre built houses, there's no way
to open doors and you have the doors placed in entirely the wrong place. It needs
like a half offset."*

Two sentences, three defects. All three were live, and the whole suite was green.

## 1. The half offset was 0.511 metres, and it is a third origin

D12 established that the Quaternius kit uses **two** origins and that mixing them
puts every wall half a cell out: a floor's origin is the centre of its cell, a
wall's is the bottom-centre of a 2m **edge**. `pieces.json` carries an `anchor`
for exactly that reason.

There is a **third**. A door leaf is hinged on its own edge:

| model | x extent | centre |
|---|---|---|
| `Wall_Plaster_Door_Round` | −1.0000 .. 1.0000 | the 2m cell, exactly |
| — its opening | −0.6495 .. 0.6551 | **+0.0028**, 1.305m wide |
| `Door_1_Round` | −0.0463 .. 1.0737 | **+0.5137**, 1.120m wide |
| `Door_2_Round` | −0.0427 .. 1.0728 | +0.5151, 1.116m wide |

Read off the glTF POSITION accessors, the same way D12's numbers were, and the
same way the cottage-ridge argument was settled. Place a leaf on the doorway's
own origin and its centre lands at +0.514 while the hole's is at +0.003. The
error is **0.511m — half a leaf** — which is precisely what "needs like a half
offset" describes, and half the door ends up hanging over the pier.

So a leaf declares **`hangs`**, an offset in its **own** local frame, and
`structures.place()` applies it after the yaw. In its own frame and not in world
space, because a door on the north wall and one on the east wall are the same
piece at different yaws — a world-space correction would be right on one and a
metre out on the next, which is D12's rotation trap wearing a different hat.

**The record keeps the snapped point, not the offset one.** The grid coordinate
is what `occupied()` compares and what a save file should carry; applying the
offset at placement means a reload applies it exactly once instead of drifting
half a leaf every time the game is loaded.

## 2. A door had no behaviour, and now it is a station

`pieces.json` had two leaves and two frames. All four placed, saved and reloaded
as static meshes. Nothing anywhere turned one, and nothing read `interact` for
one. `station.gd` is the mechanism for a placed piece that does something — the
bed, the pal bed, the campfire, the workbench, the chest and the berry plot all
use it — and no door did.

`Door` is a station, and it rests on the same measurement as the offset: because
the leaf's origin **is** its hinge, and `place()` puts the piece node exactly
there, **turning the piece node turns the leaf about its hinge** — and the
collider, a child of the same node, goes with it. One number moves the art and
the physics together, which is the only way an open door is guaranteed not to
leave a slab across its own doorway.

It swings **away from whoever opened it**, from either side. Not politeness: a
leaf that always swings the same way sweeps a `StaticBody3D` through the player
half the time. `toggle()` therefore takes the point the opener is standing at,
and it is not optional.

It persists like the campfire's `lit`: the catalogue knows a door starts shut,
and only the save file knows this one was left standing open.

**No locks and no keys.** Whether a building can be denied to the player is a
design decision, and CLAUDE.md says to flag those rather than invent them.

## 3. The doorways were sealed, and this is the one the pictures hid

`pieces.json` records one measured bounding box per piece. For a doorway wall
that box is 2m × 3.12m **of solid collision**, and a bounding box has no doorway
in it. Every pre-built cottage in the Meadows was shut: not "the door does not
open" but *the player had never been inside one of these houses*, and could not
have been.

This is the failure mode D12's closing section describes and the reason its
acceptance is a rendered frame — except that a picture could not have caught this
one either. A door swinging open in front of an invisible wall photographs
perfectly.

So a piece may carry **`collider_boxes`** — piers and a lintel, measured from the
same accessors — and `collider_centre`/`collider_extents` stay as the single
bound, because `scripts/world/vegetation.gd` reads them for the settlement. The
opening is 1.305m wide and clear to the arch springing line at 2.156m, which a
1.80m trainer walks through. The arch above that line is boxed off rather than
followed; nothing in this game is tall enough for the difference to exist.

`tools/preview_doors.gd` **raycasts** it rather than photographing it: through the
doorway must be clear, through the pier must be solid, and through a shut door
must be blocked. That is the acceptance for this one, and it is a probe rather
than a frame for the reason above.

## The authored houses, and why `door_leaf` became `door_hangs`

The settlement's cottages are drawn by the scatter as static instances, and a
static instance cannot open. `settlement.json` used to name a `door_leaf` per
room, which made `scatter_rules._expand_room()` emit a **mesh** at the doorway
wall's own origin — a dead door, in the wrong place, which is both halves of the
owner's report in one line of data.

The key is now `door_hangs`, plus a `door_frame`, and
`scripts/building/doors.gd` reads them. Renaming rather than adding is the whole
mechanism: the scatter no longer finds a key it recognises, so it draws no leaf,
and a room cannot end up with two doors in one doorway with one of them dead.

`doors.gd` asks `scatter_rules.buildings_for()` **where the doorways are** rather
than working it out again, so there is no second copy of the layout maths to
drift from the first — the same discipline `scatter_rules` keeps about
`pieces.json`, in the opposite direction. **Nothing in `scripts/world/` was
modified.**

The doors it hangs are **world-owned**: `structures.place_fixed()` builds them
through the same path as a placed piece and then keeps them out of `records()`,
out of `count()`, out of `remove_nearest()` and safe from `clear()`. Grandpa's
front door is content, not something the player built and can demolish for a
refund of materials they never paid.

The frame is a third piece and not a nicety. The hole is 1.305m and the leaf is
1.120m, so a leaf alone leaves nine centimetres of daylight down each jamb and a
hand's width of sky under the arch — which is what the first render of this fix
showed from inside the cottage. A frame is for covering a reveal.

## What this does not settle

- **Sound.** `opened()` and `closed()` exist so a sound can hang off them. There
  is no audio system yet and this did not build one.
- **A prompt.** Nothing tells the player the door is there. `interact` is
  discoverable because it is already the satchel and encounter verb, but a "press
  E" prompt belongs to whoever owns the HUD.
- **Pals and doors.** A shut door stops the trainer. Whether it should stop a
  following pal is a pathing question and belongs to that system.
- **`Doors` lives in the scene.** It is mounted by
  `build_mode._mount_field_systems()`, beside `Harvestable` and `Tools`, for the
  reason that function already states.

## See also

- `docs/decisions/D12-the-build-grid-is-measured-from-the-kit.md` — two origins;
  this is the third
- `data/building/pieces.json` — `_comment_opening` and `_comment_collider_boxes`
- `scripts/building/doors.gd`, `scripts/building/station.gd` (`class Door`)
- `tests/test_doors.gd` — the measurement, as arithmetic
- `tools/preview_build.gd`, `tools/preview_doors.gd`
