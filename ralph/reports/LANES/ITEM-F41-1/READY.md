STATUS: land
BRANCH: tb/item-f41-1  HEAD: see `git log -1 origin/tb/item-f41-1` (merged origin/main at 1e97931b on 7 Nov; test_stormheart_root_vault 0 failed, test_texture_import_policy 0 failed after the merge)

**Row:** F41#1 Stormheart finale (P2-037), Blender row. Live 3.94 (board, VIS-STORMWOOD j1). Lane LANE-SW.

**Result:** CPU 4.75 -> **5.24** mapped (r1, root vault, ON). Stopped after r2 under the stop rule (two consecutive rounds gaining under 0.5: r1 +0.49, r2 -0.31).

| Round | Arm | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect | Dir |
|---|---|---|---|---|---|---|---|
| r1 | `stormheart_presentation.json root_vault_1107`: Blender living-root vault under the OuterWorks deck slab | 4.75 | **5.24** | +0.49 (3/3 higher) | 4.2 3.8 3.9 / 4.7 4.1 4.4 | PRESENT -> PARTIAL 3/3 | `ralph/reports/LANES/LANE-SW/qj/F41-1-5fc02ca2f939-11072048/` |
| r2 | `heart_cradle_1107` (with r1 ON in both arms): Blender crystal core in a braided-root cradle in the heart cleft | 5.60 | 5.29 | -0.31 (3/3 lower) | 4.8 5.0 4.9 / 4.6 4.7 4.6 | PARTIAL/PRESENT both | `ralph/reports/LANES/LANE-SW/qj/F41-1-589bb668d6a4-11072122/` |

CPU llvmpipe, Compatibility, quick_judge, three code-blind judges, pinned anchors (anchor RMSE 0.67 / 0.69).

**Flags turned ON:** `data/config/stormheart_presentation.json:root_vault_1107` (CPU 4.75 -> 5.24, r1). **Tests:** `tests/test_stormheart_root_vault.gd` (new) asserts it ON with its score, the model's named surfaces, no collider and its bounds under the 6 m slab. Run with it ON: `test_stormheart_root_vault`, `test_stormheart_presentation`, `test_vis_stormwood_judged_on`, `test_cause_stormwood_candidates`, all 0 failed.

**What the root vault is:** the approach stand stands under the OuterWorks deck (a 6 m annular slab, r 18-44 m) whose underside tiled the bark texture once per radial quad, a "radial plank ceiling" over a third of the frame. The vault is a bark web whose grain follows 56 primary and 56 secondary gnarled roots, flaring into buttress roots at the outer wall (none in the two entrance splits), with thin natural lightning veins on 14 roots. Nothing hangs below 4.7 m inside r 44 m; the lip within r 20.2 m stays flat for the lantern clusters. Presentation only, no collider.

**Files touched:** `scripts/world/stormheart_tree.gd` (`_root_vault`, `_heart_cradle`), `data/config/stormheart_presentation.json` (two keys), `assets/props/blender-1107/stormheart_root_vault/` and `stormheart_heart_cradle/` (GLB, .import, provenance.json), `tests/test_stormheart_root_vault.gd`, this dir (Blender scripts `build_root_vault.py` and `build_heart_cradle.py`, reference crop `_ref_board_interior.jpg`, scale checks `_scale_check.jpg` and `_scale_check_cradle.jpg`).

**Provenance:** Blender 4.2.3 procedural geometry (seeds 1107, 11072), no Meshy, no downloaded geometry. In game both use the installed `Bark_TwistedTree` bark plus emissive vein and crystal materials. The reference is the owner's Stormheart board interior view.

**Flags left OFF and why:**
- `heart_cradle_1107` (r2, worse -0.31). The deck slab hides 6-16 m of the heart cleft from every judged stand, so the core had to sit at 17-31 m. There, under llvmpipe, the crystal clipped to flat white and the frame top cut its tip: 2/3 judges called it "a white splash/spike at the top edge that reads as an artefact". The cradle roots alone did not register. Its test asserts OFF.

**Judges' remaining asks (r2):**
- No visible crown or split trunk: every judged stand is inside the hollow. new_art or capture choice, not this row's frames.
- No glowing lightning core column; the lightning is flat white line strokes.
- The moss floor is blotchy, over-saturated and stretched, with a hard black pool.
- The banners are flat saturated-blue squares, all the same size and evenly spaced.
- A flat cutout bush clips the right edge of the approach frame.

**Next idea:** the crystal core read as a blob because it is emissive and pale. A second cradle attempt should use a deep-blue, mostly unlit crystal (glow only in thin inner seams), kept inside the 18-27 m band so the frame top does not cut it. Larger levers: the floor material (the biggest area in all three frames; the earlier dark loam lost, so try a cooler, less saturated moss with value variation) and the banners (navy and gold hanging cloth like the board's).
