# r27 (26 Oct): Stormheart round 2 (hollow-floor roots, core arcs), code-blind CPU

Arms: r19 on (hero interior) vs r27 (+ `hero_interior.round2`: 20 bark roots from the wall foot across the floor, diving into it as they thin; four thin white-violet arcs winding around the core column, hidden after release). Catalogue stand v02 and v04, calm, stacked.

Yardstick: JUDGE_PROMPT v1, 3 fresh judges, 3 anchor pairs (craft, f36_0_npc C2, f36_0_gap C1), seed 2727. calibrate.py linear slope 1.346, intercept -1.914, r 0.94, anchor RMSE 0.29, no warnings.

| Item | r19 (mapped) | r27 (mapped) | gain | judges (raw) |
|---|---|---|---|---|
| Stormheart interior | 5.13 | 5.54 | +0.41 | 5.2->5.6, 5.3->5.4, 5.2->5.6 |

Core defect PRESENT -> PARTIAL 3/3 ("now reads as lightning, but crude: flat uniform-width white polylines around the same bloomed pillar"). Floor defect PRESENT 3/3 on both: the roots were not read as a root floor (two judges saw "log props sticking out at odd angles"). Under +0.5: OFF, the first round under 0.5 for this approach. Shared asks: root-woven heartwood or plank floor instead of the dirt disc and grass ring, warm amber lanterns and stacked deck tiers for verticality, branching tapered violet-white lightning with a floor impact. Waiting on the GPU SW7 verdict for r19 before the next Stormheart swing.
