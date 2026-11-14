# LAND-MT-SHELLSHARDS (F38#30, BROKENHILL round 2): the crest shards and sky holes

**Row.** F38#30 Burrow Warrens hillside, 6.48 after BROKENHILL (#959). No-loss: F38#24 (walk_02 / walk_03), Warrens route_day, walk_01, vista_dusk.

**Defect.** The coordinator's round 2 asks were "floating crest shards" and "sky holes": pale-blue and dark angular chips scattered over the mound's crest and flanks (walk_02 top, route_day crest), with some apparently in open sky beside it.

**Cause (proved, five probes).**
- Ruled out, frames unchanged with each hidden: MoundGrowth, the shell's grass tufts and edge flora, InteriorRock, and the excavated chamber hulls.
- A magenta shell probe showed the chips are not lit shell surface. A crop of walk_02 shows they are *windows*: sky seen through holes in the shell, with the dark inside of the shell beside them.
- Mesh analysis of `burrow_hill_mound.glb`:
  - The mound is one 57,376-triangle body plus 276 detached islands. The islands are 2–4 m chips hovering 2–4 m off the surface.
  - The body is not watertight: it has 514 open loops on its flanks (up to 53 edges each), 3,590 open edges in all.

**Arm** (`overlay.json`; flag-off `bank.hill_shell.island_strip`, scope `client_presentation`). When the shell loads, the arm:
1. Drops every connected piece smaller than 1,000 triangles. This leaves exactly the main body.
2. Closes each open loop of up to 80 edges with a fan from its centroid, averaging the loop's attributes. Open edges go from 3,590 to 249; the rest are non-manifold tangles.

Cost: about 0.35 s once at Warrens load (CPU). The shell has no collider, so collision and routes are unchanged.

**Test.** `tests/test_hill_shell_island_strip.gd`: 3 tests, 0 failed. It runs on the real mound: 65,278 → 57,376 triangles, 3,590 → 249 open edges, and every attribute array stays sized to the vertex array.

**CPU before/after** (`_sheet_shellshards_off_vs_on_cpu.jpg`, left main, right arm; rows: route_day, vista_dusk, walk_01, walk_02, walk_03):
- walk_02: the pale-blue sky window and the dark triangle at the top are gone.
- walk_01 and route_day: the crest chips are mostly gone.
- Remaining: a few small dark slivers, and at dusk the crest still shows flecks. The flecks are the meadow-match tufts against a low sun (not touched here).
- Edge flora lands in different spots because placement samples the repaired mesh.

**By-eye line:** walk_02, the top of the frame. The sky-blue window and the black triangle in the hillside should be gone.

Still open from the round 2 list: walk_03's straight base edge, and the solid smoke column. The smoke is `Props/warrens_vault_signal/.../CampfireGlow/Smoke*`, a world prop outside the shell.
