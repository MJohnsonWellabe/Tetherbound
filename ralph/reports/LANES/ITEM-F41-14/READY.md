STATUS: land
BRANCH: tb/item-f41-14  HEAD: see `git log -1 origin/tb/item-f41-14` (origin/main merged at 08ff4bbc on 8 Nov; tests below re-run after the merge)

**Row:** F41#14 Stormwood candy pickup tiers (P2-045), Blender row. Live 5.70 (board). Lane LANE-SW. Earlier lanes tried scale-only arms: r14s worse (Rare bloomed into a yellow "effect slab"), and r14u's +0.29 was held OFF because it broke the tier count. The brief says not to ship that arm; it is untouched.

**Result:** CPU 5.83 -> **6.04** mapped (r1, ON; 2/3 judges higher, defect calls FIXED/PARTIAL on both sides). Rarer always reads bigger: the test pins good < great < rare.

| Round | Arm | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Dir |
|---|---|---|---|---|---|---|
| r1 | `data/config/stormwood_candy_tiers_1107.json` enabled: a Blender body per tier (Good: green wrapped sweet; Great: blue-and-white striped twist; Rare: faceted gold gem on a violet star wrapper), Rare glow 0.6 | 5.83 | **6.04** | +0.21 | 5.2 5.0 5.3 / 5.0 5.4 5.6 | `ralph/reports/LANES/LANE-SW/qj/F41-14-a3daee699a66-11072346/` |
| r2 | `r2_1108`: deeper Good/Great body colours, halo 0.5 on every tier | - | - | not judged | - | capture was almost identical to r1 (inspected, not sent to judges) |

CPU llvmpipe, Compatibility, quick_judge, three code-blind judges, pinned anchors (anchor RMSE 0.72).

**Flags turned ON:** `data/config/stormwood_candy_tiers_1107.json:enabled` (CPU 5.83 -> 6.04). **Tests:** `tests/test_stormwood_candy_tiers_1107.gd` (new) asserts it ON with the score, that every tier builds with its body and wrapper surfaces sitting on the old base, that rarer is fitted taller, and that Rare's glow is reduced. Run after the merge: `test_stormwood_candy_tiers_1107`, `test_band_pickups` and `test_texture_import_policy`, all 0 failed.

**How it works:** `scripts/world/stormwood_candy_tiers.gd` (new) runs after the shared candy dressing, from `stormwood_pickup_runtime.gd::_mount_pickup`. It swaps the installed candy body's mesh in place for the tier's Blender mesh, fitted to the old body's footprint and height times `height_mult` (1.1 / 1.25 / 1.4), so spin, ring, crest, sparkles and wings stay attached. It applies to Stormwood pickups only, so other regions' candy and `candy_pickup_presentation.json` are untouched. Presentation only: no claim, collider or save change.

**Files touched:** `scripts/world/stormwood_candy_tiers.gd`, `scripts/world/stormwood_pickup_runtime.gd` (one call), `data/config/stormwood_candy_tiers_1107.json`, `assets/props/blender-1107/stormwood_candy/` (r1 GLBs plus the unjudged `_r2` Good/Great GLBs, .import, provenance.json), `tests/test_stormwood_candy_tiers_1107.gd`, and this dir (`build_candy_tiers.py`, `_scale_check_candy.jpg`).

**Provenance:** Blender 4.2.3 procedural primitives, untextured PBR colours from sRGB targets, no emission, no Meshy.

**Flags left OFF:** `stormwood_candy_tiers_1107.json r2_1108`. Not judged: its capture barely differed from r1. The pale cast on Good and Great comes from the shared tier dressing's white wings/crest and highlight, not the body colour.

**Judges' remaining asks:**
- Good and Great read pale green-white and blue-white, close in value. The shared dressing's white parts carry this.
- The size step should be stronger.
- Not this row: the chibi trainer and the cartoon cottage in frame 2.

**Next idea:** tint or hide the shared crest and wing parts for Stormwood Good and Great (band_pickups dressing children), and raise height_mult to 1.0 / 1.35 / 1.7. Rare's glow is already held down, so it should not bloom.
