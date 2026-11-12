# G-closeout-f38-20-f38-3: F38#20 stronghold and F38#3 Meadows fight camera, High and Medium side by side (GPU close calls)

## Verdicts
- **F38#20 CLOSES** at exactly the bar on both presets.
- **F38#3 does not close.**

| Row | Panel | High | Medium | Control F38#38 |
|---|---|---|---|---|
| **F38#20** Team Tether stronghold | G-below6-sea-r4-stronghold (arm, High only) | 7.57 | — | — |
| | **This batch** | **7.50** (7.45, 7.17, 7.87) | **7.50** (7.45, 7.17, 7.87) | 7.92 |
| | **Pooled** | **7.54** | **7.50** | |
| **F38#3** fight camera and creature scale | G-things-foestand (arm, High only) | 7.61 ↑top | — | — |
| | **This batch** | 6.89 (6.89, 6.61, 7.17) | 7.03 (6.89, 6.75, 7.45) | 7.92 |
| | **Pooled** | 7.25 | 7.03 | |

- **Control.** F38#38 read 7.92 against its closing 8.16/8.30, so this panel is about 0.3 strict. It is stricter than G-closeout-f38-4-map (8.00).
- **Confirming batch.** The anchors include craft (7.35) and f36_0_npc:C1 (7.47/7.53). Neither row is above the top anchor here.
- **Fit:** linear, slope 1.404, intercept −1.812, r 0.987, anchor RMSE 0.16.

## F38#20 stronghold: closes, with no margin
- **This batch meets the bar on both presets:** a raw mean of 6.633 maps to 7.4999… → 7.50. `calibrate.py` reports `meets_bar: true`.
- **The score holds.** With a control that reads 0.3 strict, and the earlier arm panel at 7.57, the 7.5 holds. But it is the thinnest close tonight; a stricter panel could drop it below 7.5 at Medium.
- **The judges score High and Medium identically** (render difference 4–9, mostly grass motion).
- **Recorded defect:** PARTIAL 3/3. The approach now reads as "a tall crenellated castle with lit windows on the horizon, not a small ruin behind pylons", which is FIXED. The interior still "reads as a stage set".
- **Next lever, if margin is wanted (3/3, scene):**
  - re-texture the interior props to the muted shared prop family and place them in authored clusters (they are "uniformly saturated orange ... evenly scattered");
  - tone down the blown-out fire and window glow at night;
  - the castle is still small in frame (1/3).
- **Basis.**
  - The High side is `G-below6-stronghold-stand-r2`'s arm (stand (0, 7130); `tb/below6` d4801ed9a, which is game-identical to main for this tool).
  - The Medium side is `G-closeout-f38-20-medium` on main 1c81cdb45 (#933, stand ON).
  - The coordinator notes main has since moved to 6693348aa (#934), whose only non-water change is a flag-gated swim pose, so these Meadows frames are unaffected.

## F38#3 fight camera: open
- **Both presets are below 7.5.** The High arm frames that read 7.61 in G-things-foestand read 6.89 on this stricter panel. The same frames dropped 0.7 between panels, so the 7.61 was not a stable bar read.
- **Recorded defect:** PARTIAL 3/3. "The ally is not oversized"; trainer, ally and opponent all show in every frame. Minor overlap remains between the trainer and the dog's legs (1/3).
- **What holds the row now (3/3, scene):**
  - **The dust-trail effect.** "Strings of pale dotted beads loop across the ground and over the bodies of both creatures ... a placeholder path or debug effect, not a real object with an impact". The judges ask for short, grounded dust-and-stone bursts at the point of contact. This is cause T-TELEGRAPH, and the strongest lever for this row.
  - **A murky olive grade with little rim light.** Terrapup's black coat merges with the dark grass (T-DARKRIM).
  - **HUD.** The bottom panels take about a third of the frame.
  - **Clipping (1/3).** In High frame 3 Terrapup's head and forequarters "seem to sink or clip down into the ground".
- **Basis.**
  - The High side is `G-things-foestand-meadows`'s arm (`tb/things` 8cb498dba plus `overlay_opponent_stand.json`).
  - The Medium side is `G-closeout-f38-3-medium` on main 1c81cdb45 (opponent stand ON).
  - Render difference about 20 per frame, which is fight timing (a different moment in each capture).

## Frames
- **F38#20:** stronghold approach day and night, plus landmark stronghold day approach, stacked.
- **F38#3:** south_bridge_grunt-01/02/03, stacked.
- **F38#38:** the closing High and Medium crafting frames (`gpu-frames-1108/F38-38/live`).
- **Sets:** High on one side and Medium on the other. Briefs and recorded defects come from job.json.

## Batch `G-cc`
- Three code-blind judges, standard prompt, three candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- Yardstick: `yardstick_g_closeout_f38_20_f38_3/`.

**Raw Bar A (judges a, b, c):**

| Row | High | Medium |
|---|---|---|
| F38#20 | 6.6, 6.4, 6.9 | 6.6, 6.4, 6.9 |
| F38#3 | 6.2, 6.0, 6.4 | 6.2, 6.1, 6.6 |
| F38#38 | 7.2, 6.8, 6.8 | 7.2, 6.8, 6.8 |

Bar B for F38#20: yes from 2/3 ("the warm golden-hour approach to a lit castle ... carries it").
