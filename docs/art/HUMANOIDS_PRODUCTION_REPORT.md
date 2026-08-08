# The trainer, Grandpa and the Warden — production report

Three human characters through `tools/art_pipeline`, plus the one technique
that made them possible. Terrapup's report is the long-form template; this
records what was different, because almost everything was.

## Summary

| | trainer | Grandpa Elias | Warden of the Meadows |
|---|---|---|---|
| Reference | sheet `04` | board `05` crops + `06` head | board `06`, used directly |
| Rounds to a usable body | 3 | 3 | 2 |
| Body source | multi-image-to-3D | multi-image-to-3D | **text-to-3D** |
| Head | grafted, generated separately | grafted, generated separately | painted mask, not modelled |
| Rig | Meshy humanoid, 24 bones | same | same |
| Clips | 5, `animate_humanoid.py` | same | same |
| Shipped | `assets/characters/trainer/trainer_lod0.glb` | `.../grandpa/grandpa_lod0.glb` | `.../warden/warden_lod0.glb` |

## The finding that mattered: bodies do not grow faces

Nine whole-figure candidates, across three characters and three rounds of
prompt work, came back with the same defect. The blind critic, given only
renders and the concept art:

> there is no face on any of the three ... a featureless ovoid with hair over
> it — no brow, no eye sockets, no nose, no mouth.

and on whether it could be fixed by editing:

> b's body is a keeper and worth the three fixes above. b's head is not, and
> no amount of volume editing will make it one.

The prompt was never the problem. It had demanded sockets, lids, brows and a
cut mouth in capitals since round 2. **The problem is resolution allocation:**
at a 30k polygon budget spread over a standing figure, the head is a few
percent of the surface area and an eye socket is smaller than the triangles
available to describe it.

So each character is generated twice — once for the body, once for the head —
and `graft_head.py` joins them. The same generator that produced nine blank
ovoids produced brows, lids, a nose with nostrils and a modelled mouth on the
**first** attempt, for both the trainer and Grandpa, because the whole budget
went to the head.

The graft does not stitch. It cuts both meshes at their own measured neck,
scales the head to the concept's 20%-of-height ratio, and drops it into the
body's stump so the volumes interpenetrate; `cleanup_mesh.py`'s voxel remesh
then fuses them. Scaling to the concept also fixes, in the same operation, the
critic's separate finding that the winning body's head was 10% undersized.

## The Warden took the other road

His board shows him with **arms folded across his chest**, and image-to-3D
reconstructs the pose it is shown. Every round-1 candidate welded the forearms
into a single mass across the belly; the critic called candidate c's
"not merely touching, but welded into one mass ... you cannot select an arm
here because there is no arm as a distinct volume". No amount of "arms at his
sides" in the text outvoted three views of folded arms.

Round 2 went through **text-to-3D** instead. The design is still board 06's —
the prompt is written from it — and the pose is the only thing the drawing
loses. All three round-2 candidates came back with arms hanging clear of the
body.

His face is a **painted mask, not modelled features**, and that is the art
rather than a shortcut: board 06 masks him. Asking for a hard visor and mask
plate plays to what the generator can actually do, and the retexture pass
painted the green mask across the blank geometry exactly as intended.

Two of the round-1 critique's ten complaints turned out to be **my prompt
disagreeing with the art**, not the mesh: the board's cape hangs full from
both shoulders (not a half-cape) and his boots are ankle-high with a folded
cuff (not tall riding boots). The models were right and the prompt was wrong;
it was corrected rather than "fixed" in geometry.

## Clips: two routes measured and rejected before authoring any

- **Reuse KayKit's skeleton.** The trainer shipped on KayKit's Ranger, whose
  23-bone rig comes with all five clips in shared libraries — free, if the
  mesh could be fitted to it. Measured, it cannot: that character is 2.27
  units tall with its head from 1.19 up, roughly **two heads tall**, and sheet
  04's trainer is **6.25**. Nearest-surface weight transfer between those maps
  the boy's chest onto the chibi's jaw, and the clips are authored with chibi
  arm arcs besides.
