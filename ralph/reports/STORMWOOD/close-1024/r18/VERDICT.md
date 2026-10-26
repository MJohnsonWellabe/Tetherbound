# r18 (25 Oct): Meshy big-swing candidate, code-blind CPU

Arms: lane tree with every r18 flag OFF (= main + land5) vs the same tree with the r18 flags ON (`overlay`: heartstone `hero`, Stormheart `meshy_interior`, `cottage_interior_finish.enabled`). Same stands as r16/r17 (wo6: hs1/hs2, sh3/sh6, ash_in), calm, CPU Compatibility 1280x720. Pool basin (`stormwood_lantern_pools.json basin`) left OFF: invisible after two seating attempts (buried by the terrain); not judged.

Yardstick: JUDGE_PROMPT v1, 3 fresh judges, 4 anchor pairs (craft 7.35, f10_2_r3_capacitor, f36_0_npc:C5, f36_0_gap:C2), seed 1818. calibrate.py linear slope 1.188, intercept -0.740, anchor RMSE 0.659, no warnings.

| Item | off (mapped) | on (mapped) | gain | judges (on) |
|---|---|---|---|---|
| Ashfoot inside | 4.33 | 6.07 | +1.74 | 5.91 / 5.91 / 6.39 |
| Stormheart interior | 4.37 | 5.12 | +0.75 | 5.20 / 4.96 / 5.20 |
| Crown heartstone | 3.89 | 4.60 | +0.71 | 4.37 / 4.60 / 4.84 |

Remaining defects named by all three: Stormheart wall panels read as a repeated tiled strip and the walls above stay smooth; heartstone is trainer-height and unframed, flat grey horizon, wild herds in view; Ashfoot over-warm flat light, pale floor rug patch. The heartstone frames were captured before the fix that restored the stone's own light (the hero branch had skipped the light and prompt; fixed and covered by smoke_stormwood_crown_heartstone 12/0 with the hero ON and OFF).
