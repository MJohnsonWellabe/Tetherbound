STATUS: land (capture-stand fix by coordinator call, 11 Nov; no score claim)
BRANCH: tb/item-skyroad-stand

F40#0 Cloudreach re-capture failed on all 32 broken_causeways__04__broken_skyroad_arch frames. The cause is the
catalogue stand (365, 1925): it is off the arch's isolated ~26 m crown disc (x 338..362, z 1924..1948, h 480), so
production ground_height_at returns NaN there (diagnosis: tb/item-hollows-trunk ITEM-SKYROAD-STAND/NOTE.md).
Fly flights from the aerie get over the crown but cannot land reliably (stamina, then void recovery).

Coordinator ruling: a capture-stand problem, not a world change.
- data/config/debug_teleport_spots.json: Broken Skyroad Arch stand (365, 1925) -> (357, 1933), heading -42
  (same sight line to the arch). It is on a grounded, teleport-walkable crown cell (CPU ground map); the 12 m approach
  falls back inward to grounded crown cells.
- data/config/cloudreach_world.json: broken_skyroad_arch requires_traversal "ground" -> false.
- tests/test_cloudreach_broken_skyroad_arch.gd: the stand is pinned at (357, 1933) and asserted to be on the crown
  disc (it was "> 20 m from the landmark", which a 26 m disc cannot hold).

Checks: --only=cloudreach_broken_skyroad_arch,cloudreach_world_data,cloudreach_old_wind_observatory
21 tests, 0 failed.
Re-run: capture_cloudreach_f40_matrix.gd --piece=29-36 (the 32 arch frames).
