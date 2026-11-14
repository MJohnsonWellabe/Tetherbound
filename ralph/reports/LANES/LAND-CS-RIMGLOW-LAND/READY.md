STATUS: land

# tb/land-cs-rimglow-land: smaller pickup glow on the High Perches rim mushrooms (F40#17)

**Verdict:** GPU High, `ralph/reports/GPU-PASS/1108/G-land-cs-rimglow.md` on tb/judge 99819fd2 (confirming batch; r 0.859, RMSE 0.71, read as about ±0.3): F40#17 crown-rim-out day and night 6.03 -> 6.61 (+0.58, 3/3 prefer). The milky "debug pickup glow" balls are gone; the clusters read as grounded (floating defect FIXED 2/3, PARTIAL 1/3). Crown court no-loss level, 6.24 -> 6.20 (−0.04, inside noise).

**Flag:** `data/config/mushroom_pickup_variants.json perch_rim_cluster_1112.rim_glow_1113`, ON with `_why_on`, scale 0.45.

**Files (5):**
- `scripts/world/mushroom_pickup_presentation.gd`: `glow_scale(placement_id)` (1.0 for every pickup except the three rim placements when the flag is on).
- `scripts/world/item_cache_pickup.gd`: passes it at its four glow registrations (no other change).
- `data/config/mushroom_pickup_variants.json`: the flag ON.
- `tests/test_rim_glow_flag.gd`: the ON pin (verdict file and score), non-rim pickups keep 1.0, scale clamped and never removes the glow.
- this READY.md.

**Scope:** device-local presentation. The pickups still glow (owner OP-0830-3), only smaller at these three placements. Interaction, claims and saves unchanged.

**Tests run (14 Nov, on this branch):** every pickup and mushroom test file in one run, 75 tests, 49,747 assertions, 0 failed: `test_rim_glow_flag`, `test_below6_perch_rim_landed`, `test_mushroom_natural_cluster`, `test_item_cache_pickup`, `test_pickup_glow`, `test_band_pickups`, `test_band_pickups_meshy_candy`, `test_cloudreach_pickup_density`, `test_pickup_cloth_f38_6`.

**Not a close.** Next asks (3/3): the perched griffin clips into the tower wall with a floating wing or feather piece on the tower face (scene placement; LANE-BEINGS for the perch); the orange checker platform top reads as a placeholder; the night is a flat blue tint (CLOUDNIGHT r2); the orange lip cluster needs a soil or root base.
