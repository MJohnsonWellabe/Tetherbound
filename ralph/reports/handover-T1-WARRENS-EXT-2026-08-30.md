# Handover — T1-WARRENS-EXT, 2026-08-30

## What was asked

Fix the Burrow Warrens **exterior** -- the approach, the mound, and the
mouth -- against the owner's and the blind Fable judge's independently
matching verdict "Warrens exterior: bad" (`ralph/OWNER_FEEDBACK_2026-08-29_BUILDINGS.md`,
`ralph/reports/JUDGE-VISUAL-2026-08-29.md` subject 3), while leaving the
Warrens **interior** (`scripts/world/interior_structure.gd`, judged GOOD)
untouched, and answering the owner's real question: why did the interior
method succeed where the exterior did not, and does that reasoning extend.

## Where this got to

Three targeted fixes landed on `ralph/T1-WARRENS-EXT` (commit `bae2017a`),
each tied to a specific line in the judge's report, diagnosed from the
actual code path rather than guessed:

1. **The mouth facade never got a doorway frame.** `interior_structure.gd`'s
   `_reveals()` pass builds a jamb-and-lintel frame around every entry in
   `_openings`, and `burrow_warrens.gd::_build_passages()` populates that
   list from both ends of every internal passage. The cave's own front
   door is **not** a passage -- `_opening_on()` synthesises it specially
   for `chamber == "mouth", side == "-z"` -- so it was never appended to
   `_openings`, and the one doorway every player actually walks through
   never got the frame every interior doorway already has. That is the
   literal mechanism behind "the mouth facade is a flat wall with a
   rectangular hole." Fixed in `_build_chambers()`: the mouth's own
   outward opening is now recorded the same way a passage end is.

2. **The site skirt never touched a model's material, and scaled every
   model in one boulder-sized range.** `_build_site_skirt()` was the one
   placer in this file that instantiated a model and added it to the tree
   with no material pass at all -- every OTHER rock on this outcrop
   (`_place_rock` for the mound, `_place_interior_rock` for the chamber
   walls) already wears the cave's own triplanar Rock030 stone via
   `_wear_the_cave_stone()`; the skirt alone still carried the nature
   pack's raw mint-grey `Rocks_Diffuse.png`. It was also the one placer
   that ran a plant and a boulder through the same `skirt_scale`
   (2.2-4.4x, tuned for `Rock_Medium_*`), which is why a small rosette
   prop came out oversized. Split into `skirt_rock_models` (now
   `_wear_the_cave_stone`, matching the mound) and `skirt_flora_models`
   with their own, much smaller `skirt_flora_scale` and
   `_dress_skirt_flora()` -- the exact Bush_Common leaf-texture swap
   (`Leaves_TwistedTree` -> `Leaves_NormalTree_C.png`) and Grass_Wide_Tall
   retint (`#404e21`) `vegetation.json`'s own corridor scatter already
   uses for these two meshes, reused rather than reinvented.
   `Plant_1` is **dropped**, not rescaled: `vegetation.json`'s own
   `_comment_rosettes_gate_d` already adjudicated this model unfit for
   general ground cover after an independent blind critic read it as
   agave/tropical, and pulled it from the corridor's own scatter for
   exactly that reason. The judge's "oversized purple flower (petals
   ~40cm against the 1.8m trainer)" and the bright crimson bush visible
   in `W-ext-01-knoll-from-outside.png` are almost certainly this same
   placer's two halves of the same bug (no material pass, no
   model-appropriate scale).

