# Runtime metallic check (GPU, Forward+ Medium, main a4f8a6b7b, 22 Oct 2026, evening)

**Result: no visible win here. The file-level metallic-1.0 default is already corrected at load for characters and nature, and nothing in the rendered Meadows scene draws as full metal.**

## What the game actually renders

A local probe ran during the Meadows location capture (`--biome=meadows --subset=band1 --times=day --views=approach`, Medium, 1920x1080, GTX 1060). Every 300 frames it dumped the material bound for rendering on every visible GeometryInstance3D, grouped by source asset.

| Source | Rendered material (Forward+) | Instances |
|---|---|---|
| `assets/characters/trainer/trainer_lod0.glb`; the file has factor 1.0 (default) and no texture | StandardMaterial3D, **metallic 0.00**, roughness 1.00, no metallic texture | 1 |
| Creatures: bramblebun, brooktail, mudsnout, paddlenewt, pipwing, trailpup | metallic 1.00 **with a bound metallic texture**, so the texture's blue channel sets it; the audit puts creature blue means at 0.00–0.40 | 2–27 each |
| Creatures: galecrest, meadowhart native | metallic 0.00 | 83 / 2 |
| Scatter and vegetation, built at runtime | StandardMaterial3D, metallic 0.00, roughness 0.94 | 10,048 |
| Foliage | ShaderMaterial `foliage_camera_visibility.gdshader` | 8,320 |
| **Any material with metallic ≥ 0.9 and no metallic texture** | **none** | 0 |

## Why the file-level flags are moot

- **Characters:** `scripts/characters/character_model.gd` (around line 615) sets `material.metallic = 0.0` exactly when a rig's material carries the absent-default factor with no metallic texture. Its comment names this same glTF default. Rank badges that ask for metal go through the `finish` branch.
- **Nature and props:** `scripts/world/imported_materials.gd::make_dielectric()` does the same as a surface override. It is called from 17 scripts, including `props.gd` and `ironwood_grove_presentation.gd`. Two direct loaders do not call it, and both replace the material themselves:
  - `kit_effect.gd`: the rocks get `material_override`;
  - `felled_resource.gd`: the logs get `_paint_wood`.

## Matched frame, metallic forced to 0 (to double-check)

The same capture was re-run with every rendered BaseMaterial3D that is ≥ 0.9 and untextured forced to metallic 0. The probe found none to change.

| Frame (upper two-thirds) | Shipped luma | Metallic-0 luma |
|---|---|---|
| grandpas_village day approach | 109.04 | 109.22 |
| the_south_bridge day approach | 86.99 | 87.00 |
| band1_trail_camp day approach | 65.14 | 65.23 |

The differences are capture noise of 0.2 luma or less.

## Scope and caveats

- This is one realm and one route. Villagers and Meadows buildings did not fall inside the dump window: the buildings are built at runtime, and no villager was within the probe's visible set at the dump frames. The character-model code path covers every rig regardless.
- Another realm or tool that instantiates a flagged GLB without one of the paths above would still draw it as metal. `meshy-metallic-audit.txt` lists the candidate files.

## Files

- This note, plus `meshy-metallic-audit-runtime-probe.gd.txt` (the local probe). Its logs stay local.
