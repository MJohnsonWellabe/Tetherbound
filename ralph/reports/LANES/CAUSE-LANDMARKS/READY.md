# CAUSE-LANDMARKS — ready for GPU

**Stopped 1 Nov (coordinator, owner direction).** All three candidates are OFF and the branch is pushed. The 7 tests in `tests/test_hero_landmarks_1101.gd` pass in a scratch project that holds only these assets and scripts; CI runs them in the full project. Nothing is in progress. Open: GPU capture and judging of the three flags in `MANIFEST.json`.

Branch `tb/cause-landmarks` (from `origin/tb/land-vis-2` + `origin/tb/meshy-landmarks-1101` 5a44380c9). The contract is `MANIFEST.json`.

## Summary (1 Nov)

There are three render-only candidates, all OFF, in `data/config/hero_landmarks_1101.json`. The code is in `scripts/world/hero_landmarks_1101.gd`. None adds or moves a collider, trigger, route, gate, terrain sample or judged camera.

| Item | Flag | What ON does |
|---|---|---|
| P2-041 Crown Arch | `crown_arch.enabled` | Overlays the round-2 hero arch settings with the 1101 crowned arch model: 7.0 m tall (about 3.9× the trainer), sunk 0.3 m into the moss slab. It keeps round 2's yaw 90 (road-facing), slab moss and edge stones. The footing collider, passage trigger and travel axis are untouched (hook: `stormwood_crown_arch_hero.gd settings()`). |
| P2-070 Glass Sink | `glass_sink.enabled` | Sets the terraced basin ring into the sink floor ahead of the Hollow Crown rim stands (approach (841, 2518) and close (812, 2484), heading 220). It is 300 m across and centred at (663.6, 2306.7) on the approach view line. Its rim meets the island cliff at about 38 m (bearing ~185, r = 245), and its bottom is buried 6 m under the -65 floor. A dark indigo glass pool disc fills the ring's open centre (the mesh has no floor). No collider (hook: `stormwood_world.gd` after `GLASS_SINK.dress`). |
| P2-010 / F39#4 / P2-026 Veilfall | `veilfall.enabled` | Past the 1100 m far handoff only: the polar-grid cone (layer 0) and its `Far_` crag copies stop drawing. The Meshy sea-cliff mountain stands on the cone footprint: centre (200, 4140), 800 m across, about 595 m tall against the 620 m peak, falls facing yaw 168. It uses a far shader (`shaders/meshy_far_landmark.gdshader`) with the silhouette's depth pull and live fog copy, and whiter, less-fogged fall texels. The old fall ribbons stop past 1100 m. Near view (< 1100 m) unchanged (hook: `water_veilfall.gd` after the silhouette build). |

- **Imports.** The `.import` files and extracted Meshy textures are committed, VRAM-compressed (`compress/mode=2`, `compress_to=0`); the Veilfall textures are capped at 1024 because it is only seen from far away. The GLB import is unchanged (LODs and shadow meshes on).
- **Test.** `tests/test_hero_landmarks_1101.gd` (7 cases) checks that all three ship OFF, that OFF changes nothing, and that ON swaps in the mesh at the configured size while colliders, triggers and old nodes are kept. All 7 pass in a minimal project holding these assets and scripts. It has not run in the full project; CI runs it.
- **CPU check.** This was a proxy, not the production scene: this container has 0.5–1 GB free disk, so a full project import does not fit, and deleting the 21 GB clone to make room was refused. `_sheet_cpu_proxy_1101.jpg` shows:
  - the arch beside a 1.80 m capsule (scale correct, feet on the slab);
  - Veilfall at 4 km and 1.2 km on a sea plane with fog (falls read white at 1.2 km and are small at 4 km);
  - the basin against a terrain proxy built from the real `stormwood_heightfield.gd` sink formula, at the two judged stands. The island's shoulder hides the near half of the bowl in the approach frame; the close frame shows the bowl, crystals and pool.
- **Unchecked.** Nothing here proves the arms float- or clip-free in the real scene. The first GPU capture of each arm is the real check.

## For the GPU sweep

- **Glass Sink tunables.** If the rim misses the cliff or the bowl is hidden, the knobs are `centre_xz`, `across_m` and `rim_top_y` in `glass_sink`. The proxy also tried 70 m / 360 m: it doubles the vertical stretch and makes the crystals spindly, so it is not recommended.
- **Veilfall far terrain.** If the analytic terrain cone still draws past 1100 m and its tip shows above the Meshy mountain, raise `across_m` (the height scales with it) or `depth_pull_max_m`.