- **Meshy's animation library.** The rigging response ships exactly two clips
  with skin, `walking` and `running`. The wider library is addressed by
  numeric action id and the API exposes no way to list them — every documented
  listing path answers `Invalid ID`. Two of the five roles, with no route to
  the other three.

So `animate_humanoid.py` authors idle, walk, sprint, jump and throw on the rig
Meshy fitted to each mesh. **They are procedural cycles**, the same honest
standard as the creatures': counter-phased limbs on sine curves with a torso
bob and a head counterweight. Walk reads as walk and throw reads as throw.
They are not hand-animated character work, and they are the first thing to
upgrade.

The clip names ARE the role names, so `data/config/art.json` maps role to clip
one-to-one and nothing is retargeted.

## Bugs this work found, all of them silent

Every one reported success while being wrong. None would have been caught by
reading the code.

1. **`skin_transfer.py` picked its donor with `max(meshes, key=vertex_group_count)`.**
   On a modular character every part carries the same 23 groups, so `max()`
   returned whichever came first — an **arm** — and the entire target was then
   weighted from nearest faces on that arm. It printed "0 unweighted". The
   donor is now every skinned part, joined.
2. **`rig_quadruped.py` refused the stag** because it measured leg separation
   against the whole model's x-span, which on an antlered creature is the
   **rack** — nearly three times the body's width. It reported 0.15 and
   declined to rig a mesh whose legs the critic had just called the cleanest
   in its set. Now measured against the span of the leg band.
3. **`fix_veridian_c.py`'s yaw correction was sign-flipped.** Headings run
   `theta = atan2(x, y)` and the matrix maps `theta` to `theta - phi`, so
   `phi = -theta` doubled the error instead of cancelling it. The model still
   came out "aligned" — at 50 degrees crooked instead of 26. There is now a
   measured assertion after the rotation instead of a confident print.
4. **`meshy.py fetch` only looked at `model_urls`.** Rigging nests its output
   under `result` with per-format keys, so the first rig task reported
   SUCCEEDED and then "returned no GLB" while the file sat there.
5. **Preview generations cost 20 credits, not 5.** Every estimate in the tool
   assumed 5, so a batch billed as "roughly 15" actually cost 60 and the
   budget guard sat four times too high to ever fire. Costs are now one
   measured table.
6. **`turntable.py`'s key light was nailed to one azimuth** while the camera
   orbited, so the back view was lit from behind the subject. A reviewer's
   verdict on a batch of three: "the back renders are worthless — all three
   resolve to near-flat silhouettes with no surface shading", on the one view
   whose job is the nape and the collar. The key now swings with the camera.
7. **Blender's `mesh.delete` operator ignored per-vertex selection flags**
   entirely and deleted whole meshes. `graft_head.py` uses bmesh, which takes
   an explicit geometry list.

## The gate, and it is not a clean sweep

A blind reviewer was given the four finished turnarounds and their concept
art, told nothing about how any of it was made, and asked §10's question:
would a player see the model and the drawing side by side and identify them
as the same designed character?

| | verdict | reads at 3–6 m? |
|---|---|---|
| **Trainer** | **yes** | yes — "teal torso / cream midriff / dark legs / brown boots is a clean three-value stack" |
| **Grandpa** | **yes**, "carried entirely by the wardrobe, not the face" | yes, strongly |
| **Warden** | **NO** | **no** — "at 300px he is a vertical green rectangle" |
| **Veridian Stag** | **NO**, decided by the side view | partial, and "for a reason the design didn't earn" |

Two are recorded as embarrassing to ship as they stand:

