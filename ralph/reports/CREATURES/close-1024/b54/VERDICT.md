# b54: Mirejaw dark cell fill warmed to olive-umber vs main (CPU, three judges)

Candidate: 2c79bf6d. Coordinator brief after GPU CO8 (main 6.53; the r2 retexture lost -1.08 because it replaced the pattern): keep main's reticulated pattern, warm its dark fill toward olive-umber, lift the back values at faint end.

`candidate/retex/grade_fill.py` changes only the near-black cell fill on main's own albedo:
- Texels under value 0.36 (feathered from 0.26) and under saturation 0.45 go to hue 42 at saturation 0.34, with value x1.45 + 0.03.
- Pupils and the mouth line (under 0.08) stay black.
- The tan net, cream belly and amber frills keep their pixels.
- Reserved red band 0.33% -> 0.27%. The f36 pin is updated.

Stage: standing, hit-050, faint-050, faint-100. Sheet `_sheet_b54.jpg`: main | candidate.

Anchors: craft, f36_0_gap:C2, f36_0_npc:C3. Fit: slope 1.68, r 0.90, RMSE 0.53, **confirming**.

| side | mapped (j1, j2, j3) | mean | dark back does not read at faint end |
|---|---|---|---|
| main | 5.38, 5.38, 5.55 | 5.44 | PRESENT x3 |
| olive fill | 6.73, 6.39, 6.56 | **6.56** | PARTIAL x3 |

Call: **+1.12, GPU READY.** Judges: the olive-tan fill "restores the value split from the cream belly" and the cells "read as plates".
- Remaining: at faint end the back is "still darker, somewhat muddy" (3/3), and the pattern reads "as a decal" (2/3).
- A further value lift on the back is the next step if the GPU agrees.

Checks: `run_tests --only=f36_pose,texture_import,colourway,water,species`: 546 tests, 0 failed.
