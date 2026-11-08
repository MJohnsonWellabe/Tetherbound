STATUS: land
BRANCH: tb/item-f41-9  HEAD: see `git log -1 origin/tb/item-f41-9` (origin/main merged at ad18440d on 7 Nov; tests below re-run after the merge)

**Row:** F41#9 Stormwood harvest resource identity (P2-046), Blender row. Live 5.40 (board). Lane LANE-SW. Earlier lanes parked it twice, waiting on new art.

**Result:** three judged rounds, each 3/3 higher; all three ship ON (they stack: r2 builds on r1, r3 on r2).

| Round | Arm (over the previous round, ON) | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Dir |
|---|---|---|---|---|---|---|
| r1 | `stormwood_harvest_hero2.json lane_sw_1107`: Blender storm-glass (violet prisms, copper ore, basalt), crown, solid glowmoss cushion | 5.64 | **6.31** | +0.67 | 5.2 4.8 4.8 / 5.6 5.5 5.6 | `ralph/reports/LANES/LANE-SW/qj/F41-9-d157477bc0c8-11072300/` |
| r2 | `lane_sw_1107_r2`: columnar basalt with thicker copper bands; tufted glowmoss with taller caps | 5.52 | **6.00** | +0.48 | 5.0 4.7 4.6 / 5.3 5.0 4.9 | `.../qj/F41-9-55e013ff1e73-11072314/` |
| r3 | `lane_sw_1107_r3`: glowmoss on a dark basalt boulder (copper flecks) under a cool blue-green moss drape, brighter teal caps | 4.98 | **5.65** | +0.67 | 4.5 4.9 5.0 / 4.9 5.3 5.5 | `.../qj/F41-9-256232419465-11072326/` |

CPU llvmpipe, Compatibility, quick_judge, three code-blind judges, pinned anchors (anchor RMSE 0.76 / 0.66 / 0.51). Each round's base is the previous round ON, so the gains stack, but they come from separately calibrated batches. The defect moved from PRESENT to PARTIAL.

**Flags turned ON:** `data/config/stormwood_harvest_hero2.json`:
- `lane_sw_1107`: 5.64 -> 6.31
- `lane_sw_1107_r2`: 5.52 -> 6.00
- `lane_sw_1107_r3`: 4.98 -> 5.65

`stormwood_harvest_runtime.gd::hero2_for` uses r3, then r2, then r1, then the old round-2 items (still OFF).

**Tests:** `tests/test_stormwood_harvest_nodes_1107.gd` (new) asserts all three ON with their scores, that each item uses its latest node, the named surfaces, and no collider. `tests/test_storm_cams_candidates.gd` is flipped: it asserted the hero2 path empty (round-2 OFF); it now asserts the shipped Blender node is in charge. Run after the merge: those two and `test_texture_import_policy`, all 0 failed.

**Files touched:**
- `scripts/world/stormwood_harvest_runtime.gd` (`hero2_for` precedence)
- `data/config/stormwood_harvest_hero2.json` (three keys; not a scatter bake input)
- `assets/props/blender-1107/stormwood_harvest/` (node, crown and glowmoss GLBs for r1, r2 and r3; .import; provenance.json)
- the two tests above
- this dir: `build_harvest_nodes.py` (args `r2`, `r3`), `_scale_check_nodes.jpg`, `_scale_check_nodes_r2.jpg`

**Provenance:** Blender 4.2.3 procedural geometry (seeds 9101-9104), untextured PBR colours authored from sRGB targets. No Meshy, no downloads. Natural glow only, on the glass and the fungus caps.

**Harness note:** glTF base colours are linear and Godot shows them as sRGB, so mid-tone albedos rendered near-white under the Stormwood ambient in the first, unjudged capture. Author them from dark sRGB targets (`lin()` in the script).

**Flags left OFF:** none from this row. The old round-2 `enabled` stays OFF, as before.

**Judges' remaining asks (r3):**
- The ground is a saturated lawn-green carpet; it should be the board's cool blue-green moss. That is the Stormwood ground palette (`stormwood_ground_finish` and the terrain), not the nodes.
- The flat purple sky band.
- The glowmoss still reads partly as "mushrooms on a rock".

**Next idea:** a Stormwood ground-palette pass (moss hue toward #2f5a4a), tried first on F41#9's three stands. Earlier foliage-grade arms lost twice, so this needs a new approach: a terrain albedo change, not a post grade.
