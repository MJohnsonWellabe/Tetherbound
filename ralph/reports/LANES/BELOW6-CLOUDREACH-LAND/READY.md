STATUS: land

# tb/below6-cloudreach-land: two Cloudreach fixes (F40#8 bridge strip, F40#17 rim mushrooms)

| Flag (ON, with `_why_on`) | Verdict (GPU High, tb/item-scout-1108) | Row | Score | Prefer arm |
|---|---|---|---|---|
| `cloudreach_visual.json landmass.end_face_follows_row_1112` | G-below6-knifeedge (b4e9bdef) | F40#8 Three Bells bridge | 5.61 -> 6.37 | 3/3; road ends, overlook and aerie level (no loss) |
| `mushroom_pickup_variants.json perch_rim_cluster_1112` | G-below6-mushrooms (bc115978) | F40#17 High Perches rim | 6.01 -> 6.94 | 3/3, defect FIXED 3/3; High Perches views +0.28 (2/3) |

**1. Bridge strip.** The black strip across the grass at the Three Bells bridge foot was the end face of the route shoulder `BrokenCausewayMainCliffShoulders/Ridge000`, hung from a straight line between the row's two outer vertices and so standing up to 0.8 m above the pad crown. `scripts/world/cloudreach_world.gd _route_ridge`: with the flag on, each end face follows all seven row vertices. Render only; the collider is built from the top rows and is unchanged. The diff to `cloudreach_world.gd` is that one block (no other tb/below6 code).

**2. Rim mushrooms.** G-below6-mushrooms was a SPLIT, so only the part that gained ships: the natural patches apply at the three High Perches rim placements (`perch_rim_cluster_1112`, ON); the unscoped restyle `natural_cluster_1112` stays OFF (Meadows finds -0.74, 0/3). `scripts/world/mushroom_pickup_presentation.gd`.

**Tests:** `tests/test_below6_knifeedge_landed.gd`, `tests/test_cloudreach_end_face_flag.gd`, `tests/test_below6_perch_rim_landed.gd`, `tests/test_mushroom_natural_cluster.gd`; with the pickup and NEAR6-CR tests, 0 failed.

**Not closes:** F40#8's recorded defect stays PARTIAL (the anchor marker reads as a placeholder cylinder; needs an authored marker). F40#17 is a near-bar candidate at 6.94. F40#15's current-main read is 5.77 with its strips FIXED on base; the BELOW6-MASONRY arm targets what holds it.

This branch replaces `tb/below6-perchrim-land` (same rim content); that one can be deleted.
