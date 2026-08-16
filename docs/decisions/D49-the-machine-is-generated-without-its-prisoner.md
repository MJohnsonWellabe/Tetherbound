# D49 — The Tether Machine is generated without its prisoner

**Date:** 2026-08-16 · **Decided by:** the owner authorised the generations
("finish the meshy work except the warden's face"); the method below is this
firing's, forced by `D24` and `D23` §20.

## What was decided

The last two of `D24`'s three reserved Meshy hero objects — the Relay Apparatus
(board 14, `SE23`) and the Legendary Tether Machine (board 15, `R8.2`) — are
generated and installed. Both were shipping as clearly-marked placeholder
massing; both seams are now closed.

The Warden's face is **not** included. The owner excluded it, and independently
`CLAUDE.md` forbids spending a generation on anything without owner-supplied
reference art. No sheet for his face exists.

## The problem this decision is really about

**Board 15 draws the machine with a bound legendary inside the cage**, because
that is what the machine is for. `D24` reserves the generations for hero
OBJECTS. `D23` §20 forbids new creature meshes outright, and was reaffirmed
with 5000 credits available, so a healthy balance does not lift it.

`meshy.py` already had a negative prompt, and the machine got its own
(`NEGATIVE_MACHINE`) banning creature terms. **That is not sufficient and
should not be relied on.** `generate` uses multi-image-to-3D, which follows its
reference images far more closely than its words. Feeding four pictures that
all contain a dragon and asking in text for no dragon is a coin flip, and the
failure mode is a licence breach baked into a mesh.

## What was done instead

The occupant comes out of the **pictures**.
`tools/art_pipeline/crop_prop_views.py::lift_occupant` erases it from the front
and side crops before they are ever uploaded: a colour key confined to the cage
interior, followed by a morphological close to swallow the speckle left where
the creature's darkest scales fall outside the hue window. Inside the cage the
only bright saturated cyan in the drawing *is* the creature — the machine's own
runic glow is thin lines on dark stone, outside that box — so the key is
precise, and the containment rings, clamp arms and chains that surround the
creature survive untouched. The rear and top views needed no lifting: the board
draws the machine empty in both.

Every candidate was then checked by eye. None contains a creature.

## Why not simply use the two clean views

That was the first attempt, and it failed on quality rather than on licensing:
three preview candidates from the rear elevation plus the top plan came back as
shattered spires with no arch, dais or ring recoverable. One elevation and one
orthographic plan is not enough for multi-view reconstruction — the plan reads
as a disc rather than as the top of anything.

So the licence problem and the reconstruction problem turned out to have the
same fix: **lift the occupant and use all four views**, rather than avoid the
views that contain it.

## What this cost, and what it bought

300 credits of a 4720 balance (nine preview candidates, four refine). Balance
after: 4400.

The chapter's two remaining placeholders are gone. All three of `D24`'s hero
objects now exist. `smoke_stronghold` measures the machine at 16.6 × 15.0 ×
12.0 m against board 15's own 0–20 m scale bar, and reports
`placeholder=false`.

## Three bugs this uncovered, all of which only bite once a seam is used

1. **`stronghold.gd::_build_machine` returned early on the model path**,
   skipping the base collider, the core light and `_markers["machine"]`. That
   would have shipped a 15 m machine the player walks straight through, in an
   unlit chamber, with the marker missing from the dictionary `R8.4`'s freeing
   sequence reads its position out of. A seam that is only exercised on the day
   the placeholder stops being watched is a seam whose untested branch is the
   one that ships.
2. **Neither seam scaled the mesh.** A Meshy GLB arrives in the generator's
   units — the machine's raw export is 1.7 m tall — and its origin is wherever
   the exporter left it. Both seams now fit the mesh to the authored height by
   the mesh's own visual bounds rather than trusting its transform.
3. **`smoke_stronghold::_aabb_of` was scale-blind**, reading each
   `mesh.mesh.get_aabb()` and only translating it. Correct while every mesh sits
   at scale 1, which was true of the primitive massing and false the instant a
   fitted model landed: it measured the correctly-sized 15 m machine at its raw
   1.7 m and failed the build. It now measures through the full transform.

## Consequences

- The `massing` blocks in `data/config/tether_relay.json` and
  `data/config/stronghold.json` are **not dead code**. They are the fallback the
  builders still take when `model` is unset or the file is missing, and the
  record of the subassemblies each board names. Do not delete them.
- `tools/art_pipeline/prop_views.json` carries the crop boxes and the
  `lift_occupant` regions. If board 15 is ever redrawn, those boxes move with
  it — and `_comment_the_occupant` in that file is the thing to read first.
- `tools/capture_hero_asset.gd` renders an installed hero object through the
  game's own renderer in seconds. It is not a replacement for the Blender
  turntable (which is the candidate-judging tool, orthographic and identical
  across candidates); it answers the different question of what the asset looks
  like under `gl_compatibility`, which is where the pylon's emission bug hid.
- **No further Meshy generation is licensed for the Meadows.** The Warden's
  face is the one outstanding art request and it needs owner reference art
  before a single credit is spent.
