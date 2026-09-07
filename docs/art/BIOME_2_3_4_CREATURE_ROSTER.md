# Biomes 2-4 creature roster — current status

**Status:** Current, 2026-09-07 (rig-fix pass — every creature that was
modelled this project is now rigged, animated, and wired into
`data/creatures/species.json`; four Cloudreach Cliffs creatures were
regenerated against better owner-supplied reference boards). Companion to
`docs/art/HUMANOID_ASSET_INVENTORY.md` (that file is the human/character
source of truth; this one is the creature source of truth for Cloudreach
Cliffs, Stormwood and the Water Realm).

This is the map from "a creature exists as a `.glb`" to "which biome it
belongs to and what pipeline stage it is at." Read this before generating,
rigging, or wiring any of these species — it says what is already done so
that work is not repeated or contradicted.

Reference boards for every species named below are under
`docs/art/reference/` (numbered 22 onward). Prompts and negative-prompt
overrides live in `tools/art_pipeline/meshy.py`'s `SPECIES_PROMPTS` dict.

## Cloudreach Cliffs (Biome 2)

| Species | Model | Rigged/animated | Wired in species.json | Notes |
|---|---|---|---|---|
| Pebbik | installed | yes | yes | good |
| Craghorn | installed (redone from a new board) | yes | yes | regenerated against an owner-supplied reference board (the earlier board could not be improved on further); texture and silhouette read noticeably cleaner than the prior generation |
| Stormcapra | installed (redone from a new board) | yes | yes | regenerated against an owner-supplied reference board; texture read noticeably cleaner than the prior generation |
| Skyrill | installed | yes | yes | good |
| Aeriex | installed | yes | yes | good, no legs (flying serpent) — rigged anyway, confirmed clean |
| Ribbonray | installed | yes | yes | fixed on the 3rd generation (explicit "wings are the largest feature" + "one bird head, not a fin" language); rigged clean |
| Breezetail | installed | yes | yes | good |
| Cloudfang | installed (redone from a new board) | yes | yes | regenerated against an owner-supplied reference board; the earlier minor chest-seam artifact is gone in this generation |
| Cliffspike | installed | yes | yes | good |
| Tempestwing | installed | yes | yes | good — alpha catch, rig confirmed clean in-engine |
| Solmane | installed | yes | yes | legendary, confirmed clean in-engine at combat distance |
| **Galecrest** | **already installed** (Meadows wild roster) | yes (pre-existing) | yes (pre-existing) | reused, not regenerated |

## Stormwood (Biome 3)

| Species | Model | Rigged/animated | Wired in species.json | Notes |
|---|---|---|---|---|
| Voltwig | installed | yes | yes | zero-redo generation from the dedicated board |
| Glimmermoth | installed | **yes — fixed this pass** | yes | insect body plan (4 legs + 2 wings + 2 antennae) doesn't fit `rig_quadruped.py`'s leg-quadrant clustering, so it refuses outright; rigged instead with `rig_glider.py` directly on the mesh (0.1% unweighted, negligible), animated with the existing `animate_quadruped.py` (it already auto-detects a glider skeleton by bone name) |
| Stormbrush | installed | **yes — fixed this pass** | yes | bone-heat weighting failed 100% on the raw mesh; fixed via strip→clean→rig→skin-transfer (see below), needed the coarser `--voxel-divisor 110` where the default 220 still failed |
| Mosshock | installed | yes | yes | zero-redo |
| Staticub | installed | yes | yes | zero-redo |
| Tanglevolt | installed | **yes — fixed this pass** | yes | same failure mode and same fix chain as Stormbrush, converged at the default voxel divisor |
| Voltarach | installed | yes | yes | alpha catch, 8 legs — rigged and confirmed clean in-engine (see the Voltarach combat-distance frame) |
| Fulgocobra | installed | yes | yes | legendary, no legs — rigged anyway, confirmed clean |
| Stormraven | installed | yes | yes | good |
| **Sparkit** | **already installed** (Meadows creature-expansion roster) | yes (pre-existing) | yes (pre-existing) | reused, not regenerated |
| Thundertunnel | installed (redone from a new board, 4th generation) | **yes — fixed this pass** | yes | took 4 generations total: the first 3 attempts (including one from a corrected crop) still would not weight cleanly or kept producing a duplicated/fused second body; a 4th generation from a new owner-supplied board finally gave one coherent body, then the same strip→clean→rig→skin-transfer chain as Stormbrush (also needed `--voxel-divisor 110`) rigged it clean |

## Water Realm (Biome 4)

