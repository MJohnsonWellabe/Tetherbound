# Cause lane: Cloudreach cliffs, clouds, light and meadow (tb/cause-cloudreach)

## Status (1 Nov 2026, round 1, group 1)

**For the GPU queue:** one arm, `data/config/cloudreach_cause.json:enabled` (the master switch turns on all four parts). `MANIFEST.json` lists every F40 world-view item whose frames it changes: 15 items, 23 camera entries. Each part also has its own `<part>.enabled` key, for a per-part arm if the combined arm gains and attribution is wanted.

**Not captured on CPU.** This container's disk allowance is spent (about 0.9 GB free; `.git` alone is 20.5 GB), so `godot --import` cannot run and no capture can render. Nothing has been checked on screen yet. What was checked:
- Godot 4.7 `--check-only` parse of the new scripts and the test, using the TECHNICAL §8.1 disk-tight recipe.
- `tests/test_cloudreach_cause.gd`: 11/11 pass headless, run in a throwaway copy with the asset preloads stubbed (the real file needs an imported tree; CI's import covers it).
- The edits to `cloudreach_world.gd`, `cloudreach_look.gd`, `world_look.gd` and `cloudreach_settlement_life.gd` were reviewed by diff only. They cannot be parse-checked without an import.

**First GPU look should check:** stone too pale or reading as ice/sugar (an F08#3 failure mode); course-surface shimmer at distance; whether the cloud deck at 130 m below the tier reads as a cloud sea or as fog; and whether grove trees land inside any landmark composition.

## What each part does (all OFF)

| Part | Judge theme it answers | Change |
|---|---|---|
| `pale_strata` | "huge flat untextured brown cliff masses"; "rusty ruined pillars clash with the pale stone" | Pale warm-grey geology palette (cliffs, crown banks, rock sections, buttresses, distant spires). Turns on the existing F26 course surface (metre-scale beds, desaturated Rock030 grain; shader globals, Compatibility-safe). Retints the rusty `stone` (#906955) and `stone_light` materials. Installed boulders move onto the shared geology. |
| `cloud_sea` | "cloud banks standing on the grass horizon like cards" | A settlement cloud card whose footprint meets walkable ground is pushed out from its ring centre over open air and dropped below the rim. A card with no open air within 640 m is hidden; cards over open air are unchanged. The cloud deck rises (130 m below the tier, was 190 m; upper deck offset 45 m, was 100 m) and is lit pale with a cool base. |
| `light_grade` | "flat noon light" | Day: sun lower and warmer (pitch -34°, energy 1.65), deeper zenith, pale horizon, cooler ambient, contrast 1.08, aerial haze (fog 0.0008, aerial 0.85). Golden and dawn get the same haze. Night unchanged. |
| `meadow_groves` | "uniform grass carpet of identical blades" | A world field with about 90 m features sorts the turf. Clearings get short, thinner grass. Grove cores get clumps of installed CommonTree and Bush pieces, with longer grass at the fringe. A second field places Rock_Medium outcrops and clears the grass under them. Routes (6 m), settlements, landmark vistas and exclusions stay clear. Caps: 260 groves and 200 outcrops. One pass over the tuft buffers at build. |

Composes with other lanes: it merges last over `cloudreach_visual.json`, the F40 visual/items overlays and settlement life. The light overrides apply after the light candidate. The cloud and meadow passes run after grounding and paved-grass. Preview without editing the config: `--cloudreach-cause-candidate`, or `--cloudreach-cause-<part>`.

## Files

- `data/config/cloudreach_cause.json` (new): the flags and every tunable.
- `scripts/world/cloudreach_cause.gd` (new): overlays, material retint, cloud-card reseat.
- `scripts/world/cloudreach_meadow_groves.gd` (new): the meadow pass.
- `tests/test_cloudreach_cause.gd` (new): with every flag off nothing changes; with each flag on its keys are applied; cloud-card reseat; tuft-buffer edit.
- Small hooks: `cloudreach_world.gd` (visual overlay, light overrides, stone retint, boulder palette route), `cloudreach_look.gd` (cloud and meadow passes at the end of `dress`), `world_look.gd` (course surface on under pale_strata), `cloudreach_settlement_life.gd` (each cloud card records its ring centre).

## Next

- A container with disk for an import should take one CPU capture per part at the realm gate and the sky shrine approach, to check visibility and look for clipping or black frames.
- If `pale_strata` reads as too white on the GPU, the tunables are `stone_light`/`stone_dark` and `materials.*` in the config, with no code change.
