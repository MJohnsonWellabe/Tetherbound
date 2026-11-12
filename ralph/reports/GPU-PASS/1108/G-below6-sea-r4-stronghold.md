# G-below6-sea-r4-stronghold: restored sea round 4 (F39#17) and the stronghold stand (F38#20) (LANE-BELOW6; GPU High)

## Verdicts

| Arm | Set | Base | Arm | Gain | Prefer arm | Verdict |
|---|---|---|---|---|---|---|
| stronghold stand r2 | **F38#20 row** (approach day, night, courtyard landmark) | 6.40 | **7.57** ↑top | **+1.17** | 3/3 | **SHIP.** Meets the bar at High (7.71, 7.50, 7.50; confirming batch); needs Medium |
| restored sea r4 | **F39#17 row** (S1/S2 live and restored) | 6.26 | 6.23 | −0.03 | 1/3 (2 prefer base) | **Do not ship.** The row is level-to-down, and the restoration no longer reads |
| restored sea r4 | F39#17 other stands (S3 waterfall, S4 sunset) | 5.84 | 6.37 | +0.53 | 3/3 | (no-loss check now gains) |

**Pooled current-main line (coordinator's policy):**
- F38#20 on current main, with no stand change: this batch's base 6.40 and G-things-meadowground's 5.76 (different tree) pool to about 6.1.
- The arm's 7.57 is evidence of the gain, not yet the row score.

## F38#20 stronghold stand
- **Approach.** The arm's day approach is "a clear, lit landmark at the end of a cobbled path, framed by trees ... no dominant pylons".
- **Base.** Base "sits on a flat empty field in front of a grey, washed-out fog wall of mountains", and its night foreground crushes to black.
- **Recorded defect:** FIXED on the arm 3/3, PARTIAL on base.
- **What still holds it (1–2/3):**
  - the castle still sits fairly small in frame;
  - flat orange window rectangles by day, "jack-o'-lantern faces" at night;
  - the interior (same on both sides) has oversaturated orange props, some oversized against the trainer, and glowing sprite fires.
- **The GPU lane's watch item** (a faint translucent copy of the crenellations behind the keep) was not named by any judge.
- **Next:**
  - a Medium capture of the same stand to close;
  - if Medium misses, the levers are a warmer, less uniform window glow and a slightly closer or taller stand.

## F39#17 restored sea, round 4
- **The no-loss stands now gain.** S3/S4 rise 5.84 → 6.37 (3/3). The arm keeps the sunset water "teal-green with readable form", where base's "lower-left water goes almost black". Round 1's sunset loss is fixed.
- **The row no longer gains.** On S1/S2 the judges call the sides "nearly identical": "the restoration event does not read on either side". The recorded defect is PRESENT on both sides (3/3).
  - Round 1's darker deep water made the restored current read: +0.67 on the row.
  - Round 4's wider, lighter shallows do not.
- **Shared defects (3/3):**
  - a hard-edged dark wedge or shadow band across the water;
  - bare sand-disc islands with no dressing;
  - a blown-out sun-glint bar;
  - a low-detail faceted waterfall cliff.
- **Next:**
  - combine round 1's restored-current read on S1/S2 (deeper water, visible current bands) with round 4's lighter sunset water. Scope the deepening to the S1/S2 stands or to high sun only.
  - The row needs the restoration to show on the shoreline: foam lanes, white surf on the sandbars.
  - Island dressing is the next lever after that.

## Frames
- **Sources:** `tb/gpu-frames-1108`, High.
  - `G-below6-restored-sea-r4` (599b85bbf): 32 frames.
  - `G-below6-stronghold-stand-r2` (652497f91): 8 frames.
- **Build:** `tb/below6` d4801ed9a on both sides (game-identical to d13bdd51d).
  - **base:** no overlay.
  - **arm:** each lane overlay.
- **Health:** 0 blank frames, 0 script errors.
- **Sets:**
  - F39#17: the same row and no-loss sets as G-restoredsea-mapfog.
  - F38#20: its job.json frames (band5 approach day and night, landmark stronghold day approach), stacked.
- **Render check:** mean difference F39#17 row 7.6, other stands 5.5, F38#20 17.9.
- **GPU lane pre-checks:**
  - S4 black share 69.7% → 43.9%.
  - S1/S2 restored L 57 → 84 and 71 → 101.

## Batch `G-b6`
- Three code-blind judges, standard prompt, three candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.0586, intercept 0.298, r 0.874, anchor RMSE 0.67. A loose fit; sets are about ±0.35.
- **Warning:** F38#20 arm meets the bar only above the top anchor (7.53). This batch is its confirming batch.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F38#20 | 5.6, 5.8, 5.9 | 7.0, 6.8, 6.8 |
| F39#17 row | 5.8, 5.4, 5.7 | 5.7, 5.5, 5.6 |
| F39#17 other stands | 5.5, 5.1, 5.1 | 6.0, 5.6, 5.6 |
