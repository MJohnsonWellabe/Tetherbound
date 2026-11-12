# BELOW6-MUSHROOMS: mushroom finds become small natural patches (F40#16 6.19, F40#17 6.08)

**Flag:** `data/config/mushroom_pickup_variants.json natural_cluster_1112` (OFF; overlay turns it on).
**Code:** `scripts/world/mushroom_pickup_presentation.gd` (`_swap_silhouette` cluster copies, `_tint`). Test: `tests/test_mushroom_natural_cluster.gd`.

**Why:** F-cloudreach (8-9 Nov), 3/3 on both rows: the placement defects are FIXED, and what holds the rows is that the caps are "oversized and toy-saturated against the stylised-realism direction" (cluster T9 in CLUSTERS-6TO7).

**What it does:** the single large cap is hidden (it stays for interaction and grounding) and the find shows a patch of the installed `stylized_nature` mushrooms:
- Speed: five `Mushroom_Common`, slate blue `#8fa3c4`, tallest 0.62x the old cap.
- Stamina: the same patch in ochre `#d9b56e`.
- Wild: three `Mushroom_Laetiporus` shelf fungi, rust-orange `#d99a62` (no red).
The existing contact shadow, pebbles and clover stay. No new assets, no Meshy.

**CPU look** (`_sheet_cpu_base_top_arm_bottom.jpg`; base top, arm bottom; Speed left, Wild right): the knee-high yellow and orange toy caps become low patches with separate caps and stems. Speed and Wild now differ in silhouette as well as colour, which is F40#16's own recorded defect. No CPU judge batch was run, and the High Perches rim frames were not captured on CPU.

**Risks:** the Speed patch is small and pale; earlier GPU passes called finds "pinhead-sized" before the size step. If the judges cannot find it, raise `height_scale`.

**Scope:** the presentation is shared by Meadows, Cloudreach and Stormwood mushroom finds.

**Expected gain:** over 0.5 on F40#16 (silhouette defect plus the toy read); about 0.5 on F40#17.