| Species | Model | Rigged/animated | Wired in species.json | Notes |
|---|---|---|---|---|
| Cannonback | installed | yes | yes | redone once to drop an unwanted tail and fix the cannon-barrel read |
| Riptusk | installed | yes | yes | redone once for colour/tusk prominence; confirmed working in-engine at exploration distance |
| Aquaryn | installed | **yes — fixed this pass** | yes | modelling itself succeeded after 2 redos (a crop bug fed the wrong section of the board, causing a floating leg then a multi-leg pileup); the corrected model then hit the same bone-heat failure as Stormbrush/Tanglevolt/Thundertunnel, fixed the same way (strip→clean→rig→skin-transfer) |
| Mirejaw | installed | yes | yes | redone once for the same crop bug (first attempt generated an unrelated rock/tree) |
| Torrentoad | installed | yes | yes | good |
| Cragclaw | installed | yes | yes | redone once to remove a floating claw fragment; 6+ legs rigged clean anyway |
| Riverdrake | installed | yes | yes | redone once to remove an unwanted rock pedestal |
| Sirenseal | installed | yes | yes | good — flippers rigged clean |
| Mangrove Monitor | installed | yes | yes | good |
| Abyssal Guardian | installed | yes | yes | legendary — confirmed clean and correctly scaled (towers over the 1.8m reference post) in-engine |
| **Mosshell** | **already installed** (Meadows wild roster) | yes (pre-existing) | yes (pre-existing) | reused, not regenerated |
| Tidecoil | installed | yes | yes | generated from the original crude reference crop (no dedicated board was ever supplied) and still came out clean; rigged with no issues |

## What "installed" and "rigged/animated" mean here, precisely

**Installed**: a Meshy `multi-image-to-3d` output (refine tier, textured) at
`assets/creatures/tetherbound/<species>/models/creature_<species>_lod0.glb`,
checked by rendering a 4-angle Blender turntable and comparing every angle
against the reference board.

**Rigged/animated**: run through the rig pipeline (see below for which
script) then `animate_quadruped.py` (procedural idle/walk/run/attack/hit/
faint clips baked into the glb), and verified two ways — a Blender turntable
render of the animated glb checked for tearing/corruption at the joints, and
for 3 representative species (Riptusk, Voltarach, Abyssal Guardian) a real
in-engine capture via `tools/validate_asset.gd` confirming the model loads
through `creature_body.gd`'s actual fit/scale pipeline rather than falling
back to the placeholder capsule. Every "yes" in the tables above passed the
first check; the three named above also passed the second.

**Every "yes" is also wired into `data/creatures/species.json`** — height,
radius, model path, and the animation clip mapping are all set, so these
species are spawnable in the game today. Combat stats (moves/HP/attack/
defence/catch rate) reuse the existing per-element move pool rather than
being individually balanced — placeholder-functional, not a tuned combat
profile. See each entry's `_comment_placeholder_stats`.

## Rigging: what the pipeline covers, and the bone-heat-weighting fix

`tools/art_pipeline/blender/rig_quadruped.py` turned out to handle far more
body plans than its own docstring claims — its leg-quadrant clustering
produced a clean, verified rig (0% unweighted vertices, confirmed sensible
in-engine) for actual quadrupeds, but also for Voltarach's 8 legs, Cragclaw's
6+-leg crab body, Aeriex/Fulgocobra/Tidecoil's legless serpent bodies, and
Tempestwing's dragonfly/Solmane's winged-lion silhouettes. It was not
guaranteed to work for any of these — the script's own guard exists
specifically to refuse rather than guess — so each one was verified
individually rather than assumed.

**Glimmermoth** needed a different rig script entirely: its compact insect
body (4 legs, 2 wings, 2 antennae) doesn't separate into 4 clean quadrant
clusters, so `rig_quadruped.py` refuses outright. `rig_glider.py` handled it
instead — succeeded directly on the real mesh at 0.1% unweighted, judged
negligible — and `animate_quadruped.py` already auto-detects a glider
skeleton by bone name, so no new animator script was needed.

**Aquaryn, Stormbrush, Tanglevolt and Thundertunnel** all hit the same
failure: `rig_quadruped.py` placed bones without erroring, but Blender's
bone-heat weight solver failed to converge on the raw Meshy retexture mesh —
100% of vertices left unweighted, which the script itself flags loudly
("these will tear in animation. Inspect before using."). This turned out to
be a mesh-quality problem, not a rigging-logic problem, and was fixed with
the same four-step chain for all four species:

