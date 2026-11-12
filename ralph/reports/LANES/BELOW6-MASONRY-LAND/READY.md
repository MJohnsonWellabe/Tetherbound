STATUS: land

# tb/below6-masonry-land: Cloudreach wall stones at human scale (F40#15)

**Verdict:** GPU High, G-below6-stormraven-masonry (`ralph/reports/GPU-PASS/1108/G-below6-stormraven-masonry.md` on tb/item-scout-1108 832aaa06): F40#15 5.17 -> 5.54 (+0.37, 3/3): base's wall stone is "very large for the trainer, oversized and soft", the arm's smaller stones "read as built masonry". Overlook routes +0.18 (2/3). Sky Shrine and aviary score identically (no loss).

**Flag:** `data/config/cloudreach_visual.json masonry_scale_1112`, ON with `_why_on`: the shared masonry brick repeats every 1.4 m (was 3.6 m) and the wall stone is a step lighter.
**Code:** `scripts/world/cloudreach_world.gd`, one block where the two shared masonry materials are built (the only diff to that file).
**Tests:** `tests/test_below6_masonry_landed.gd` (pin), `tests/test_cloudreach_masonry_scale_flag.gd`.

**Scope:** material values on every Cloudreach masonry and trim piece. No mesh, collision or placement change.

**Not a close:** F40#15 is still below 6 (pooled current main about 5.47). What holds it (3/3): no built kerb or lip where the grass meets the cloud sea, orange haze on the aerie vista, floating box walls and flat banner cards. The judges also saw, on both sides, a large semi-transparent amber pane and a white glowing sphere in overlook `walk_02_day` (an occluder fade or debug volume); not from this change.
