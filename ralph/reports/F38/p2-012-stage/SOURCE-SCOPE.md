# P2-012 source scope and evidence boundary

Status: source audit only; no runtime source or terrain geometry changed. The blind baseline supports an exposed brown face with straight rectangular edges and a broad ramp beside a dark entrance cut. It does not establish collision, walkability, or whether the shape is an intentional retaining structure. Catalog status remains open at impact 32.

## What the pinned source already builds

At `06bedfa5082e6ea5dd425c9fc04ffd1d5ace84eb`, `data/config/burrow_warrens.json` sites the entrance at `[-357, 2610]`, yaw `315°`, and defines an 8 m approach apron. Its width tapers from 8.0 m at the mouth to 4.6 m at the far end. The color is `#4a3a2c`. `scripts/world/burrow_warrens.gd::_build_approach_apron()` builds the continuous exterior ramp surface and its walkable substrate; its exterior material uses the existing Ground030 worn-path texture. Existing comments identify prior EXT-05/EXT-06 changes for the pale apron and too-short dark-soil apron. That history makes an unmeasured geometry or texture retune especially likely to repeat an already tried fix.

This identifies a plausible source surface for the observed ramp. It does not prove that the blind frame's brown rectangle is this apron, a terrain face, or a collision surface. Leave geometry, collision, player stand, and the cave mouth unchanged until the exact route frames identify the rendered feature.

## Exact evidence still required

The current audit has no High or Medium receipts for either exact sighting:

- `meadows__band2_stone_and_root__04__the_burrow_warrens__walk_02_day`
- `meadows__band2_stone_and_root__04__the_burrow_warrens__walk_03_day`

The existing `tools/capture_warrens_63.gd` is a separate camera recipe. It waits 240 physics frames and generates named Warrens presentation views, but it does not emit either requested catalog ID and is not a substitute. The general Phase 2 location capture emits the named debug-teleport landmark, but not the two `walk_02` / `walk_03` route IDs. Their source camera/stand definitions have not been found in the pinned live capture path. Preserve the row as open until those exact camera definitions and matched High/Medium frames are available.

## Source pins

Git blob IDs are exact pins under the frozen commit, not SHA-256 hashes.

| File | Git blob |
| --- | --- |
| `data/config/burrow_warrens.json` | `9f8f57bd9ca58822b72ccf34b07328308db4da35` |
| `scripts/world/burrow_warrens.gd` | `81ab3c7d8425cee68e700cc6df0dbc9dba2a550e` |
| `tools/capture_warrens_63.gd` | `c181ae9bdc73cc65a385a2cd6ab9355f34c464d3` |
| `assets/environment/terrain/Ground030_Color.jpg` | `a7899ea0794e7660ac036345b96db8fa7ec62905` |
| `assets/environment/terrain/Ground030_NormalGL.jpg` | `4a6ba7bc626f2c668d55e28eaacbdc6a9a829363` |
| `shaders/warrens_boulder_stain.gdshader` | `5a0e3122ff0b958d5ba534b9ec65aba98d480d54` |
| `data/config/terrain_playground.json` | `fb2804d8f388c59a746e84bd534465d6b02745e8` |

No rescore, numeric impact change, or source candidate follows from this audit.
