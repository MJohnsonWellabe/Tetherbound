# G-things-beam: quest beacon beam removed from catch views (F38#7; F38#33 and F38#14 ride along; GPU High)

## Verdict: SHIP. All three rows gain, at least 2/3 prefer the arm on each, and nothing loses. No row reaches 7.5; two sit at 7.49.

| Row | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F38#7** catch aim readability | 6.92 | **7.49** | **+0.57** | 3/3 | 7.06, 7.63, 7.78 |
| F38#33 catch result hierarchy | 7.35 | **7.49** | +0.14 | 2/3 (1 tie) | 7.21, 7.63, 7.63 |
| F38#14 catch effect finish | 7.01 | **7.40** | +0.39 | 3/3 | 7.35, 7.49, 7.35 |

- **What the arm fixes.** Base has "a tall cyan light beam ... a sci-fi pillar / flat effect slab" rising through the aim frames (3/3). The arm removes it.
  - F38#7's recorded defect: FIXED on the arm for 2/3, PARTIAL on base 3/3.
- **Confound: the sides differ beyond the beam.** Each side ran on its own tree (base main 506b40292, arm tb/things f582dbd7a), and the frames differ by run timing.
  - **F38#7:** base's frame 2 has a bush in front of the target and the trainer (3/3). That is the same capture fault G-closeout-meadows-ui saw on High. Part of the +0.57 is the bush, not the beam.
  - **F38#14:** the arm's orb is caught as "a modelled sphere with ornament and gold banding" and its pose changes between frames 1 and 2. Base's orb is "a flat cream disc" with frames 1 and 2 identical. That is orb timing in the stage run, not the beacon fix.
  - So the beam removal is a real gain, but its size is uncertain. The rows' arm scores are the useful numbers.
- **Near the bar.** F38#7 and F38#33 at 7.49 are close-out candidates. The judges' remaining asks for each are below.

## What still holds the rows (3/3 unless noted)
- **F38#7 aim:**
  - The reticle is "a small cyan slab on the hare's chest that is hard to see". The judges ask for a bright outlined ring with a dark halo.
  - The trainer overlaps the target's legs.
  - Frame 3 has flat white smoke puffs at ground level.
  - Keep foliage out of frame (base's bush; the arm's frame 2 has grass at the right edge, 1/3).
- **F38#33 result:**
  - The success moment is "only a generic sparkle and a toast", with "no staging of the captured creature". It ends on "an orb in the grass".
  - A second Bramblebun stands upper-right near the banner (2/3).
- **F38#14 effect:**
  - The burst is "flat beige glow puffs", which the judges want as "a lit, element-tinted burst".
  - The shake barely reads (PARTIAL 3/3). The magenta ring is gone on both sides.
  - Terrapup crowds the left third (2/3).

## Frames
- **Sources:** `tb/gpu-frames-1108`, High, both from `phase2_capture_catch.gd --biome=meadows --seed=2042`.
  - `G-things-beam-catch` (384c4e9d6): the plain catch run.
  - `G-things-beam-catch-stages` (178081422): `--stages-on-catch`.
- **Sides:**
  - **base:** main 506b40292.
  - **arm:** `tb/things` f582dbd7a (objective beacon fix, code only; the other lane code is flag-off).
- **Health:** 0 script errors, 0 blank frames.
- **Sets:** each row's three job.json frames, stacked top to bottom.
  - F38#7: 01-aiming-full-health, catch_low, catch_high.
  - F38#33: 06-breakout, 08-caught-verdict, 09-caught-banner.
  - F38#14: 02-orb-in-flight, 03-strike, 03-absorbing (stages run).
- **Render check:** mean difference 29–31 on every set. Most of it is run-to-run foliage and timing, which is the confound above.

## Batch `G-bm`
- Three code-blind judges, standard prompt, three candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.428, intercept −2.3626, r 0.916, anchor RMSE 0.56.

**Raw Bar A (judges a, b, c):**

| Row | Base | Arm |
|---|---|---|
| F38#7 | 6.3, 6.6, 6.6 | 6.6, 7.0, 7.1 |
| F38#33 | 6.6, 7.0, 6.8 | 6.7, 7.0, 7.0 |
| F38#14 | 6.4, 6.8, 6.5 | 6.8, 6.9, 6.8 |
