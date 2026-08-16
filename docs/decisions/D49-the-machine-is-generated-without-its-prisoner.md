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

## Addendum — the Warden, 2026-08-16

The owner supplied his character sheet the same day
(`docs/art/reference/16_Warden_Aldis_Character.png`), lifting the one blocker
that had stood since `R8.3`.

**Board 16 supersedes board 06 for the Warden.** Board 06 draws a masked
soldier whose face is hidden behind a hard visor and a plate over nose and
mouth; board 16 draws a bare, bearded, human face with a green marking painted
across the eyes in the shape of a domino mask, level with the skin. The
generation prompts in `meshy.py` were tuned hard against board 06 — including a
capitalised demand for the mask as raised geometry — and have been rewritten
against 16. The one thing carried forward unchanged is the **value break**:
board 06's gate review failed this character at distance ("at 300px he is a
vertical green rectangle"), board 16 is green on green too, and its answer is
the pale cream fur mantle, so that stays stated LARGE and PALE.

### What was done

Board 16's four head views — front, 3/4, side profile, **and back of head** —
are cut into `assets/creatures/tetherbound/warden_head/reference/`.
`meshy.py::cmd_head` exists precisely because a whole-figure pass cannot
resolve an eye socket, but it could only ever send ONE crop and admitted the
cost in its own docstring: *"the generator invents the back of the skull"*.
Board 16 draws the back of the skull, so the head goes through the ordinary
four-view `generate` path instead — strictly more information for the same
money.

The head generated well on the second attempt. **The first attempt failed the
same way board 15 nearly did**: the crops ran down to the chest, and all three
candidates came back as full standing figures with tiny blank heads, because
image-to-3D follows its pictures over its words and "HEAD AND NECK ONLY" in
capitals lost to four pictures containing shoulders and a fur mantle. Cropping
to the jaw line fixed it, and the faces now carry brows, lids, a real nose and
a beard. Candidate `e` is the best of three.

### What was NOT done, and why

**A retexture of the existing body was tried first and rejected.** Aiming
`meshy.py texture` at board 16 drained the colour out of him — no gold trim, a
grey-green coat, a dulled cream cape, and a face no better than before. The
original model was never overwritten and the attempt is not in the tree.

**The head is not installed.** Installing it means `graft_head.py` →
`cleanup_mesh.py` → rig → procedural clips → grade → install → in-engine
validate, and the graft has to happen on the **pre-rig** body. That raw body is
not in this container (`assets_raw/` is gitignored and was never carried
across), so the only warden mesh here is `warden_lod0.glb`, which is rigged and
animated and working in the game. Grafting onto that destroys the rig.

So the honest state is: **the Warden's face is generated and judged, and the
swap is a full character-pipeline run rather than a finishing touch.** What is
committed is everything that run needs and does not have to be redone — the
board, the four head crops, the board-16 prompts, and the head-only crop rule
that took two attempts to find. What remains is body → graft → remesh → rig →
animate → install. Blender is required for it and is NOT part of this image; it
was installed ad hoc here (`apt-get install blender`).

### The fourth route was taken, and the Warden is rebuilt

The owner said "run the character pipeline, redo Meshy if you need to, just
finish this work." He is finished and installed.

**Body** generated from board 16's own FULL BODY SILHOUETTE panel — which is
not a silhouette but a clean front-and-back turnaround at one scale. Candidate
`b` of three won on one specific thing: `NEGATIVE_HUMAN` bans `staff`, the
board draws him holding one, and `b` is the candidate where the ban took. That
ban is deliberate and is the *opposite* of the `DROP_FOR_SPECIES` case — there
a shared negative fought a creature's own signature, here it removes an
accessory the game has no use for.

**Head** grafted from the separately-generated `warden_head` candidate `e`,
then textured against board 16, auto-rigged at 1.85 m, and animated with the
five gameplay clips `animate_humanoid.py` bakes (idle, walk, sprint, jump,
throw) — the same five `data/config/art.json` already asked for, so nothing
downstream changed.

### Two tools grew a flag each, and both were earned by a visible defect

- **`cleanup_mesh.py --skip-voxel`.** The voxel remesh turned his coat, cape
  and mantle into lace at every voxel size tried, and *finer voxels made it
  worse* — which is how it was finally pinned on the remesh rather than on thin
  walls. Rendering the intermediate settled it: the grafted mesh is perfect and
  the remeshed one is holed. The remesh exists to weld loose parts into a
  manifold for **Blender's bone-heat weighting**, and humanoids in this project
  do not use bone heat — `finish.py rig --kind humanoid` calls Meshy's
  auto-rigger, which takes loose parts happily. So for a humanoid the remesh is
  all cost and no benefit. Decimation alone gets to 30k with the topology
  intact.
- **`graft_head.py --drop`.** The first install had a neck the owner called
  *"comically long"*. The body's own neck stump and the grafted bust's neck
  stack, and neither existing lever shortens that: `--overlap` moves the CUT,
  so raising it keeps MORE neck, and negative values lift the head clean off
  the shoulders (both rendered and looked at). `--drop` translates the placed
  head down into the collar. **0.45 head-heights** put his jaw on the fur.

Final recipe, for whoever rebuilds him next:

    graft_head.py  --head-fraction 0.18 --overlap 0.15 --drop 0.45
    cleanup_mesh.py --target-tris 30000 --skip-voxel
    meshy.py texture warden <mesh> --style-from warden_body --resolution 2k
    meshy.py rig <textured> --height 1.85
    animate_humanoid.py

953 tests pass, `smoke_art` and `smoke_boss` both green.

### The three routes that did not work, kept because they cost real time

1. **Retexture the shipped body against board 16.** Rejected: it drained the
   colour, lost the gold trim, dulled the cream cape, and the face came back no
   better. `enable_original_uv` is false on that endpoint, so it re-UVs and
   discards the hand-graded texture the current asset carries.
2. **Graft the new head onto the shipped body.** The graft itself WORKS —
   `graft_head.py` finds the body's neck at 0.917 of height once the armature
   is stripped, scales the bust to the board's ~7-heads ratio and drops it in.
   What kills it is the step after: `cleanup_mesh.py`'s voxel remesh, which the
   graft explicitly depends on to weld the two volumes, shreds this body. The
   shipped Warden is a finished asset with a THIN-WALLED cape, coat skirt and
   layered collar; voxel remeshing at 28k triangles eats thin surfaces, and the
   result was a hole-riddled mass with the head gone entirely.
3. Raising the voxel budget was not attempted, because the failure is
   structural rather than a tuning miss — the graft path assumes a freshly
   generated, solid, PRE-RIG body, and every other character in this project
   went through it in that state.

**The fourth route was the one taken** — see above. Note that route 2's
failure was misdiagnosed at first as thin-wall loss and blamed on the graft;
it was the remesh, and `--skip-voxel` is the fix.
