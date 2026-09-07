# Biomes 2-4 creature roster — current status

**Status:** Current, 2026-09-07. Companion to `docs/art/HUMANOID_ASSET_INVENTORY.md`
(that file is the human/character source of truth; this one is the creature
source of truth for Cloudreach Cliffs, Stormwood and the Water Realm).

This is the map from "a creature exists as a `.glb`" to "which biome it
belongs to and what pipeline stage it is at." Read this before generating,
rigging, or wiring any of these species — it says what is already done so
that work is not repeated or contradicted.

Reference boards for every species named below are under
`docs/art/reference/` (numbered 22 onward). Prompts and negative-prompt
overrides live in `tools/art_pipeline/meshy.py`'s `SPECIES_PROMPTS` dict.

## Cloudreach Cliffs (Biome 2)

| Species | Model | Rigged/animated | Notes |
|---|---|---|---|
| Pebbik | installed | no | good |
| Craghorn | installed | no | usable, softer texture than the rest of the batch |
| Stormcapra | installed | no | usable, softer texture |
| Skyrill | installed | no | good |
| Aeriex | installed | no | good, no legs (flying serpent) |
| Ribbonray | **not installed** | — | two generations, both wrong: no wings, wrong head shape. Needs a fresh look, not a third blind retry |
| Breezetail | installed | no | good |
| Cloudfang | installed | no | usable, softer texture, minor chest-seam artifact |
| Cliffspike | installed | no | good |
| Tempestwing | installed | no | good — alpha catch |
| Solmane | installed | no | usable — legendary, wings read a little folded/small versus the board's spread pose |
| **Galecrest** | **already installed** (Meadows wild roster) | **yes** | reused, not regenerated — large hawk fits the Cliffs sky theme; the missing "#01" slot on the original board |

## Stormwood (Biome 3)

| Species | Model | Rigged/animated | Notes |
|---|---|---|---|
| Voltwig | installed | no | generated from the dedicated board's own "Model Notes for Meshy"; pending visual-judge pass |
| Glimmermoth | installed | no | pending visual-judge pass |
| Stormbrush | installed | no | pending visual-judge pass |
| Mosshock | installed | no | pending visual-judge pass |
| Staticub | installed | no | pending visual-judge pass |
| Tanglevolt | installed | no | pending visual-judge pass |
| Voltarach | installed | no | alpha catch, 8 legs; pending visual-judge pass |
| Fulgocobra | installed | no | legendary, no legs; pending visual-judge pass |
| Stormraven | installed | no | pending visual-judge pass |
| **Sparkit** | **already installed** (Meadows creature-expansion roster) | **yes** | reused, not regenerated — electric fox-coyote already fits Stormwood exactly |
| Thundertunnel | **no dedicated board yet** | — | only the old crude shared-sheet crop exists; still a gap |

## Water Realm (Biome 4)

| Species | Model | Rigged/animated | Notes |
|---|---|---|---|
| Cannonback | installed | no | good — redone once to drop an unwanted tail and fix the cannon-barrel read |
| Riptusk | installed | no | good — redone once for colour/tusk prominence |
| Aquaryn | installed | no | good — redone once; first two attempts had a floating leg then a multi-leg pileup, both traced to a crop bug feeding the wrong section of the board |
| Mirejaw | installed | no | good — redone once for the same crop bug (first attempt generated an unrelated rock/tree) |
| Torrentoad | installed | no | good |
| Cragclaw | installed | no | good — redone once to remove a floating claw fragment |
| Riverdrake | installed | no | good — redone once to remove an unwanted rock pedestal |
| Sirenseal | installed | no | good |
| Mangrove Monitor | installed | no | good |
| Abyssal Guardian | installed | no | good — legendary |
| **Mosshell** | **already installed** (Meadows wild roster) | **yes** | reused, not regenerated — the pond turtle already fits Water Realm; the missing "#11" slot |
| Tidecoil | **no dedicated board yet** | — | only the old crude shared-sheet crop exists; still a gap |

## What "installed" means here, precisely

Every "installed" model above is a raw Meshy `multi-image-to-3d` output at
`assets/creatures/tetherbound/<species>/models/creature_<species>_lod0.glb`:
textured, **unrigged, unanimated, and not wired into
`data/creatures/species.json`**. It has been checked by rendering a 4-angle
Blender turntable (`tools/art_pipeline/blender/turntable.py`) and comparing
every angle against the reference board — not by eyeballing Meshy's flat
thumbnail, which this pass found hides real defects (extra/floating limbs,
wrong colour, wrong subject entirely).

## Rigging: what the existing pipeline actually covers

`tools/art_pipeline/blender/` has five rig scripts, each for a specific body
plan, all working from the mesh's own geometry (no hand-placed bones):

- `rig_quadruped.py` — standard four-legged stance (mammals, lizards). Refuses
  outright if the leg-quadrant clustering doesn't separate cleanly, which is
  its explicit guard against silently rigging a body plan it wasn't built for.
- `rig_glider.py` — two legs + wing-forelimbs + tail (Galewisp's shape).
- `rig_bird.py`, `rig_sitter.py` — see their own docstrings.
- Humans go through Meshy's own auto-rigger (`meshy.py rig`), which is
  humanoid-only but works well — confirmed this pass on Kael and Sera.

**Not covered by any existing script:** Voltarach (8 legs), Cragclaw and
Mosshell-style crabs/turtles with a shell silhouette the quadrupled clustering
doesn't match, Fulgocobra/Tidecoil-style legless serpents, Glimmermoth/
Tempestwing-style insects, and Cliffspike/Pebbik-style ball-shaped bodies. Any
of these needs either a new placement script (same philosophy: measure, place,
refuse rather than guess) or manual Blender rigging before it can be
animated — do not assume `rig_quadruped.py` will produce a correct skeleton
for one of these just because it runs without erroring.

## Main character choices (not biome-specific)

Lyra, Kael and Sera are three alternate playable-character options, generated
from `docs/art/reference/23-25`, sitting outside the biome rosters above.
Kael and Sera are rigged and animated (Meshy auto-rig + procedural clips via
`animate_humanoid.py`, same as the trainer). **Lyra's rig fails outright**
("Pose estimation failed") — her arms sit close enough to her torso that
Meshy's pose estimator can't read the joints. This does not block using her
portrait art in a selection UI; it blocks giving her an in-game rigged body
without a pose-corrected regeneration.
