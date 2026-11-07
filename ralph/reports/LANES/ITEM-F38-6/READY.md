STATUS: land
BRANCH: tb/item-f38-6  HEAD: e1cc6f697c13043e91a5bf84dc064dc5dbe04398 (the gain commit; this READY commit follows it)

Lane LANE-MS (Meadows). Row F38#6 (P2-033 ground pickup identity), board 5.52. This is a Blender row.

**Round 1** (`ralph/reports/LANES/LANE-MS/qj/F38-6-6b6bc90bbae7-11072022/`; CPU llvmpipe, Compatibility; three code-blind judges; calibration r 0.81, RMSE 0.67):
- **CPU mapped 6.50 -> 6.76 (+0.26).** All three judges preferred the candidate.
- They read the deep blue cloth as separating from the sunlit grass, where the old near-white cloth blended into the highlights. One judge moved the defect to FIXED.

**New art (Blender, owner 7 Nov):**
- `assets/props/meshy-1020/candy_pickup_set/model_candy_rare_cloth_r1/candy_rare_cloth_r1.glb` is a reskin of the installed Meshy `candy_rare.glb` (task 01a15c3f-…).
- Geometry, UVs, normal map and metallic-roughness map are unchanged.
- Only the cloth's pale texels are recoloured: the faces in the lower 47% of the model's height with saturation below 0.42, moved to blue velvet #1b375c with their shading kept.
- The gold trim and the sweets keep their colours. No red is used.
- Script: `ralph/reports/LANES/ITEM-F38-6/blender/candy_rare_cloth_r1.py` (Blender 4.2.3).
- Preview and scale script: `render_preview.py` (Cycles on CPU).
- Reference: `blender/_reference_cloth_r1.jpg`, showing before (top) and after (bottom) beside a 1.80 m trainer bar.
- Provenance: `provenance.json` in the model folder.
- Scale: unchanged. The model is fitted at `height_m` 0.9, half the 1.80 m trainer.
- The texture `.import` files follow the runbook's Meshy rule (compress/mode=2, compress_to=0).

**Flag turned ON:** `data/config/meshy_item_visuals.json:items.rare_candy.model` now points at the reskin, with `_why_on` recording the score. The old path is named there.

**Tests:**
- New: `tests/test_pickup_cloth_f38_6.gd`.
- Ran test_pickup_cloth_f38_6, test_meshy_item_visuals, test_band_pickups and test_texture_import_policy: 42 tests, 43146 assertions, 0 failed.

**Files touched:** the config above, the new model folder, the test, and the qj verdict.

**Judges' remaining asks:**
- The pickups read oversized against the trainer (good_candy is about knee to hip height).
- The green striped good_candy reads as a toy or sweet.
- The pink potion is a saturated outlier.
- What each pickup is remains guesswork. They ask for item-specific meshes at believable scale: a wood bundle, a seed pouch, a berry basket.

**Next idea:**
- Grade the potion's pink toward the Meadows palette (another Blender recolour).
- Try a smaller `height_m` for good_candy. That shrinks a prop, not a creature, so it is allowed.
- Each needs its own round. I stopped at one round: this row still has budget, but the next arms are new items, so I moved on to keep usage down.
