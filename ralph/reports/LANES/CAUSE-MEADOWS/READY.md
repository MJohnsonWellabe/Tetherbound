# Cause lane: Meadows light, atmosphere and ground (tb/cause-meadows)

**Group 2 (1 Nov, ~23:30 UTC): cause_light r2.** Same flag, `data/config/meadows_look.json:cause_light.enabled`. It adds `cause_light.foliage`: the Meadows scatter leaves and flowers get backlight 0.45 instead of 0.28, for the "card-like trees". This is backlight only. A leaf rim would make `foliage_standard_shader.gd`'s converter refuse those materials, and that would drop them out of the fight foliage fade. MANIFEST repeats every cause_light entry as `group: 2`; capture them on this head. The foliage logic was run headless, and the test case is in `tests/test_meadows_cause_flags.gd`.


**Group 1 (1 Nov, ~23:00 UTC).** Three flags, all OFF. MANIFEST.json has an entry for every Meadows catalogue item whose frames each flag changes (138 entries). UI-only items are left out: P2-001, P2-002, P2-007, P2-031, P2-061, P2-095 and P2-096. P2-004 (HUD) gets the light flag only.

| Flag (set true) | What it changes |
|---|---|
| `data/config/meadows_look.json:cause_light.enabled` | **Light and grade, day.** The key light is warmer and lower: pitch -38 → -30, energy 1.5 → 1.75, colour #ffd7a3. The fill is cooler and weaker: ambient 1.9 → 1.3, #8aa3c6. So lit faces are warm and shadows are cool and darker, which adds value range. Exposure 0.6 → 0.62. **Distance:** fog is about 2.2× denser and bluer (#94b0d2, 0.0022), with sky affect 0.15 and aerial perspective 0.9. The sky horizon and haze match the fog. The terrain's distance fade colour is cooler (#7088ae). Contrast 1.1 → 1.16, saturation 1.08 → 1.0. **Separation:** characters get a rim by day (0.4). Every creature gets a faint field rim (floor 0.12). That is under the uncommon tier's 0.14 and the alpha's 0.65, so the rarity tells stay. **Night:** carries light_candidate's night fill unchanged. **Golden:** untouched. |
| `data/config/meadows_look.json:cause_ground.enabled` | **Ground.** Terrain: the macro blobs become a deliberate two-tone (light straw #eef0dc and a cooler, darker lush #c3d6bb) instead of an olive smear. Terrain mip bias 0.86 → 0.7 (sharper), near grain 0.22 → 0.34. Grass ring: the ground-zone field runs at full strength and a larger scale (~31 m), so a frame shows clearings, lawn, tall grass and dry-olive patches instead of one carpet. Clump contrast 0.55 → 0.75. Flowers gather into denser drifts. Viewport: 16× anisotropic filtering and a -0.35 texture mip bias, so ground and village textures stay crisp at grazing angles. The viewport values are restored when the Meadows look leaves the tree. |
| `data/config/capture_stands.json:buried_stand_guard.enabled` | **P2-014: a capture-stand fix, not a look change.** The Warrens earth bank is a hollow trimesh shell. The capsule-overlap check and the floor ray both start inside it, so walk_02 (player) and walk_03 (camera) were staged inside the bank. That is where the "floating faceted brown slabs" come from. With the guard on, a terrain stand is rejected if a down ray from 8 m above the player stand, or above the settled camera, hits solid geometry. The loop then tries its next offset, and 18 m and 26 m fallback offsets are added at the end. Frames whose first stand was clear are unchanged. Built-floor stands (stronghold rooms, Warrens chambers) are exempt. |

**Composition:**
- `cause_light` merges after `light_candidate`, so enabling both is harmless.
- `cause_ground.grass` merges after `grass_field.json meadows_ground_candidate` (shipping ON).
- `cause_ground.terrain_shader` merges after `terrain_presentation.json shader_candidate`.
- None of them reads or writes another lane's keys.
- Everything is renderer-neutral: sun, ambient, depth fog, ACES/BCS, material rim, terrain uniforms and viewport filtering all exist on Compatibility.
- No per-frame work, no volumetrics, no durable or replicated state.

**Checks:**
- Every touched script passes Godot 4.7 `--check-only` (TECHNICAL §8.1 method):
  - clean outright: `grass_field.gd`, `creature_body.gd`, `phase2_capture_locations.gd`, `phase2_capture_routes.gd`;
  - checked in isolation with stubs: the new functions in `meadows_look.gd` and `playground_world.gd`, because a dependency's `.glb` preload blocks a whole-file parse without an import.
- The grass merge, stand-guard config readers, overhead query and rim floor clamp were also run in a headless Godot script and behave as intended.
- New unit test: `tests/test_meadows_cause_flags.gd`. It is unrun under `run_tests.gd` here, because autoloads need imported assets.

**Not verified here:** no CPU capture was possible. The container has 1.1 GB free and no `.godot` import (a full import does not fit). The GPU batch is the first render. Please check for blown highlights on sunlit paths with cause_light ON: the key is about 20% brighter on lit faces.
