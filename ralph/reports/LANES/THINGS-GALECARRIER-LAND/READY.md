# THINGS-GALECARRIER-LAND: Galewisp flies as its 1 Nov remake, carrying from its feet

STATUS: land

- **Branch:** `tb/things-galecarrier-land`, cut from `origin/main` 6eae7917.
- **Verdict (LANE-SCOUT):** `G-faint2-medium-galecarrier.md` (`tb/item-scout-1108` 5f1f5ee2), GPU High: Galewisp in flight **6.17 → 6.83 (+0.66), 3/3 prefer the arm.** The judges read the remake as "a naturalistic owl-griffin" and the old carrier as a "chibi mascot" with undersized wings. The pose-stage row (F36#48) is unchanged at 7.44, because the stage already used the remake.
- **What was wrong:** `fly_traversal.json capabilities.galewisp.model` still named the pre-remake mesh, so Galewisp flew (and landed) as the old cartoon fox-bird while every other view showed the remake. Owner, 1 Nov: all remakes ON; no mascot or chibi. No capture showed it because every flight capture carried with Galecrest.
- **What ships (game, config only):** `data/config/fly_traversal.json capabilities.galewisp`: `model` to the remake GLB and `grip_bones` to `["foot_l", "foot_r"]`, each with a `_why`. Height, feet offset, wing flap, collision and stamina are unchanged. Galecrest is not touched.
- **What ships (capture tooling):** `tools/phase2_capture_realm_flight.gd --carrier=<species>` (default galecrest, so existing rows are unchanged).
- **Test added:** `tests/test_galewisp_carrier_is_the_remake.gd` (2): every carrier flies as the model its species ships; Galewisp's grip bones exist on that rig.
- **Tests run on this branch (per-file lines checked):** `galewisp_carrier_is_the_remake` 2, `fly_traversal` 16, `uiposes_fly_hang_body` 4: 22 tests, 0 failed.
- No texture is touched. No `.uid` files are included.

## Follow-ups named by the judges (not this landing)
- The talon grip does not read as a grip: the trainer looks dangled, not held (2/3).
- In the landing frame the creature is half hidden behind the trainer and a bush and looks barely taller than him (3/3). Creatures must stay taller than the trainer: check the landed presentation height.
- The flight backdrop is a flat fog plane with grey mountain cards (3/3): LANE-PLACES.
