# BELOW6-NAMEDPOSTS: a lantern post beside each named Stormwood villager (F41#8, 5.80)

**Flag:** `data/config/stormwood_character_presentation.json named_posts_1112` (OFF; overlay turns it on).
**Code:** `scripts/world/stormwood_named_posts.gd`, hooked in `stormwood_chapter.gd` after the character rim attach (local presentation only, no gameplay state). Test: `tests/test_stormwood_named_posts.gd` (2 tests pass).

**What it does:** Elder Maud, Rodkeeper Hesk and Warden-elect Bryn each get one installed storm-lantern post 1.9 m to their side, with a warm light (energy 4.2, range 11 m, `#ffc77a`). No new assets, no Meshy.

**CPU look** (`_sheet_cpu_base_top_arm_bottom.jpg`, base top, arm bottom): the black road around each villager becomes a warm brown pool, feet and legs separate from the ground, and the villager reads warmer than the cool background. Three placements tried; the first (light 2.2) did nothing visible, the second (6.0, post on the player's side) over-lit Hesk and lit the player more than the villager. This is the third.

**Not verified on CPU:** bloom on the lantern glass; whether the warm pool survives the GPU's storm grading. No CPU judge batch was run: the CPU score does not close the row and the change is plainly visible.

**Risks:** the post is tall and sits at the left edge of the subject crop; if the judges read it as clutter, pull `offset_m` out or lower the light. Hesk's pale coat is the nearest to over-lit.

**Expected gain:** over 0.5 (the row's complaint is figures lost against dark ground). Character side only; the road stays with LANE-PLACES.
