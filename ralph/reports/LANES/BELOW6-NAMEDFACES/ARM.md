# BELOW6-NAMEDFACES: the named Stormwood villagers' faces stop clipping to white (F41#8, 5.92)

**Flag:** `data/config/stormwood_character_presentation.json named_tint_1112` (OFF; overlay turns it on).
**Code:** `stormwood_character_presentation.gd decorate` sets the model `tint` for a listed identity. Test: `tests/test_stormwood_named_tint.gd`.

**Why:** G-below6-namedposts (3/3, base and arm): "speakers' faces burn orange-white". Two CPU checks ruled out the usual causes: emission floor 0 for the three (no change) and the character rim at 0.2 (near-white pixels 6.7 -> 6.3% on Maud, faces still white). The skin textures are not bright (p99 value 0.69-0.76), so it is the storm light on pale skin and hair.

**What it does:** multiplies each body's albedo by a neutral grey: Maud `#a8a8a8`, Hesk and Bryn `#b0b0b0`.

**CPU look** (`_sheet_cpu_base_top_arm_bottom.jpg`, dialogue crops, base top, arm bottom). Near-white pixels in the crop: Maud 6.7 -> 4.8%, Hesk 5.8 -> 3.2%, Bryn 3.8 -> 1.6%. Skin tone, cheeks, beard and brow now read on all three; Maud's hair is off-white with strands. No CPU judge batch was run.

**Rides along (direct data fix, on base and arm):** Hesk's dialogue portrait. With `distinct_bodies_1111` ON he stands on the alpha_tracker body, which had no entry in `plates_by_profile`, so his lines kept `villager_male` (the dark-haired boy the judges named). He now gets the installed alpha_tracker plate `sorrel.png`; lost_traveler gets `tobin.png` as its profile fallback. Bryn's lines already resolved to `meshy_f41_8_bryn.png` (checked through `apply_npc_portraits` and the capture manifest), so nothing changed for him. Test: `tests/test_stormwood_distinct_body_portraits.gd`.

**Not touched:** the player's bloom, the repeated background sentinels (new art), the bear and wolf colours, the road.

**Dropped:** `named_posts_1112` (G-below6-namedposts, -0.49 and -0.73). Its flag stays OFF.

**Expected gain:** over 0.5 on the dialogue frames (the same defect class as Marrow's head, +1.40); less on the wide row frames.
