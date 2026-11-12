STATUS: land

# tb/below6-perchrim-land: natural mushroom patches on the High Perches rim (F40#17)

**Verdict:** GPU High, G-below6-mushrooms (`ralph/reports/GPU-PASS/1108/G-below6-mushrooms.md` on tb/item-scout-1108 bc115978): F40#17 6.01 -> 6.94 (+0.93, 3/3), defect FIXED 3/3 ("smaller natural clusters, clearly on the grass, at a believable size"); the High Perches views +0.28 (2/3).

**The arm was a SPLIT, so only the part that gained ships.** The same restyle on the open finds lost (Meadows finds 6.66 -> 5.92, 0/3; F40#16 -0.09), so:
- `data/config/mushroom_pickup_variants.json perch_rim_cluster_1112` is **ON**, with `_why_on`, and applies the natural patches only at the three rim placements (`cr_recovery_high_roost_flight_speed_01`, `..._stamina_01`, `..._wild_01`).
- `natural_cluster_1112` (the unscoped restyle, which also holds the three items' looks) stays **OFF**.

**Code:** `scripts/world/mushroom_pickup_presentation.gd` (cluster copies, tint, and the placement scope read from the pickup's `_placement_id`).
**Tests:** `tests/test_below6_perch_rim_landed.gd` (pin: rim ON with its verdict, open arm OFF, only rim placements take the patch), `tests/test_mushroom_natural_cluster.gd`; with the NEAR6-CR and pickup tests: 108 tests, 0 failed.
**Checked in the real scene (CPU, High Perches capture):** the three rim finds show the tan, blue and orange-shelf patches; nothing else changes.

**Scope:** device-local presentation. The hidden pickup mesh, interaction, claims and saves are unchanged.

F40#17 is at 6.94, a near-bar candidate once on main; not a close.
