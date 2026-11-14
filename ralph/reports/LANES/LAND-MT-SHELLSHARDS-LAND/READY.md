# READY: tb/land-mt-shellshards-land

STATUS: land. GPU-judged ship (LANE-JUDGE G-land-mt-shellshards-ss, tb/judge 4db78c054, 14 Nov).

**Verdict.** All 3/3:
- F38#30 5.44 -> 5.98 (+0.54); the floating pale shards and back-face slivers are gone.
- Warrens other frames +0.59.
- F38#24 no-loss +0.28.

**What.** `bank.hill_shell.island_strip` ON. When the Warrens hill shell loads, the Meshy mound mesh is repaired in two steps:
1. Every connected piece under 1,000 triangles is dropped, with vertices welded by position. These are 276 detached 2-4 m islands floating off the surface (the crest shards). Exactly the 57,376-triangle main body stays.
2. Each open boundary loop of up to 80 edges is closed with a fan from its centroid, attributes averaged and winding matched. These are 514 loops on the flanks where the sky showed through. Open edges go from 3,590 to 249; the rest are non-manifold tangles.

Cost: about 0.3 s once at Warrens load on CPU. The shell has no collider, so collision, routes and saves are unchanged. Presentation only.

**Files.**
- `scripts/world/burrow_warrens.gd`: `strip_mesh_islands`, `fill_mesh_holes`, `_append_loop_means`, `_uf_find`, and the call site in `_build_hill_shell`.
- `data/config/burrow_warrens.json`: the `island_strip` block, ON, with `_why_on`.
- `tests/test_hill_shell_island_strip.gd`: the pin. It runs on the real mound: strip and fill counts, attribute sizes, and the config ON with the verdict cited.

The lane's later flag-off steep-face grass work is **not** in this branch.

**Tests run** (headless; this branch's config and test run on the lane checkout, whose shell code matches plus flag-off extras): 12 tests, 0 failed.

| Test file | Tests | Assertions |
|---|---|---|
| `test_hill_shell_island_strip.gd` (pin; SceneTree script) | 3 | 0 failed |
| `test_warrens_meadow_match.gd` | 3 | 19 |
| `test_warrens_hill_shell_r2.gd` | 2 | 7 |
| `test_warrens_hill_foundation.gd` | 3 | 7 |
| `test_warrens_shell_seat_f38_30.gd` | 1 | 4 |

**Next asks from the verdict (lane follow-up):**
- the dark toe cut at the slope base (walk_03);
- the remaining crest debris;
- a higher-frequency rock and moss material;
- one continuous smoke plume (PLUME did not ship);
- a warren entrance hero piece (new art).
