# Cloudreach look: `_excluded()` grid index (X05 F06#5 unblock, Cloudreach entry stall)

Base: main 32bd33079 (batch 26). 4-vCPU container, Godot 4.7-stable, headless.

Command (both runs, same checkout except `scripts/world/cloudreach_look.gd`):
`godot --headless --path . --script tests/probe_cloudreach_look_hash.gd -- --profile-realm-load`

The harness builds `cloudreach_cliffs.tscn` (whose own runtime dresses once) and then dresses a
second look node; `[cloudreach_look] cover ms` therefore prints twice. The hash covers the
probe's own look node: every Node3D transform and every MultiMesh instance transform, in tree order.

| | main `cloudreach_look.gd` | grid index |
|---|---|---|
| cover pass (1st / 2nd dress) | 158,948 / 161,576 ms | 20,129 / 20,760 ms |
| trees_stones | 320 / 412 ms | 35 / 41 ms |
| `dress()` total (probe's dress) | 162,654 ms | 21,466 ms |
| whole process wall clock | 6m35.6s | 1m59.0s |
| MultiMesh instances / Node3D | 663,250 / 3,879 | 663,250 / 3,879 |
| placement sha256 | `61638ff76ad510c955396187dc055960f6a59e05d4e7a74f71d43bff80343640` | **identical** |

Unit proof: `tests/test_cloudreach_look_exclusions.gd` compares the grid against the retained
linear walk (`_excluded_linear`) on 40,000 points (a quarter snapped to cell boundaries) over 70
shapes (segments incl. degenerate, rotated ellipses/boxes, a zero-axis ellipse, an INF box, a
non-Dictionary entry) = 0 mismatches; and an exclusion appended after the first query is seen.

Raw lines: `hash_before_main.txt`, `hash_after_grid.txt`.

## After independent review (APPROVE WITH NITS)
Applied: shapes whose box exceeds 1e7 m in any coordinate or covers more than 4096 cells (checked
in float, before `floori`) go to the always-checked list, so a huge finite half/half_width cannot
saturate the cell index; shared empty bucket; append-only assumption documented. The test gained a
1e30-half ellipse, a 1e300 half_width segment, and negative halves at ±π/2 and π: still 0
mismatches. Placement hash re-run: identical (`hash_after_grid_review_fixes.txt`, dress 20,665 ms).
