# r30 (26 Oct): Lantern Pools hollow, code-blind CPU

Arms: lane `tb/stormwood` (pools as flat discs with stones and posts, `stormwood_lantern_pools.json`) vs the same with `basin`, `glow_fungi` and `grove` ON:
- **Grove:** 68 storm-canopy trees, the Ash Road layer's own models and tints. They stand 24-62 m round the pools, clear of every route, seat, cluster, arch, camp and the shelter, with trunk colliders on every shell. Two trees near the catalogue cameras were removed after judging, leaving 66.
- **Basins:** the Meshy root-rimmed basins, seated so only their slab sinks.
- **Glow fungi:** bioluminescent storm fungi on each basin rim.

Stand: the F41 catalogue's Lantern Pools stand (-380, 1400), three headings round 43 degrees, calm.

Yardstick: JUDGE_PROMPT v1, 3 fresh judges, 3 anchor pairs (craft, f10_2_r3_capacitor, f36_0_gap C6), seed 3030. calibrate.py linear fit: slope 0.885, intercept 1.10, r 0.71, anchor RMSE 0.84 (WARNING: above 0.75, so report with this caveat).

| Item | off (mapped) | on (mapped) | gain | judges (raw) |
|---|---|---|---|---|
| Lantern Pools | 4.40 | 5.55 | +1.15 | 3.8->5.0, 3.8->5.3, 3.6->4.8 |

Recorded defects:
- Open meadow: PRESENT 3/3 -> FIXED 3/3.
- Pools: PARTIAL/PRESENT -> PARTIAL 2, PRESENT 1. They are "small, partly hidden behind mushrooms and roots".
- Lantern posts: still PRESENT 3/3 ("black bars").

Still asked:
- larger black glossy pools;
- real lantern meshes in place of the posts;
- a broken-up floor;
- the canopy family's flat mauve trunks and leaf cards (every Stormwood stand shares them);
- light shafts.