3. **Mound/skirt boulders read as chamfered cubes and alias to a
   checkerboard at distance.** `_material()`'s `normal_scale` (2.2) and
   the interior's shadowless dim omnis were tuned together across several
   judged rounds and the interior bar (GOOD) depends on that pairing --
   left untouched. Outdoors, the same normal detail is driven by a real
   directional sun on triplanar-mapped boulders scaled up to 4.4x, and at
   distance the per-pixel normal perturbation aliases past what this
   software rasterizer's triplanar blend filters -- visible directly in
   `W-ext-01-knoll-from-outside.png`'s right-hand wall face, a plainly
   regular checkerboard grid. `_wear_the_cave_stone(..., exterior=true)`
   now passes a lower `normal_scale` (1.15) for exactly the mound/skirt
   rock this affects, plus explicit anisotropic texture filtering
   (`_material()`'s new `textured` branch), leaving every interior caller
   (`_place_interior_rock`, the chamber walls, the vault plinth) at the
   original 2.2. Boulders also went from a uniform `Vector3.ONE * scale`
   to a modest per-axis stretch (+-15-18%) in `_place_rock`, so the same
   low-poly mesh reads less like a perfectly scaled cube.

## Done-and-verified vs done-but-unverified

**Done, and confirmed against the actual before-frames** (the judge's own
`ralph/reports/judge-visual-2026-08-29/W-ext-01/02/03*.png` -- I did not
re-render a "before" myself; those are the real evidence this lane
answers, and re-deriving them would have spent the render budget twice
for the same picture):

- The mint-green faceted rocks flanking the doorway in `W-ext-03` and the
  teal-shadowed faceted rock in `W-ext-02`'s foreground are visibly the
  same source material the skirt fix targets.
- The crimson clump in `W-ext-01` is the Leaves_TwistedTree bug the
  Bush_Common retexture fixes.
- The regular checkerboard grid on `W-ext-01`'s right wall face is
  visible directly in that frame, not inferred.
- The purple flower prop and the tall bright-green blade grass in
  `W-ext-01`/`W-ext-02` match `Plant_1`/`Grass_Wide_Tall` at the old,
  shared boulder-scale range.

**NOT yet verified**: whether the fixes actually read correctly once
rendered. A real 240-frame `tools/capture_warrens_63.gd` pass was started
against the fixed code (see Commands below) but this environment's
software rasterizer takes 50+ minutes for that tool, and \<<<FILL IN
BEFORE SENDING -- state whether that run finished, and if so, either link
the after-frames or paste the one-line verdict; if not, say it is still
running and where to find the log.>>>

A cheap 90-frame iteration stand (this session's own
`/tmp/.../scratchpad/iter_warrens_ext.gd`, not committed -- see below) was
tried first for faster turnaround and its camera stands landed **inside**
the mound's own geometry (both hand-picked eye points were closer than the
mound's actual outward reach). That is the exact problem
`capture_warrens_63.gd::_clear_exterior_views()` already solves by
ray-casting for a clear stand rather than guessing a position, which this
lane re-learned the hard way instead of reusing from the start. The two
frames it did produce are not usable evidence (one is nose-against-rock,
the other is a close-up of pure granite texture) and were not committed.

## Exact commands and camera stands

Environment setup (this session; Godot is not preinstalled):

```
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip
unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 && mv Godot_v4.7-stable_linux.x86_64 /usr/local/bin/godot
godot --headless --path . --import        # exit 0 this run, first try
```

Evidence (the real tool, the one the judge used, ~50+ min):

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/capture_warrens_63.gd
```

Frames land in `shots/warrens_63/` (gitignored): `03-mouth`,
`04-hall-dressing`, `05-hall-from-the-doorway`, `06-den-and-guardian`,
`07-den-dressing` (authored, cave-local), plus two auto-found
`0{1,2}-knoll-from-outside` exterior stands from
`_clear_exterior_views()`'s ray-cast ring search. This is the tool and the
stand set the judge's `W-ext-01/02/03` and `W-int-01/02` frames came from.

**The judge's own before-frames are the before-evidence for this pass** --
`ralph/reports/judge-visual-2026-08-29/W-ext-01-knoll-from-outside.png`,
`W-ext-02-knoll-from-outside.png`, `W-ext-03-mouth-door.png` (mound/skirt),
and `W-int-01-den-wide.png`/`W-int-02-hall.png` (the protected interior
bar). I read these directly rather than re-rendering a redundant "before."

## The interior-vs-exterior grammar question

The owner's brief asks this as the real question, and it deserves a
direct answer rather than a restatement of the diagnosis above.

**The interior method succeeded because it solves a problem exteriors do
not have, and this pass's three defects confirm that by being three
different problems that all happen to sit on the same building.**
`interior_structure.gd`'s own header states the mechanism: an interior
wall under a shadowless omni has nothing to give it a middle scale of
visual interest, because no light in the room is going to model form for
free, so the bays/course/ribs/reveals/corners passes build that scale
into the geometry itself. Outdoors, the sun already does that job --
`T1-ARCH_buildings_2026-08-29.md` reached the same conclusion for the
stronghold's lighting and the castle's flatness, independently, before
this lane started. **So "does the interior grammar extend to exteriors"
has two different answers depending on which part of the grammar is
asked about:**

- **The structural vocabulary (bays, course, ribs, corner posts) does
  NOT need to extend outdoors**, and should not: the mound's mass is
  already broken up by real boulders with real silhouette variation,
  which is a strictly richer middle scale than a repeating pilaster rhythm
  would add, and doubling up would just be two competing systems on one
  wall.
- **The one piece of the grammar that IS about construction, not about
  light, extends directly and was simply never wired up: `_reveals()`.**
  A jamb-and-lintel frame around a cut opening is not answering "how do I
  give a lit surface a middle scale" -- it is answering "does this hole
  in a wall read as something that was built", which is exactly as true
  of a door in full daylight as a door in torchlight. This pass's fix #1
  is that answer, applied for the first time to the one doorway that was
  structurally excluded from ever receiving it.

The other two fixes this pass made (skirt material, boulder aliasing) are
**not** grammar questions at all -- they are the same two failure modes
`T1-ARCH_buildings_2026-08-29.md` already named for the stronghold and the
castle (wrong source texture, and a lighting/material mismatch between
what a treatment was tuned against and where it actually got applied),
recurring here in a third register (an untouched placer, and a normal-map
scale tuned for indoor omnis reused outdoors under real sun). **The
pattern across all three T1-ARCH sites plus this one is not "exteriors
need their own grammar" -- it is "this codebase has one recurring bug
shape: a material or a lighting treatment gets tuned once, against one
condition (interior light, one specific model), and then gets reused
somewhere the tuning does not hold, silently."** The fix each time is not
a new system, it is noticing the second site and giving it its own
tuned value, which is what this pass's `exterior` parameter on
`_wear_the_cave_stone`/`_material` does explicitly rather than leaving a
future reader to rediscover it by frame.

## Disagreements / things worth flagging

- The brief's diagnosis focuses on rock language and boulder read. The
  actual before-frame (`W-ext-01`) shows the checkerboard-aliasing defect
  it calls "the loudest single defect in the set" plainly, on a flat wall
  face, which strongly supports a normal-map/filtering explanation over a
  geometry explanation -- but I have not yet measured this against an
  after-frame at time of writing this section (see the unverified item
  above). If the after-frame still shows aliasing, the more likely
  remaining cause is the underlying `Rock_Medium_*.gltf` mesh's own
  low-poly facets at 2.2-4.4x scale reading as flat, near-axis-aligned
  quads that any triplanar projection will alias on at a shallow angle,
  which is a mesh-density problem no material tuning fixes -- flag for
  the next lane rather than guess further here.
- The "concrete slab" approach-apron complaint (`_floor_material()`,
  `Ground030` at a near-white lerp tuned to fix a DARK-interior problem
  three rounds ago) was diagnosed but **not fixed** in this pass. I chose
  not to touch it blind: `_floor_material()`'s own comments record two
  prior over-corrections (a "beach" that was too light, then a floor that
  crushed the room's whole value histogram), both found only by rendering
  and measuring, and I did not want to spend this pass's remaining render
  budget on a fourth guess at the same lever without seeing whether the
  other three fixes already change how it reads next to properly-coloured
  rock and flora. If the after-frame still shows it reading as a slab,
  the right next move is almost certainly to split `_floor_material()`
  into interior/exterior variants the same way this pass split the rock
  material, not a fourth retune of the shared one.

## File footprint

- `scripts/world/burrow_warrens.gd` -- `_build_chambers()` (mouth opening
  recorded), `_material()` (parametrised `normal_scale`, anisotropic
  filter), `_wear_the_cave_stone()` (`exterior` param), `_place_rock()`
  (non-uniform scale), `_build_site_skirt()` (rewritten, rock/flora
  split), new `_dress_skirt_flora()`, new `LEAF_GREEN` constant.
- `data/config/burrow_warrens.json` -- `mound.skirt_models` replaced with
  `skirt_rock_models`/`skirt_flora_models`, new `skirt_flora_scale`,
  `skirt_flora_fraction`.
- Not committed: `/tmp/.../scratchpad/iter_warrens_ext.gd` (this
  session's failed cheap-iteration stand; superseded by using the real
  tool directly once its stands proved necessary) and its two unusable
  frames.

## What I would do next

1. Confirm the after-render (see unverified item) and, if the checkerboard
   or the mound's cube read still fails, escalate to the mesh-density
   explanation above rather than a fourth material retune.
2. If the after-render otherwise reads well, take one pass at the
   approach-apron floor material as its own small, evidence-driven fix
   (interior/exterior split, following this pass's own precedent) rather
   than leaving it for a fresh diagnosis session.
3. Hand the interior-vs-exterior answer above to whichever lane is
   rebuilding the Meadows Hall, per the brief's own routing note -- the
   `_reveals()` extension in particular (frame every daylight opening
   too, not just lit interior ones) is directly reusable there.
