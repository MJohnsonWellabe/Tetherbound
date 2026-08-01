# TETHERBOUND — Asset Policy and Sourcing

## The rule

**CC0 or public domain only.** No CC-BY, no CC-BY-SA, no "free for non-commercial", no asset store freebies with custom EULAs, no AI-generated models from services with unclear terms. If the license is ambiguous, the answer is no.

Every asset that enters `public/` gets a row in `ASSET_MANIFEST.md` before it is committed:

| File | Source URL | Author | License | Date pulled | Modified? |
|---|---|---|---|---|---|

No row, no commit.

## Approved sources

Pull from these first. All are reliably CC0.

| Source | Best for | Notes |
|---|---|---|
| **Kenney.nl** | Nature Kit, Survival Kit, Platformer Kit, UI Pack, Audio packs, Prototype textures | Everything Kenney publishes is CC0. This is the workhorse. |
| **Quaternius** | Ultimate Nature Pack, Animated Animals, RPG Characters, Modular buildings | CC0. Rigged and animated animals are the pal backbone. |
| **Poly Pizza** | Odd one-off props | Filter to CC0 explicitly. The site hosts CC-BY too. Check every download. |
| **ambientCG** | Ground, rock, wood, thatch PBR textures | CC0. Grab 1K, not 4K. |
| **OpenGameArt** | Filler props, tiling textures | Filter to CC0 only. Verify per asset, the site is mixed license. |
| **Freesound** | SFX | Filter to CC0. Verify per file. |
| **Kenney Audio / Sonniss GDC bundles** | Ambience, UI clicks | Sonniss bundles are royalty free for commercial use. Read the year's terms. |
| **Google Fonts (OFL)** | Typography | OFL is fine for embedding. |

## Art direction

Low-poly, flat-shaded, saturated. Chunky silhouettes that read at phone size. Think Kenney's Nature Kit as the baseline and match everything to it. Consistency of style beats fidelity of any single asset.

- Palette: warm meadow greens and golds, desaturated stone greys, a single hot accent (Tether iron-orange) reserved for enemies and danger.
- No normal maps in v0.1. Flat color plus vertex tint plus a single directional light.
- Outline shader is optional and only if it costs under 2ms.

## Pal model strategy

Fifteen species is too many unique models for a fast first build. Do this instead:

1. Pull **six** rigged animal base models from Quaternius Animated Animals (something quadruped, something bird-like, something amphibian, something small mammal, something horned, something bulky).
2. Generate species variants with **material tint, scale, and one attached accessory prop** (horn, crest, tail plume, moss patch, spark ring).
3. Map each of the 15 Meadows species to a `baseModel + tint + scale + accessory` combo in `species.json`.

This gets a full visible roster with six downloads. Replace with unique models later, one at a time, without touching any gameplay code, because the mapping is data.

Required animations per base model: `idle`, `walk`, `run`, `attack`, `hit`, `faint`. If a downloaded model is missing one, reuse the nearest and log it in the manifest.

## Required asset list for v0.1

**Terrain and props:** grass texture, dirt path, rock face, 3 tree variants, 2 bush variants, 4 rock variants, 3 flower variants, tall grass tuft, reeds, standing stone, fallen log.

**Building pieces:** wood floor, wall, half wall, doorway, door, window wall, roof 26°, roof 45°, stair, pole, beam, ladder, plus stone floor, wall, arch, pillar, stair. Kenney's building kits cover most of this. Anything missing gets built from primitives in code, which is acceptable and fast.

**Structures:** campfire, workbench, bed, tanning rack, orb bench, village houses (3 variants), the Hall exterior and interior shell.

**Characters:** player (one model, no customization in v0.1), Grandpa Orin, 2 villagers, Tether grunt, Bracken Holt. Retexture one humanoid base for all of them.

**VFX:** hit spark, capture beam, orb shake, faint puff, charge glow, tether snap. All shader or sprite based, no imported VFX.

**Audio:** footsteps on grass and stone, axe chop, pick strike, place piece, orb throw, orb click x3, catch success, catch fail, quick hit, power hit, faint, level up, ambient day loop, ambient night loop, combat sting, victory sting, UI click, UI back.

## Pipeline

1. Download to `assets_raw/` which is **gitignored**.
2. Convert: `gltf-transform` for Draco compression and texture resize. Target under 300 KB per model.
3. Output to `public/models/`.
4. Add the manifest row.
5. Commit.

Ship a `scripts/optimize-assets.sh` that runs step 2 across `assets_raw/`.

## Placeholder policy

Milestone 0 and 1 use colored primitives. A pal is a capsule with a tinted sphere head. A tree is a cylinder and a cone. This is correct and expected. Do not spend a day sourcing models before the character controller feels good on a phone.
