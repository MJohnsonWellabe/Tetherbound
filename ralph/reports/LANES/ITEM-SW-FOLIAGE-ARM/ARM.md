# Stormwood foliage grade: config-only arm (existing flag, never GPU-judged)

**Overlay:** `overlay_foliage_grade_on.json`. It sets `data/config/stormwood_look.json` `foliage_grade_1104.enabled` to true; nothing else changes.
**Capture:** live main vs arm at High, on:
- F41#5 (forest ground and distance layers)
- F41#8 (named character silhouettes; judges cite the foliage there)
- F41#3 (named wild fight)

## Defect (GPU, repeated)

GPU judges keep naming flat, saturated cartoon green that does not match the board's cool blue-green moss forest:
- G-f41-8 Uv: "flat saturated green with a cartoon finish, not the board's blue-green moss" (judge c); "flat cartoon pink-brown bark" (judge b).
- The Stormwood frames in G-occlusion-fade-off-wide.

## What the flag does

`foliage_grade_1104` (VIS-STORMWOOD, 4 Nov) is already in the build, OFF. `vegetation.gd` `stormwood_foliage_grade` does two things:
- **Per-model tints:** canopies cooler and about a quarter darker; giant trees from #d8c8ae to #9fb0a8; ferns and bushes follow.
- **Per-texture adjusts (`adjust`):**
  - crown canopy leaves: saturation 0.5, brightness 0.82;
  - the giant canopy Meshy sheet: saturation 0.6, brightness 0.85;
  - storm fern: saturation 0.6, brightness 0.85.

It changes no placement, bake input, collision or harvest.

## History

A CPU quick judge on 4 Nov found the tint-only first version flat. The `adjust` block was added afterwards to reach the bright sheets a multiply tint could not cool. The flag has **not** been GPU-judged with `adjust` in. This arm is that judgement.

**Risk:** a darker canopy could deepen the fight-frame murk (F41#3, "dark low-contrast frames"). F41#3 is in the capture to catch it.