1. **`strip_textures.py`** (new this pass, ad hoc but reusable) — removes
   `TEX_IMAGE` material nodes from a copy of the model, because
   `cleanup_mesh.py` refuses outright on any textured input ("carries image
   textures — refusing to voxel-remesh").
2. **`cleanup_mesh.py`** on the stripped copy — welds duplicate vertices,
   drops debris islands, and voxel-remeshes to one closed manifold surface.
   This is the strongest guarantee bone heat has to work with. Stormbrush
   and Thundertunnel's default `--voxel-divisor 220` still failed 100%
   unweighted; re-running at the coarser `--voxel-divisor 110` succeeded at
   0 unweighted for both. The working hypothesis is that dense fine surface
   detail (Stormbrush's spiky quill fur, Thundertunnel's dense fur) was too
   fine for heat diffusion to solve at the finer voxel size even on an
   otherwise-clean manifold mesh. Aquaryn and Tanglevolt converged at the
   default divisor with no retry needed.
3. **`rig_quadruped.py`** on the clean voxel-remeshed donor — heat weighting
   succeeds cleanly on this donor by construction (0 unweighted in every
   case), but the donor has lost its textures and UVs in step 2.
4. **`skin_transfer.py`** — brings the real textured mesh into the same
   file as the rigged donor and copies vertex weights across by
   nearest-face interpolation (the two meshes are the same shape to within
   the retexture's remeshing noise, so this is exact for practical
   purposes), then discards the donor. The real textured mesh inherits the
   armature at 0 unweighted vertices after transfer.

All four were then run through `animate_quadruped.py` and verified with a
turntable render of the *animated* glb (checked for tearing/corruption at
the joints, not just static shading) before being copied into the tracked
repo path and wired into `species.json`.

**Process note, so it isn't repeated:** the first pass at installing the
Craghorn/Stormcapra/Cloudfang board-redos copied the raw Meshy
`multi-image-to-3d` output straight into the tracked model path, silently
overwriting the already-rigged-and-animated files that were there before —
a raw Meshy output has a mesh and a material but no armature at all, so
this would have shipped those three species with no `AnimationPlayer`.
Caught by loading the result through Godot directly (`art.find_children("*",
"AnimationPlayer", true, false)` came back empty) rather than trusting the
copy step, then fixed by running all three through `rig_quadruped.py` (all
converged clean, 0 unweighted vertices, straight off the raw redo mesh — no
cleanup pass needed for these three) and `animate_quadruped.py` before
re-installing. **A regenerated model is not "installed" until it has been
rigged and animated again — a board redo throws away the previous
generation's rig along with its mesh.**

A second thing this surfaced: Godot's runtime resource loader does not
reimport a `.glb` just because the file on disk changed underneath it — it
trusts the cached `.godot/imported/*.scn` from whenever the project was
last opened in the editor, so a model swapped in by copying a new file over
an old tracked path keeps rendering (and animating, or failing to animate)
the *previous* file's imported scene until something forces a reimport.
`godot --headless --import --path .` (a real command-line flag, not
`--check-only`, which does not open the editor's asset pipeline at all)
does that reimport pass without opening a window, and is now the standard
last step any time a tracked `.glb` is replaced in place — run once after
all model copies for a session are done, then re-verify.

Humans go through Meshy's own auto-rigger (`meshy.py rig`), documented
humanoid-only, then `animate_humanoid.py` for clips — confirmed working on
Kael and Sera this pass.

## Main character choices (not biome-specific)

Lyra, Kael and Sera are three alternate playable-character options, generated
from `docs/art/reference/23-25`, sitting outside the biome rosters above.
Kael and Sera are rigged, animated, and wired into `data/config/art.json`
under their own keys (`kael`, `sera`) — picking them on the title screen's
character-select step actually swaps the player's in-game body.

**Lyra's rig is fixed.** The first two generations both failed Meshy's
humanoid auto-rigger with "Pose estimation failed" because her arms sat
close enough to her torso that the pose estimator could not read the
shoulder/elbow joints. The first fix attempt tried prompt text alone
("BOTH ARMS HELD CLEARLY AWAY FROM THE TORSO...") and still failed
identically — a rendered turntable of that regeneration confirmed why: her
arms were still close to her sides, matching this project's established
lesson that the reference image's actual drawn pose overrides prompt text in
image-to-3D reconstruction. The fix that actually worked was a new
owner-supplied reference board whose front/3-quarter/side/back turnaround
genuinely draws her arms away from her torso — a real pose change in the
source pixels, not a reworded prompt. Cropped into the usual
front/side/back/three_quarter set (the old face-closeup `head.png` was
retired to stay under Meshy's 4-image cap; the four full-body views matter
more for a pose fix than a face crop does), regenerated, and the auto-rig
succeeded on the first attempt this time: a real 24-bone humanoid skeleton
(hips/spine chain, both arms, both legs, neck/head), confirmed via a
Blender turntable of both the raw rig and the animated result (clean
skinning, no tearing at the joints). Animated with the same
`animate_humanoid.py` pass as Kael/Sera/the trainer (idle/walk/sprint/jump/
throw/chop, identical clip names), installed at
`assets/characters/lyra/lyra_lod0.glb`, and wired into `data/config/art.json`
under a `lyra` key. Picking her on the title screen's character-select step
now builds her real body instead of falling back to the trainer — confirmed
by loading `art.json`'s `lyra` entry straight through Godot's resource
loader and checking the `AnimationPlayer` resolves all six clip names, the
same check used for every creature in this document.
