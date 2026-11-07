STATUS: parked
BRANCH: tb/item-f40-1  HEAD: b49392480afd0ddcee1ea70e546e40d7db6fd7a1 (READY committed in the next commit)

# F40#1 P2-021 Cloudreach open terrain: stone shelves (LANE-CR, 7 Nov 2026, Blender row)

Row F40#1 P2-021. Live 5.29 GPU / 5.86 CPU (VIS-CLOUDREACH stone trail ON). This lane: no judged gain; nothing turned ON.

## New art (Blender, flag OFF)
- **`assets/props/lanecr-1107/cloudreach_strata_terrace/`** (r1): three stepped tiers of pale banded strata with a moss lip. Native 11.2 x 5.4 x 2.55 m.
- **`assets/props/lanecr-1107/cloudreach_strata_landform/`** (r2): four uneven, rougher tiers climbing to one side, with lawn-matched turf tops. Native 16.1 x 9.4 x 5.7 m.
- Both are procedural Blender meshes.
  - Script: `blender/strata_terrace.py` (variants r1/r2).
  - Textures: `blender/strata_textures.py`, procedural numpy. Embedded in the GLB, extracted by Godot, with VRAM import policy applied (check PASS).
  - Scale checks: `blender/_strata_*_scale_check.jpg`, next to a 1.80 m trainer cylinder.
  - Provenance: `provenance.json` in each asset dir.
  - No Meshy, no third-party mesh.
- Wiring: the `strata_terrace` and `strata_landform` keys in `scripts/world/cloudreach_settlement_life.gd` PROPS.

## Rounds (CPU llvmpipe, Compatibility, quick_judge, three code-blind judges)
- **r1 `qj/F40-1-r1`: `cloudreach_f40_items.json` candidates[12] `--cloudreach-f40-strata-terrace-candidate`.**
  - Arm: three terraces on the three scored stands.
  - Mapped 6.17 -> **6.03 (-0.14, flat)**. Raw base 4.9 / 5.7 / 5.4, candidate 4.8 / 5.6 / 5.2. RMSE 0.724.
  - Judges: "stone staircases / flat slabs pasted on the grass"; the defect is PRESENT on both sides. Stays OFF.
  - A pre-judge self-look caught two problems, both fixed before judging:
    - The first texture build read near-white; values were matched to the installed cliffs.
    - The `shrine_walk_a` stand put a terrace 2.8 m from the heartstone camera; that stand was dropped.
- **r2: candidates[13] `--cloudreach-f40-strata-landform-candidate`. Captured, not judged.**
  - The larger landform, placed 5–6 m tall at 11 m and 18 m.
  - In engine it lands low: `_ground` seats each piece where the island falls toward its rim, so it reads like r1's low slabs against the backdrop cliffs. It was not visible at all in the sky-shrine close frame.
  - Parked under the "an approach that fails twice is parked" rule; the same family was also judged -0.73 on F40#2 (scattered stone at the summit stand).

## Flags
- ON: none.
- OFF, left in the tree: `cloudreach_f40_items.json` candidates[12] (r1, flat) and candidates[13] (r2, not judged).
- The assets stay installed for a later idea.

## Tests
None: no flag turned ON. JSON parse checked; texture import policy check PASS on the new assets.

## Files touched
- `assets/props/lanecr-1107/**`
- `data/config/cloudreach_f40_items.json` (two OFF candidates appended)
- `scripts/world/cloudreach_settlement_life.gd` (two PROPS keys)
- `ralph/reports/LANES/ITEM-F40-1/**`

## Judges' remaining asks (r1, unanimous)
- Layered elevated land and ledges that lead the route: the route should climb them, not pass beside them.
- Hide the frame-2 terrain disc edge, the brown soil skirt across the foreground of the gate approach, which reads as a test tile.
- Replace the uniform, generator-looking rubble pad under the trainer: the ON stone-trail candidates[0] paving reads as a blob of same-size rocks.
- Clump the grass and add depth fog between cliff tiers.

## Next idea
- Not stand dressing. The terrain itself has to rise: a terrace edit to the island heightfield along the route, or `cloudreach_world.gd` mesa tiers.
- Retexture the island rim skirt as pale strata (`_build_articulated_settlement_skirt` / mesa skirt material).
- Try the stone-trail pad OFF as its own A/B; three judges in r1 called it generator output.
