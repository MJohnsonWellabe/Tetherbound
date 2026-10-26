# r33 (26 Oct): Lantern Pools finish, code-blind CPU

Arms: lane (merged head, baked forest present on both arms; both capture logs checked for a stale bake) against `stormwood_lantern_pools.json` with:
- **`lantern_model` ON:** the Meshy `stormwood_lantern_post` (tb/meshy-1024 a24b25f7a, concept c1_1). An aged timber post, carved bracket and hanging copper-and-glass lantern replace each box post. Lit panes glow through `warm_pane_glow.gdshader` (`glow_energy` 3.0), and a warm light hangs at the lantern (`light_energy` 3.0, range 10 m).
- **Black pools:** `deep_colour` #030607 and `water_specular` 0.12 (was 0.3), so the water stops mirroring the lilac sky as grey.

Stand: the F41 catalogue's Lantern Pools stand, three views, calm.

Yardstick: JUDGE_PROMPT v1, 3 fresh judges, 3 anchor pairs (craft, p2_094_r4, f36_0_npc C1), seed 3333. calibrate.py linear fit: slope 1.40, intercept -1.92, r 0.96, anchor RMSE 0.42, no warnings.

| Item | off (mapped) | on (mapped) | gain | judges (raw) |
|---|---|---|---|---|
| Lantern Pools | 4.83 | 5.58 | **+0.75** | 5.1->5.6, 4.5->5.1, 4.9->5.4 |

Recorded defects:
- Grey puddles: PRESENT 3/3 -> FIXED 3/3 ("near-black with a teal rim; matches the black-pools brief").
- Black-bar posts: PRESENT 3/3 -> PARTIAL 3/3 (the lantern head reads but is small at survey distance).

Still asked:
- larger, clustered black pools on the path;
- lantern light reading at distance;
- a moss and stone rim;
- breaking up the floor carpet;
- light shafts;
- the Meadows-style cottage at the path end (pools shelter).
