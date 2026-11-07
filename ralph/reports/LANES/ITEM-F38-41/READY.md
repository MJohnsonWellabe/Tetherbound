STATUS: land
BRANCH: tb/item-f38-41  HEAD: b37d965d356e25609f782b6ad4ae2388615eedf1 (the gain commit; this READY commit follows it)

Lane LANE-MS (Meadows). Row F38#41 (Old Quarry boulders, raw 6.43 after natural faces). This is a Blender row. Verdict: `VERDICT_r1_r2.md`; rounds in `qj_r1/` and `qj_r2/` (sheet `qj_r2/_sheet_f38_41_r2.jpg`).

- **Best: CPU mapped 6.43 -> 6.96 (+0.53)** in r2. All three code-blind judges preferred it, and they moved the defect "smooth rounded lumps" PRESENT -> PARTIAL.
- r1 was flat (6.70 -> 6.64): noisy blue speckle on rounded shapes. Its assets are deleted.

**New art (Blender, owner 7 Nov):**
- `assets/environment/stylized_nature_q41_r2/Rock_Medium_{1,2,3}_q41_r2.glb` recombines installed assets: the `stylized_nature/Rock_Medium_*` meshes and the `terrain/Rock030` stone.
  - Seams welded, 7 random bisect split planes through the outer about 22%, light voronoi and cloud grain, box UVs at 2.6 m per repeat, and a warm-grey grade baked into a copy of the Rock030 texels.
  - Footprint and height equal the sources, so placements and colliders keep their sizes.
- Script: `blender/rock_medium_q41.py` (`Q41_VARIANT=r2`, Blender 4.2.3).
- Preview and scale check: `blender/render_preview.py` beside a 1.80 m bar.
- Texture `.import` files follow the runbook rule (compress/mode=2, compress_to=0).

**Flags and config turned ON (each carries `_why_q41_r2` / `_why_natural_face_models` with the score):**
- `data/config/bands/band2_stone_and_root/props.json`: `quarry_station` (5 Rock_Medium spoil pieces) and `old_quarry_cut_face` (13 cut-face masses) now use `dir` `stylized_nature_q41_r2` with the `_q41_r2` models. Their old `retint` keys name the old `Rocks` material, so they no longer apply.
- `data/config/bands/band2_stone_and_root/harvest.json` orders 12, 13 and 14 (the rootstone deposits, which are the two big foreground boulders in the judged frame): their models now point at the r2 boulders.
- `data/config/old_quarry.json`: new `worked_cut.natural_face_models` lists the r2 models. It is read by a new optional hook in `scripts/world/old_quarry.gd`; with no list, the original three Rock_Medium meshes are used as before.

**Checks:**
- Ran test_harvest_rock_tint, test_harvest, test_fight_ring_occluders, test_chapter_content_map, test_texture_import_policy, test_vis_meadows_1104_on and test_meadows_tier1_art_gates: 93 tests, 0 failed.
- `tests/smoke_quarry_rootstones.gd` passed.
- No test asserted these OFF.

**Files touched:** the three configs above, `scripts/world/old_quarry.gd`, the new asset folder, and this row's report dir.

**Flags left OFF:** none.

**Judges' remaining asks:**
- The granite speckle is still a little photographic at range.
- It clashes with the pale old boulders and white blocks at mid-left. These are not from these clusters; next, name them with `tests/probe_camera_pixel.gd` and put them on the same family.
- No terraced cut face or rubble apron.
- Foreground planks are oversized.

**Next idea:** move the remaining pale quarry rocks onto the r2 family, and soften the grain by lowering the Rock030 normal strength or using a larger UV repeat.
