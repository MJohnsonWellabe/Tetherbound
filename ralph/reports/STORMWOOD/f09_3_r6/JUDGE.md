# F09#3 round 6 — code-blind judge (judge 14)

Frames: render.yml run 36269371056 on main 32bd33079 (round 6 plus the round-5 light shafts, scatter bake fresh), `tools/capture_stormwood_pocket_walks.gd`, 20 frames, 0 capture failures (`pocket_walks/frames_walks.json`).
Judge: a code-blind subagent. It saw only the 5 road-lure and 5 mouth frames, shuffled and renamed (`blind_map.json` maps them back). Question per road view: would an ordinary player notice a side place worth a detour here? Target: at least 4 of 5 YES.

| Pocket | Road view | Verdict | Judge's reason (condensed) |
|---|---|---|---|
| conductor_ridge_cleft | A | **YES** | A cyan beam centred between two trunks, with paired lanterns and a bright stepped patch: reads as a gateway. |
| deepwood_ridge_shelter | B | PROBABLY | Lanterns on a dead tree, but the warm beam is partly hidden behind the trunk (reads as glare). No trail visible. |
| verge_ash_hollow | C | AMBIGUOUS | Faint yellow shaft at left-centre. The stone strip reads as a crossing road, and the red-roofed house at the vanishing point pulls the eye. |
| hollows_moss_nook | D | PROBABLY | A thin green-yellow beam, washed out against the grey horizon. Nothing leads toward it. |
| dynamo_scorch_pen | E | NO | Two small lanterns high at the top right, too far away. No beam or trail visible. The cyan crystals compete. |

**Result: 1 of 5 YES (plus 2 PROBABLY). F09#3 NOT MET.** Judge 13 on round 5 gave 3 of 5.

Gates: all five read as reward places. Defects:
- Crystals float or clip slightly (gates 1, 2 and 5 = Hollows, Conductor, Verge).
- The beam is cut off at the top of the frame (Hollows, Dynamo).
- The cobbles end short of the gap and never merge with the dirt lane (all five).
- Hollows, Conductor, Deepwood and Verge are one repeated stamp; Dynamo differs slightly.

Next round (7), from the judge's first-priority note:
1. Make the beam brighter and more saturated against the pale horizon, and keep it in the road camera's clear sightline (not behind the gate trunk).
2. Show the trail start where it meets the road's dirt (the cobbles reach the road edge and join it).
3. Dynamo: the lanterns are too high and too small from the stand (the gate sits in the top band on the slope). Lowering it depends on the open "lantern head ≥ 2.4× trainer" design call.
4. Verge: a red-roofed house at the vanishing point competes for the eye.
5. Give each gate its own silhouette.
