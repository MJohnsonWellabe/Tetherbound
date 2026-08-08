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
