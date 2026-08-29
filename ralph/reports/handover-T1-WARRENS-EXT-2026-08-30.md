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

**All four fixes below landed, and all four are verified against real
render evidence** (`tools/capture_warrens_63.gd`, the same tool and stands
the judge used) -- not just plausible from reading the code. Commits
`bae2017a`, `829c5442` on `ralph/T1-WARRENS-EXT`. Side-by-side frames are
committed at `ralph/reports/T1-WARRENS-EXT/shots/{before,after}/` (the
`before/` copies are the judge's own frames, not a re-render -- see
"Exact commands" below for why).

Four targeted fixes, each tied to a specific line in the judge's report,
diagnosed from the actual code path rather than guessed:

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

4. **The approach ramp reused the interior floor's near-white lerp and
   read as poured concrete.** `_floor_material()`'s 0.42 lerp toward
   `ROCK_TINT` was tuned, three rounds deep and by measurement, to solve
   an interior-only problem: a floor competing with shadowless-omni-lit
   walls for a room's midtone mass. The approach ramp calls the same
   function under full daylight sun, where there is no histogram to
   protect, and the same near-white lerp instead reads as an unweathered
   slab beside boulders that (after fix #3) now carry real facet
   contrast -- "a plain grey concrete walk slab... sits on the grass with
   no edge blend." `_floor_material(exterior)`/`_floor_box(...,
   exterior)` give the ramp its own much smaller (0.12) lerp, pulling it
   back toward the source photo's warm dirt colour; every interior floor
   call site is untouched.

## Done-and-verified vs done-but-unverified

**All four fixes are done and verified**, against a real
`tools/capture_warrens_63.gd` pass run twice (once after fixes 1-3, once
more after fix 4) on this branch's own code, compared directly to the
judge's own before-frames (`ralph/reports/judge-visual-2026-08-29/`).
Side by side, committed at `ralph/reports/T1-WARRENS-EXT/shots/`:

- **Rock language**: `before/W-ext-03-mouth-door.png` shows dark granite
  mega-boulders, smooth mint-green faceted rocks, and a plain grey slab
  in one frame. `after/03-mouth.png` shows one consistent granite
  language flanking the door and along the whole knoll in
  `after/01/02-knoll-from-outside.png` -- no mint-green rock visible
  anywhere in either after-frame, and the crimson Bush_Common clump
  visible in `before/W-ext-01` does not appear in `after/01`.
- **Checkerboard aliasing**: `before/W-ext-01`'s right-hand wall face
  shows a plainly regular pixel grid. `after/01-knoll-from-outside.png`
  (matching stand) shows none -- the surface reads as continuous
  granite mottling at the same distance.
- **The mouth doorway**: `before/W-ext-03` is a flat wall with a
  rectangular hole. `after/03-mouth.png` (cropped in this session's own
  review, not committed) shows a real lintel band across the top of the
  opening and a jamb post standing just inside the threshold -- genuine
  built depth, not a hole.
- **The approach ramp**: `before/W-ext-03`'s path is flat pale grey.
  `after/03-mouth.png`'s path is a warm dark brown with visible
  paver-like variation, no longer reading as poured concrete.
- **The interior bar is unaffected**: `after/06-den-and-guardian-
  interior-unchanged-reference.png` -- dirt floor, timber ribs, pilaster
  rhythm all intact, confirming the `exterior` parameter split on both
  the rock and floor materials did not leak into any interior call site.

**Still open, not attempted this pass**: the mound's boulders still show
a visibly boxy/faceted top silhouette in `after/01-knoll-from-outside.png`
-- better than before (no longer reading as a mint hedge, no longer
aliasing), but still readable as "large chamfered blocks" rather than
organic stone. See Disagreements below for why I believe this is a
mesh-geometry limit rather than something a fourth material tweak fixes,
and did not chase it further inside this pass.

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

- The brief's diagnosis treats "boulders read as chamfered cubes" and
  "aliases into a checkerboard at distance" as two symptoms of one cause.
  The render evidence says they are two different causes that happened to
  share a frame: the checkerboard was a normal-map/filtering problem
  (fixed, confirmed gone) and the boxy silhouette is a mesh-geometry
  property of `Rock_Medium_*.gltf` at 2.2-4.4x scale that a material
  change cannot reach -- non-uniform per-axis scale softened it visibly
  but did not remove it (see `after/01-knoll-from-outside.png`). Fixing
  the remainder needs either a higher-poly/more-fractured rock model (a
  new asset, or an owner-supplied reference for one, per CLAUDE.md's
  Meshy rule) or a lot more, smaller boulder instances breaking up the
  large flat faces geometrically -- both bigger than this pass's scope.
  Flagged for the next lane rather than chased further here.
- I initially planned to leave the approach-ramp floor for a future pass
  (see the in-progress draft of this section, superseded) but the render
  budget allowed a second, cheap round once fixes 1-3 were confirmed, so
  fix 4 above landed in this same pass instead of being deferred.

## File footprint

- `scripts/world/burrow_warrens.gd` -- `_build_chambers()` (mouth opening
  recorded into `_openings`), `_material()` (parametrised `normal_scale`,
  anisotropic filter), `_wear_the_cave_stone()` (`exterior` param),
  `_place_rock()` (non-uniform scale), `_build_site_skirt()` (rewritten,
  rock/flora split), new `_dress_skirt_flora()`, new `LEAF_GREEN`
  constant, `_floor_material()`/`_floor_box()` (`exterior` param),
  `_build_approach_apron()` (passes `exterior=true`).
- `data/config/burrow_warrens.json` -- `mound.skirt_models` replaced with
  `skirt_rock_models`/`skirt_flora_models`, new `skirt_flora_scale`,
  `skirt_flora_fraction`.
- `ralph/reports/T1-WARRENS-EXT/shots/{before,after}/` -- the evidence
  frames this handover cites, committed (repo-root `shots/` is gitignored
  and a prior lane lost evidence to exactly that).
- `ralph/reports/handover-T1-WARRENS-EXT-2026-08-30.md` -- this file.
- Not committed: `/tmp/.../scratchpad/iter_warrens_ext.gd` (this
  session's failed cheap-iteration stand; superseded by using the real
  tool directly once its stands proved necessary) and its two unusable
  frames.

## What I would do next

1. The mound's remaining boxy silhouette (see Disagreements) needs either
   a different/higher-detail rock model or a geometric density change,
   not another material pass -- flag it rather than re-attempt it
   blindly.
2. Hand the interior-vs-exterior answer above to whichever lane is
   rebuilding the Meadows Hall, per the brief's own routing note -- the
   `_reveals()` extension in particular (frame every daylight opening
   too, not just lit interior ones) is directly reusable there, and so is
   the general lesson that a treatment tuned against one light/material
   condition needs an explicit second value, not a silent reuse, the
   moment it is applied under a different one.
3. Nothing else in this site's scope is currently open. The interior
   remains untouched and, per the after-frame above, unaffected.
