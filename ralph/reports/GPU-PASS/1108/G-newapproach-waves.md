# G-newapproach-waves: owner's design, "which way the waves move" as the in-water current cue (CARD:T2, F13#5)

Frames: `tb/gpu-frames-1108` dabeb818, High, with the current arrow OFF on both sides.
- **Base:** main ded3c30f6 plus `water.gdshader`, `water_surface.gd` and the capture tool at tb/newapproach 64dab56f0.
- **Arm:** base plus `NEWAPPROACH-WAVES/overlay_lane_waves.json` with lane_crest 0. The re-shoot after lane_crest 0.3 smeared.
- **Swimmer views** (swim-away-day, swim-across-day, swim-away-night): 10-frame strips at 0.1 s per step, plus GIFs.
- **Dock frames** (`-docks`, catalogue mode): not judged. As stills they barely differ (absdiff 0.05–0.41), and the question is about motion.

## Pre-judge check
- **The stills are essentially identical** between base and arm, as the GPU lane said. A side-by-side check confirms it, so a standard look-score batch would compare near-identical images and was not run.
- **Automated motion estimate:** phase correlation over water crops gave no usable shift in 5 of 6 crops, swamped by static content. The lane's own block-match was also inconclusive.
- **The blind direction test** is therefore the evidence.

## Blind direction test (motion strips)
- **Strips:** each was a water crop around the swimmer at five moments (t = 0, 0.2, 0.4, 0.6, 0.8 s), stacked top to bottom with time labels.
- **Six strips** (3 views × base/arm) were shuffled and unlabelled for three fresh judges. The judges could not view the GIFs, because their image reader takes stills only.
- **Asked per strip:** direction, confidence, whether the water visibly moves one way, and 7-inch readability.
- **Truth** comes from `NEWAPPROACH-T2/direction_test.json`: swim-across = RIGHT; both swim-away views = TOWARD_CAMERA.
- **Data:** `yardstick_g_waves/direction_test_strips.json`.

| View | Side | Correct | Answers (j1, j2, j3) | Mean confidence | Mean readability |
|---|---|---|---|---|---|
| swim-across-day | base | **3/3** | RIGHT, RIGHT, RIGHT | 7.0 | 5.7 |
| swim-across-day | arm | **3/3** | RIGHT, RIGHT, RIGHT | 7.0 | 5.7 |
| swim-away-day | base | 1/3 | CANNOT_TELL, LEFT, TOWARD | 3.3 | 2.0 |
| swim-away-day | arm | 1/3 | CANNOT_TELL, LEFT, TOWARD | 3.3 | 2.0 |
| swim-away-night | base | 1/3 | LEFT, LEFT, TOWARD | 4.3 | 3.0 |
| swim-away-night | arm | 1/3 | LEFT, LEFT, TOWARD | 4.3 | 3.0 |

**Every judge gave identical answers for base and arm in all three views.** All three noticed on their own that "the images come in three identical-looking pairs" and called it "3 independent samples, not 6".

## What the judges saw
- **Swim-across reads from the moving water on both sides:** "upright crescent marks advance steadily right", "crescent strokes slide right past a fixed seam" (so not camera pan). It reads correctly at confidence 7, but only by watching for about a second; each frame looks static.
- **Swim-away does not read on either side.** The crests are horizontal arcs that "lie along the direction they move", drift only a few pixels, and move with the logs and rock, "so the movement mostly looks like the camera". Two of three judges guessed LEFT, which is wrong.
- **The hard vertical colour seam** in swim-across-day was seen again. It has now been flagged in every T2 batch.

## Verdict
**The arm (lane_crest 0) makes no perceptible difference.** With identical answers on every strip, the direction-reading is the same with or without it. It cannot be credited with the owner's goal as captured.

**The owner's idea partly works already on base.** In the cross-current view, the existing moving crescents tell the direction from the water alone (3/3, confidence 7). The camera-facing current, in both swim-away views, does not read (1/3 at confidence 3–4), because crests that move toward the camera only creep down the screen.

**What would make "which way the waves move" read toward the camera**, from the judges' cues:
- crests oriented across the flow, so they advance rather than slide along themselves;
- enough speed and density to show a clear advance within a second;
- motion relative to floating debris, so it is not mistaken for camera drift.

The lane_crest 0.3 version smeared, so this is a shape and speed change, not more crest opacity. Fix the swim-across colour seam alongside it.

**The arrow stays the reliable cue.** It scored 18/18 correct at confidence 9 earlier today (`G-newapproach-t2-cue.md`). Owner's call: if the in-water cue is to replace the arrow rather than add to it, the swim-away case has to pass this test first.
