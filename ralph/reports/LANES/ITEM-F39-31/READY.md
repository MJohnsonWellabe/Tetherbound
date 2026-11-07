STATUS: parked
BRANCH: tb/item-f39-31  HEAD: c526eea77b52fa22d09beab92986eb8c7c43406f (this line added in the next commit)

# ITEM F39#31 and F39#2 Veilfall (LANE-TW, Blender row)

- **Rows:** F39#2 P2-010 Veilfall silhouette (GPU 5.78) and F39#31 Veilfall at distance and up close (5.56). They share one cause on one branch.
- **Result:** parked under the stop rule after two consecutive judged rounds that lost. Nothing ships ON.
  - Round 1 (`qj/F39-2-f0ffeeed1cd7-11071925`): tiered Blender Veilfall, CPU mapped 6.77 -> 6.31 (-0.46). Judges 3/3: "stepped ziggurat / wedding cake".
  - Round 2 (`qj/F39-2-f0ffeeed1cd7-11071950`): pinnacles, sloped ledges, broader falls and low mist, CPU mapped 6.57 -> 5.46 (-1.11). Judges 3/3: "pale stepped white blocks"; the falls read as flat white slabs.
- **What was built (all inert, flag OFF):**
  - `assets/props/blender-1107/veilfall_tiered/veilfall_tiered.glb` and its extracted textures. Procedural Blender 4.2 build with no source meshes: rock tiers, crag pinnacles, about 980 tree clumps seated by raycast, stepped falls and mist puffs. Script and textures: `ralph/reports/LANES/ITEM-F39-31/blender/` (`make_textures.py`, `build_veilfall.py`).
  - Scale: authored in metres, 836 x 875 x 799 m. The candidate used `across_m` 1000, about 910 m tall. There is no trainer-scale concern for a landmark that draws only past 1100 m.
  - `scripts/world/hero_landmarks_1101.gd`: optional `veilfall.hide_siblings_from_m` and `hide_sibling_nodes`. Applied deferred, it stops the render-only crag heaps (kitbash, cliff_r3, tiered_r2, ridge blockout, gate passage) drawing past the far handoff. Without it they buried any far hero (seen in round-0 frames). The key is absent from config, so the code is inert.
  - `hero_landmarks_1101.veilfall.enabled` stays false. No config or test flipped.
  - Tests: `test_hero_landmarks_1101.gd`, `test_glass_sink_wall_grade.gd` and `test_vis_stormwood_judged_on.gd` all pass (8/2/8 tests, 0 failed).
- **Arm (for reproduction):** `{"data/config/hero_landmarks_1101.json": {"veilfall": {"enabled": true, "model": "res://assets/props/blender-1107/veilfall_tiered/veilfall_tiered.glb", "across_m": 1000.0, "yaw_deg": 172.0, "sink_m": 6.0, "hide_siblings_from_m": 1100.0, "hide_sibling_nodes": ["VeilfallCragKitbash", "VeilfallCliffR3", "VeilfallTieredR2", "VeilfallRidgeBlockout", "WaterfallPassage"]}}}`.
- **F39#31 is not reachable by a far hero.** Its stands (F39-look `veilfall-near` about 390 m, `veilfall-vista` about 750 m from the centre) are inside the 1100 m handoff. A near-range replacement would have to match the physical island and gate approach (entrance about 360 m from the centre), so it is a terrain and collision rebuild. F39#31 was not judged this pass.
- **Findings for the next attempt:**
  1. The far shader (`meshy_far_landmark.gdshader`) plus fog and Compatibility lighting renders mid-grey textures as near-white. Any far hero needs much darker rock values than it looks in Blender, and falls with real form (thickness, spray) rather than textured quads.
  2. Judges consistently prefer the shipping craggy spire with its single broad continuous fall. Base calls went FIXED on one judge in round 2.
  3. Next idea (not a repeat of this approach): keep the shipping crag composition and add to it. Green ledges or tree clusters on its upper shelves, two more broad continuous veils beside the main fall, and base spray/mist at the sea. This is near-range dressing on the existing kitbash, so it would also reach F39#31's stands.
- **Texture import fix (coordinator, 7 Nov 21:31):** the five `veilfall_tiered_*.png.import` sidecars now use VRAM compression (mode 2) via `tools/art_pipeline/texture_import_policy.py --apply` plus re-import. `test_texture_import_policy.gd`: 2 tests, 1587 assertions, 0 failed.
- **Judges' remaining asks:** greenery and pine cover on the crag, several broad falls with base mist and foam, haze toward the landmark, and beach dressing (grouped grass, rocks, driftwood) in the foreground.
