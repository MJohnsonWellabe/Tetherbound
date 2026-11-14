# G-closeout-f38-10-panels: F38#10 close-out, all three panels at High and Medium (+F38#38 control)

## Verdict: NOT CLOSED. F38#10 maps to 7.39 on both High and Medium.

| Set | High | Medium | Raw a / b / c | Defect |
|---|---|---|---|---|
| **F38#10** Build, Players and Quest Log | **7.39** | **7.39** | 6.6, 7.0, 6.6 (both presets) | PARTIAL 3/3 |
| Control F38#38 craft hints | 7.63 | 7.63 | 6.8, 7.2, 6.8 | FIXED 3/3 |

- **Panel strictness:** the control reads 7.63 against its closing 8.16 and 8.30, about 0.6 strict. That is stricter than this afternoon's batches, which read 8.01. The craft:after anchor also mapped 0.75 below its reference.
  - Even allowing for that, the judges' finding is consistent and specific. With all three panels in view, Players and Quest Log pull the row down from the Build-only 7.75 to 7.39.
- **Presets:** the judges see no difference between High and Medium.

## What the judges see (3/3)
- **Build:** "well filled with three illustrated cards".
- **Players and Quest Log:** both "still leave the lower third to half of the panel empty" below a few rows of text. That is the recorded defect, so it is PARTIAL, not fixed.
- **Style:** on direction. Blue-grey translucent panels, teal selected tab, gold headers, controller shoulder and face glyphs, and a painted meadow header (3/3 bar B yes).
- **Not marked down:** the Players panel's "network port could not be opened" line, which comes from the capture PC (GPU lane disclosure). No judge marked it.

## Frames and batch
- High:
  - menu_build from G-rescore-f38-19-c673 (7285d72d5).
  - menu_players and menu_quest_log from G-closeout-f38-10-panels-high (902eff4e2).
- Medium: all three panels from G-closeout-f38-10-panels-medium (27df65c8d).
- Content: main 4f9ae9e2a, one side.
- Batch `yardstick_g_batch5_1113/`:
  - Anchors: craft, f36_0_npc:C1, f04_6_r22.
  - Fit: linear, slope 1.184, intercept −0.585, r 0.925, anchor RMSE 0.38.
  - Confirming batch; the control is above the top anchor.

## Next asks (LANE-SCENE)
1. **Fill the lower third to half of the Players panel:** for example a party card per slot with an invite card, or the illustrated empty-state card that Build uses. Scene.
2. **Same for Quest Log:** quest cards with a region thumbnail or a progress strip, instead of a few text rows over empty panel. Scene.
3. **Re-capture all three panels at both presets** and close in one batch with the F38#38 control. Build alone already reads 7.75.
