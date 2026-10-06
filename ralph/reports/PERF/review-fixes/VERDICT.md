# Fixes for the independent review BLOCK on 4182f3ac

1. **detail_cull and wide MultiMesh batches.**
   - Godot tests a node's visibility range against the centre of the node's whole box. A MultiMesh whose instance spread is wider than its own computed reach is now left unranged.
   - The spread is measured from the instance transforms. When the spread can't be read (the headless Dummy renderer keeps no instance buffer), the batch is treated as unknown and also left unranged.
   - Covers the world_perimeter Hedge, Boulder, Fence, Tree and Reed runs, the water.gd Shore_* batches and the others the review named.
2. **The Stronghold landmark spine is never ranged** (`detail_cull.skip_subtrees: ["Stronghold"]`), matching performance.json's structure rule.
3. **harvest_node.** The idle stock poll stays at 1 s. A day change re-reads at once, and a gather always re-reads stock, and with it `expected_revision`, right before it submits. `f32_source_service._enabled()` caches the runtime flag by file stamp instead of parsing JSON on every stock read.
4. **static_mesh_batch.** Meshes with alpha-blended materials (ALPHA or ALPHA_DEPTH_PRE_PASS, or shaders that write ALPHA without a scissor threshold) are excluded, along with instance transparency.

Tests:
- New `tests/test_detail_cull.gd`, 5 tests covering a wide batch, a single instance, small and large meshes, the Stronghold skip with small lamps, and an authored range. It passes headless and under a real renderer (xvfb, opengl3).
- Affected suites (detail cull, harvest and F32, rematch, tournament and bounty, village, day cycle, foliage visibility, far floor, Stormwood pockets): 313 tests, 0 failed.

Frames:
- Meadows west perimeter (fence, hedge, boulders) and pond shore, day and night, at Low. Medium needs Forward+, which this container cannot render; that pass is requested from Codex.
- The detail cull was switched on and off at the same commit, and the pairs were randomised for the judge (`judge8_key.json`). Code-blind judge: **EQUIVALENT on all 6 pairs**. The boundary fence runs, posts, hedge clumps and boulders are present and identical. The only differences were clouds, sway, ripples and pulse phase.
- The `*_before.jpg` and `*_after.jpg` files are the day pairs.
