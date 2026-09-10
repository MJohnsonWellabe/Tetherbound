# GRASS-SHADING01 — withdrawn after cross-location review

Final decision: withdraw the production shader change. One Water daytime diagnostic preferred it modestly, but fresh South Bridge and Glass Field reviews found no meaningful difference and Root Walk preferred the former shading, particularly at night. This does not establish a broad improvement. The procedural-grass visual acceptance issue remains open. The patch is preserved at `.artifacts/broad-visual-0910/grass-shading01-withdrawn.patch`; the diagnostics and images remain evidence of this attempt, not the retained build.

Native production comparisons completed without engine errors: Meadows candidate 06:22:37–06:24:10 (4 frames), Stormwood candidate 06:26:08–06:27:11 (4), Meadows control 06:28:09–06:29:40 (4), Stormwood control 06:30:55–06:31:59 (4), Water candidate 06:37:06–06:37:54 (6), Water control 06:38:04–06:38:50 (6). The controls validated live field-center, wind and raw terrain bindings at each pose. The focused unit run passed 22 tests / 87,832 assertions at 06:21:54–06:22:02. Neither clean execution nor unit success establishes visual acceptance.

Fresh judgments are recorded in `JUDGE-GRASS-SOUTHBRIDGE01.md`, `JUDGE-GRASS-GLASSFIELD01.md` and `JUDGE-GRASS-ROOTWALK01.md`. Their separate answers were A No / B Yes / commercial No. Root Walk's night minute labels differ slightly, so this is not exact temporal equivalence; the reviewer still found the local original-root shading preferable. Untested motion/performance remains unclaimed. The following records the candidate's mechanism and historical setup before withdrawal.

Date: 2026-09-10  
Production change: `shaders/grass_field.gdshader` only

## Change and cause

The shared grass vertex shader formerly replaced every blade vertex normal with
`normalize(vec3(NORMAL.x * 0.35, 1.0, NORMAL.z * 0.35))` before applying the
blade's stable yaw. That forced the authored, mostly horizontal blade faces to
shade as upward-facing surfaces. The Water diagnostic removed only that override;
the shader now retains each mesh vertex's authored normal and still rotates its XZ
components by the same per-item yaw used for geometry.

The production candidate reproduces that exact diagnostic mechanism. It changes no
tint, geometry, bend, density, culling, backlight, terrain sampling, placement, or
LOD value.

## Existing evidence

Root's `water-grass-shading-cause-fourth` diagnostic ran clean from
06:07:30–06:08:52 UTC and recorded seven frames with actual Terrain3D render IDs
validated. Its alternatives isolated the authored-normal path, the previous
upward-normal path, and backlight zero.

The fresh blind verdict in `JUDGE-GRASS-SHADING01.md` modestly preferred F01, the
authored-normal image, over F02, the production baseline, because its foliage
contrast was calmer and its pale edge/tip presence less conspicuous. F03,
backlight zero, retained conspicuous pale blades and dark interruptions. The judge
found the alternatives close at small viewing size and explicitly did not establish
other locations, weather, camera distances, movement, or performance. A remained
No, B was narrowly Yes, and commercial quality remained No.

This is one accepted Water daytime comparison, not a whole-realm or all-biome
visual acceptance claim.

## Production scope

`scripts/world/grass_field.gd` creates its primary grass material from
`res://shaders/grass_field.gdshader`. Its production consumers are:

- Meadows: `playground_world.gd` creates `GrassField` through that script.
- Stormwood: `stormwood_world.gd` creates `StormwoodGroundCover` through the same
  script and shader.
- Water: `water_world.gd` creates profile-configured `WaterGroundCover` through the
  same script and shader.

Cloudreach is excluded. `cloudreach_world.gd` constructs
`cloudreach_ground_cover.gd`, which borrows the shared tuft mesh factory but assigns
`cloudreach_ground_cover.gdshader`; it does not render this material.

The shader edit therefore reaches three production realms. Only Water daytime has
the isolated blind comparison so far. Meadows, Stormwood, all affected night views,
and motion remain root-owned native follow-ups.

`tools/probe_grass_upward_normal_control.gd` is the matched catalogue control.
It accepts the base catalogue's ordinary biome, subset, time, character, and output
arguments. After the production world is mounted and before capture preparation, it
finds only live `GeometryInstance3D` materials whose shader resource is the shared
grass shader, inserts the former upward-normal line exactly once, and retains the
stable yaw. It replaces the Shader on each unique original live ShaderMaterial,
rather than replacing the material object, so `GrassField._material` continues to
receive its ordinary `field_centre`, wind, LOD, and terrain updates during long
catalogue travel. It snapshots and restores all cached uniforms plus Terrain3D's
`_height_maps`, `_control_maps`, and `_color_maps` raw RenderingServer RIDs. Its
manifest records every affected node and unique material, and verifies the live
camera center, advancing wind time, shader identity, and raw bindings after each
pose. It changes no camera, time, material value, geometry, gameplay state, or
production resource.

## Static verification and limits

Static source inspection confirms the upward-normal assignment is absent, the
`NORMAL.xz = lattice_yaw(NORMAL.xz, item_yaw)` line remains, and there is one
production material load of this shader in `grass_field.gd`. `git diff --check`
passes. No Godot process was launched by this lane.

The diagnostic probe still contains the old assignment as a search token because it
was built to remove that line from the previous production baseline. It is evidence
tooling, not a production consumer. Re-running that old three-way probe against this
new baseline would no longer recreate its original labels and should not be treated
as a fresh A/B.