- **The Warden's face.** "The face is a texture, not a mask ... a soft green
  splodge airbrushed across bare skin", which "reads as a rendering fault, and
  it's the villain". The masked-face bet was right in principle and the
  retexture did not carry it: a mask has to be raised geometry that casts a
  shadow, not a marking. He also came out slim and closed-coated against a
  board that shows a broad officer in an open greatcoat with a long cape, and
  he fails at distance because coat, trousers, boots, hair and face all sit in
  one green hue at one value.
- **Grandpa's hair.** "An outright defect, not a style choice" — a thick
  bright-white bouffant where the concept has thin receding grey, and in
  profile "a mass of blobby waxy lobes ... like a cauliflower". He is an NPC
  the player stands still in front of and talks to, so it is on screen large.

### What the re-rounds fixed

Both prompts were rewritten against those exact words and re-run, and both
failures are addressed in what now ships:

- **Grandpa's hair.** A second head generation, with the prompt naming a high
  receding hairline and thin sparse hair and explicitly forbidding a full
  bouffant, came back with directional swept strands and a visible hairline.
  The face also came out gaunter and more lined, which was the review's
  secondary complaint. Re-grafted, re-textured, re-rigged.
- **The Warden.** A fourth round, prompted for a broad heavy build, an OPEN
  greatcoat, a long pale cape and a large pale fur ruff, fixed the build and —
  more importantly — fixed the distance failure. The reviewer's objection was
  that "coat, trousers, boots, hair and face markings all sit in one narrow
  green hue at essentially one value"; the full cream cape and heaped cream
  ruff are now the largest shapes on him, so his silhouette carries a hard
  light/dark break from any angle.

### What the re-rounds did NOT fix: the Warden's face

The trainer-and-Grandpa trick — generate the head alone, graft it — was tried
on the Warden and **failed**. Both head candidates came back as unusable
lumpen masses with no readable features at all.

The cause is the one `REFERENCE_CANON.md` has warned about from the start:
his only reference is a figure on board `06`, so a head crop is a ~165px
region upscaled, and it is far too soft to drive image-to-3D. The head-only
technique works because the generator gets a clear image AND the whole polygon
budget; here it only got the budget.

So he ships with a **painted** mask, which is the thing the gate called a
rendering fault at close range. That is an accepted, recorded limitation
rather than a solved problem, and the fix is not another generation round:
**the Warden needs a proper `01`–`04`-quality reference sheet**, exactly as
the canon file has said since it was written. He is not in the first fifteen
minutes, so this does not block the opening sequence.

The reviewer's other
standing warning is recorded rather than acted on yet: **do the stag's antler
pass before building a boss encounter around him**, because its rack "fuses
into one backward-sweeping mass" in profile and writing camera work against a
silhouette that falls apart from the side is how the mistake gets baked in.

The trainer is judged shippable today apart from its backpack, which the
concept draws as cream canvas with a stamped emblem and a teal bedroll, and
which the model replaced with a generic brown pack.

## Known imperfections

- **The clips are procedural.** Named above, repeated here because it is the
  largest gap between this and shipped character work.
- **The Warden has no cape.** Board 06 gives him a long cream cape from both
  shoulders; the text-to-3D body does not have one. The coat, fur collar and
  gold piping all read.
- **Grandpa's vest is a raised front panel, not a garment.** The critic:
  "it never becomes a layer, in any view", and none of the three candidates
  solved it. Fixing it properly is a new shell over the torso.
- **No individual finger bones.** The Meshy rig ends at `Hand`, which is
  enough for everything the game currently asks a human to do.
- **The trainer's backpack is undersized** against the sheet — the critic
  asked for roughly +30% height and +35% width. Deferred: it is a volume edit
  on a mesh that has since been textured, so it costs a retexture to redo.

## Owner review

The frames are in `shots/candidates/trainer-textured/`,
`shots/candidates/grandpa-textured/` and `shots/candidates/warden-textured/`,
and the legendary's in-engine frames in `shots/validation/veridian_*`.
The last box on the §18 gate is yours.
