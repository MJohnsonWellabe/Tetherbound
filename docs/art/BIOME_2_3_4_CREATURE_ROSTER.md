# Biomes 2-4 creature roster — current status

**Status:** Current, 2026-09-07 (final pass — rigged, animated, and wired into
`data/creatures/species.json` for everything that could be). Companion to
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
| Craghorn | installed | yes | yes | usable, softer texture than the rest of the batch |
| Stormcapra | installed | yes | yes | usable, softer texture |
| Skyrill | installed | yes | yes | good |
| Aeriex | installed | yes | yes | good, no legs (flying serpent) — rigged anyway, confirmed clean |
| Ribbonray | installed | yes | yes | fixed on the 3rd generation (explicit "wings are the largest feature" + "one bird head, not a fin" language); rigged clean |
| Breezetail | installed | yes | yes | good |
| Cloudfang | installed | yes | yes | usable, softer texture, minor chest-seam artifact |
| Cliffspike | installed | yes | yes | good |
| Tempestwing | installed | yes | yes | good — alpha catch, rig confirmed clean in-engine |
| Solmane | installed | yes | yes | legendary, confirmed clean in-engine at combat distance |
| **Galecrest** | **already installed** (Meadows wild roster) | yes (pre-existing) | yes (pre-existing) | reused, not regenerated |

## Stormwood (Biome 3)

| Species | Model | Rigged/animated | Wired in species.json | Notes |
|---|---|---|---|---|
| Voltwig | installed | yes | yes | zero-redo generation from the dedicated board |
| Glimmermoth | installed | **no — rig refused** | no | insect body plan (4 legs + 2 wings + 2 antennae) doesn't fit `rig_quadruped`'s leg-quadrant clustering; needs a new rig script or manual rigging |
| Stormbrush | installed | **no — bone-heat weighting failed (100% unweighted)** | no | rig placed but the automatic weights didn't take; needs another rig attempt or a cleanup pass first |
| Mosshock | installed | yes | yes | zero-redo |
| Staticub | installed | yes | yes | zero-redo |
| Tanglevolt | installed | **no — bone-heat weighting failed (100% unweighted)** | no | same failure mode as Stormbrush |
| Voltarach | installed | yes | yes | alpha catch, 8 legs — rigged and confirmed clean in-engine (see the Voltarach combat-distance frame) |
| Fulgocobra | installed | yes | yes | legendary, no legs — rigged anyway, confirmed clean |
| Stormraven | installed | yes | yes | good |
| **Sparkit** | **already installed** (Meadows creature-expansion roster) | yes (pre-existing) | yes (pre-existing) | reused, not regenerated |
| Thundertunnel | installed | **no — bone-heat weighting failed (100% unweighted)** | no | took 3 generations to get a single coherent body (the first 2 attempts produced a duplicated/fused second body, traced to the crude reference crop containing the whole multi-mole turnaround panel rather than one isolated creature — fixed by cropping just the hero image). The corrected model still won't weight cleanly; needs another rig attempt |

## Water Realm (Biome 4)

| Species | Model | Rigged/animated | Wired in species.json | Notes |
|---|---|---|---|---|
| Cannonback | installed | yes | yes | redone once to drop an unwanted tail and fix the cannon-barrel read |
| Riptusk | installed | yes | yes | redone once for colour/tusk prominence; confirmed working in-engine at exploration distance |
| Aquaryn | installed | **no — bone-heat weighting failed (100% unweighted)** | no | modelling itself succeeded after 2 redos (a crop bug fed the wrong section of the board, causing a floating leg then a multi-leg pileup); the corrected model still won't weight cleanly |
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

**Rigged/animated**: run through `rig_quadruped.py` (bone placement from the
mesh's own geometry, automatic weight painting) then `animate_quadruped.py`
(procedural idle/walk/run/attack/hit/faint clips baked into the glb), and
verified two ways — a Blender turntable render of the animated glb checked
for tearing/corruption at the joints, and for 3 representative species
(Riptusk, Voltarach, Abyssal Guardian) a real in-engine capture via
`tools/validate_asset.gd` confirming the model loads through
`creature_body.gd`'s actual fit/scale pipeline rather than falling back to
the placeholder capsule. Every "yes" in the tables above passed the first
check; the three named above also passed the second.

**Every "yes" is also wired into `data/creatures/species.json`** — height,
radius, model path, and the animation clip mapping are all set, so these
species are spawnable in the game today. Combat stats (moves/HP/attack/
defence/catch rate) reuse the existing per-element move pool rather than
being individually balanced — placeholder-functional, not a tuned combat
profile. See each entry's `_comment_placeholder_stats`.

## Rigging: what the existing pipeline actually covers, and what it doesn't

`tools/art_pipeline/blender/rig_quadruped.py` turned out to handle far more
body plans than its own docstring claims — its leg-quadrant clustering
produced a clean, verified rig (0% unweighted vertices, confirmed sensible
in-engine) for actual quadrupeds, but also for Voltarach's 8 legs, Cragclaw's
6+-leg crab body, Aeriex/Fulgocobra/Tidecoil's legless serpent bodies, and
Tempestwing's dragonfly/Solmane's winged-lion silhouettes. It was not
guaranteed to work for any of these — the script's own guard exists
specifically to refuse rather than guess — so each one was verified
individually rather than assumed.

**Genuinely not covered, four species:**

- **Glimmermoth** — `rig_quadruped.py` refuses outright (compact insect body,
  legs don't separate into 4 clean quadrant clusters). Needs a purpose-built
  rig script (same philosophy as `rig_glider.py`/`rig_bird.py`: measure,
  place, refuse rather than guess) or manual Blender rigging.
- **Aquaryn, Stormbrush, Tanglevolt, Thundertunnel** — the rig itself placed
  bones without erroring, but Blender's bone-heat weight solver failed to
  converge (100% of vertices left unweighted, which the script itself flags
  loudly: "these will tear in animation. Inspect before using."). These four
  are genuinely modelled and reviewed clean, just not yet rigged. A repeat
  attempt, a mesh cleanup pass first (`cleanup_mesh.py`), or manual weight
  painting are the likely next steps — this is a real, separate follow-on
  task, not a same-session fix.

Humans go through Meshy's own auto-rigger (`meshy.py rig`), documented
humanoid-only, then `animate_humanoid.py` for clips — confirmed working on
Kael and Sera this pass.

## Main character choices (not biome-specific)

Lyra, Kael and Sera are three alternate playable-character options, generated
from `docs/art/reference/23-25`, sitting outside the biome rosters above.
Kael and Sera are rigged, animated, and wired into `data/config/art.json`
under their own keys (`kael`, `sera`) — picking them on the title screen's
character-select step actually swaps the player's in-game body. **Lyra's rig
fails outright** ("Pose estimation failed") — her arms sit close enough to
her torso that Meshy's pose estimator can't read the joints. This does not
block using her portrait art in the selection UI; picking her currently
falls back to the trainer body. Fixing this needs a pose-corrected
regeneration, not another rig attempt on the same mesh.
