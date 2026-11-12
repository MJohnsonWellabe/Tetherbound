STATUS: land

# tb/below6-swim-land: the swimmer shows a body and a stroke (F39#5, F39#14)

**Verdict:** GPU High, G-below6-swim-sea-r5 (`ralph/reports/GPU-PASS/1108/G-below6-swim-sea-r5.md` on tb/item-scout-1108 5c800b97): F39#5 5.45 -> 5.98 (+0.53, 3/3), F39#14 5.74 -> 6.12 (+0.38, 3/3). The pose reads as "arms spread at the surface"; the defect goes PRESENT -> PARTIAL.

**Flag:** `data/config/human_swim_visual.json surface_crawl_1112`, ON with `_why_on`.
**Code:** `scripts/player/trainer_model.gd` (the flag's `swim_pose` is merged last; `arm_recover_lift` and `arm_reach_scale` keys, both no-ops at their defaults).
**Tests:** `tests/test_below6_swim_landed.gd` (pin), `tests/test_surface_crawl_flag.gd`; with `test_human_swim_visual.gd` and the swim tests: 0 failed.

**Scope:** pose keys only. Capsule, camera, speed, stamina and the network packet are unchanged; a remote trainer runs the same pose code from the packet it already gets.

**Known remainders (3/3, for whoever takes F39#5 next):** boots show as dark blobs behind the head, a radial pinwheel seam in the wake foam at surface_west, a soft smear on the near-camera water. The −0.29 on surface_east/surface_far is a capture confound (a different shore creature between runs).

Both rows are still below 7.5; this landing is a judged gain, not a close.
