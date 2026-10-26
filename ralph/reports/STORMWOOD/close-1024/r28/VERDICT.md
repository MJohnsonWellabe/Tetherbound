# r28 (26 Oct): Fallen Giant hero, code-blind CPU

Arms: shipping (the installed `DeadTree_3` at 2x at the seat, `stormwood_destination_dressing.json fallen_giant`) vs `fallen_giant.hero` ON: the Meshy `stormwood_fallen_giant` (tb/meshy-1024 edd21e2f3; a hollow fallen log, 55 m long, about 35 m across and 23 m high) at (-180, 4492), yaw 250, hollow root end toward the approach, in the catalogue stand's view corridor (at the seat itself the grove hid it from 90 m). The grove trees inside its footprint are cleared on every shell (vegetation.gd clear_area, as the lantern pools do). Stand: the F41 catalogue's Fallen Giant stand (-240, 4463.6), headings 62.3 and 92.3, calm.

Yardstick: JUDGE_PROMPT v1, 3 fresh judges, 3 anchor pairs (craft, f36_0_gap C6, f36_0_npc C4), seed 2828. calibrate.py linear slope 1.282, intercept -1.863, r 0.77, anchor RMSE 0.52, no warnings.

| Item | off (mapped) | on (mapped) | gain | judges (raw) |
|---|---|---|---|---|
| Fallen Giant approach | 4.80 | 5.66 | +0.86 | 4.9->5.5, 5.3->6.0, 5.4->6.1 |

Landmark defect PRESENT 3/3 -> PARTIAL 3/3. Still asked: lift its value against the trunks (rim light, copper/glass or lightning accents), frame the road on it, texture the flat brown road, break the row-planted verge grass. Render-only: no collider on the log yet (collision scope stays pending, as the config documents for the dead tree).
