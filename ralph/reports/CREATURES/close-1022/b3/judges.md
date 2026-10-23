# b3 per-judge verdicts (three code-blind judges, standard prompt; key in key.json)

Sets: Vh = Riverdrake (A live, B c4); Os = Mirejaw+Voltarach (A live, B c4); Sw = F29#3 bears (A live, B c4);
Io = Meadowhart (A live, B c4). Anchors: Uj f36_0_npc:C1, Pn p2_094_r4, Rl craft, Ur f36_0_gap:C7.

| Set/side | j1 Bar A | j2 Bar A | j3 Bar A | Defect outcomes j1 / j2 / j3 |
|---|---|---|---|---|
| Vh A (live) | 6.6 | 6.4 | 6.2 | hit-as-standing PARTIAL/PRESENT/PRESENT; recover=standing PRESENT x3 |
| Vh B (c4) | 7.2 | 7.0 | 6.8 | hit-as-standing FIXED x3; recover=standing FIXED/FIXED/PARTIAL |
| Os A (live) | 5.2 | 4.6 | 4.4 | hit PARTIAL/PRESENT/PRESENT; no-faint PRESENT x3; dark melt PRESENT x3 |
| Os B (c4) | 6.3 | 5.8 | 6.1 | hit FIXED x3; no-faint FIXED x3; dark melt FIXED x3 (all three: palette now blown-out/plastic) |
| Sw A (live) | 6.2 | 5.9 | 5.6 | cub=adult PRESENT x3; hit/recover PRESENT x3 |
| Sw B (c4) | 6.7 | 6.4 | 6.0 | cub=adult PRESENT x3; hit/recover PARTIAL x3 |
| Io A (live) | 6.4 | 5.8 | 6.0 | hit PRESENT x3; antlers-through-floor PRESENT x3; faint-mid-standing PRESENT x3 |
| Io B (c4) | 7.2 | 6.9 | 7.0 | hit FIXED x3; antlers FIXED x3; faint-mid FIXED x3 (j1, j2: faint end overlaps the stage ruler) |
| Uj A/B | 7.3/7.3 | 7.4/7.4 | 7.3/7.3 | anchor |
| Pn A/B | 4.0/5.8 | 4.8/6.3 | 4.7/6.3 | anchor |
| Rl A/B | 4.8/6.6 | 4.8/6.6 | 5.0/6.8 | anchor |
| Ur A/B | 6.3/6.6 | 5.6/6.0 | 5.6/6.2 | anchor |

Top asks (all three):
- the cub needs its own smaller, rounder mesh (new art);
- rebalance creature materials to mid-value designed blocks with a soft rim (lift dark, tone down blown-out);
- the homestead wall and craft panel asks belong to the anchors only.

GPU follow-up (coordinator, tb/gpu-pass 6ddeda1b7 F36-0/r3-candidates): Meadowhart 7.22-7.28, Riverdrake 7.39,
both under 7.5, so these recipes stay OFF (`--candidate-1022`).
