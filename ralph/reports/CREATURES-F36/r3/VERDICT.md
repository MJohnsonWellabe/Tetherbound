# CREATURES-F36 r3: side-lie faints for Cliffspike and Thundertunnel vs CO12 (CPU, three judges)

**Verdict: both regress. Not sent to the GPU.**

Control: CO12 (`tb/co12-main-on` e5fcc1c47, landing on main as PR #780). It was the coordinator's base for these species after the 31 Oct GPU verdict.

| Species | Change | Mapped CO12 | Mapped arm | Gain | Defect (CO12 / arm) |
|---|---|---|---|---|---|
| Cliffspike | faint pivot roll −70° (the +70° screen barely moved the quill dome) | 6.92 | 6.58 | **−0.34** | crouch faint PARTIAL x3 / PRESENT 2, PARTIAL 1 |
| Thundertunnel | faint pivot roll +70° (the −70° screen went belly-up, legs in the air) | 6.64 | 6.20 | **−0.44** | faint barely differs PARTIAL x3 / PRESENT 1, PARTIAL 2 |

- **Fit:** linear, slope 0.93, intercept 0.63, r 0.78, RMSE 0.59. Confirming batch (craft, f36_0_npc:C1). No warnings.
- **Raw scores:** in `batch.json`.

**What the judges saw:**
- On both species the roll lifts the body: the underside comes off the stage and the shadow separates, so the faint reads as a hop, a roll or a rear, not a collapse.
- CO12's own head-tucked slump scores higher.
- For quilled or domed bodies, a grounded collapse needs authored bones: the legs fold out and the flank settles. A whole-body pivot alone can't do it, the same lesson as Mosshell's shell.

**Next asks from the judges** (not pose changes):
- Thundertunnel: lift the dark body value and give it readable eyes. On CPU this is still "very dark, close to the backdrop".
- Cliffspike: group the quill colour, and lift the value of the skin.

**Stop-rule count:** round 1 under 0.5 (a regression) for Cliffspike and Thundertunnel faints. The pivot-roll approach is dropped for both.

Sheet `_sheet_r3.jpg`: CO12 on the left, arm on the right; rows are Cliffspike and Thundertunnel. Tiles: standing, hit 050, faint 050, faint 100.
