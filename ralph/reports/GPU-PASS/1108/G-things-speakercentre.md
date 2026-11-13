# G-things-speakercentre: speaker-centred dialogue camera (F38#16/#17/#36/#37; GPU High)

## Verdict: DO NOT SHIP as one arm (fails no-loss)
The arm helps Hess and hurts Rae by more.

| Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| Hess (relay picket) | 5.95 | 7.11 | **+1.16** | 3/3 |
| Rae | 7.60 | 6.00 | **−1.60** | 0/3 |
| Stronghold patrol (Verrick) | 6.66 | 6.57 | −0.09 | 1/3 |

Keep the Hess camera. Leave Rae on her current camera.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-things-speakercentre` (404fd6029), High, `phase2_capture_dialogue.gd`, every Meadows post, seed 2042, `--sight-stand` on both sides.
- **Build:** `tb/things` 4c824ef9a on both sides (clearance_1112 on).
  - **base:** no overlay.
  - **arm:** `THINGS-SPEAKERCENTRE/overlay_speaker_centre.json` (`clearance_1112.speaker_centre` on).
- **Render check:** only 3 of 48 shots change camera on the arm (Hess about +56°, stronghold patrol about +77°, Rae about +54°). The other 45 differ only by scene motion. None of the 3 is in the F38#16/#17/#36/#37 row frames, so this arm cannot move those rows. 0 script errors.

## Batch `G-sc`
- Three code-blind judges, standard prompt. Candidate sets: the 3 changed conversation shots, base vs arm.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.3327, intercept −1.4222, r 0.943, anchor RMSE 0.46. One warning: Rae base (7.60) maps above the top anchor (7.53). This batch is its own confirming batch.

## Results

| Set | Base raw → mapped | Arm raw → mapped | Gain |
|---|---|---|---|
| Hess | 5.5, 5.5, 5.6 → 5.95 | 6.6, 6.3, 6.3 → 7.11 | +1.16 |
| Rae | 6.7, 6.8, 6.8 → 7.60 | 5.4, 5.8, 5.5 → 6.00 | −1.60 |
| Stronghold patrol | 6.0, 6.0, 6.2 → 6.66 | 6.1, 5.9, 6.0 → 6.57 | −0.09 |

### What the judges see (3/3 unless noted)
- **Hess:**
  - On base she is "cut by the left edge", "turned away in profile", and a post and a large red banner fill the right third.
  - On the arm she is "mid-frame, fully readable and facing the camera".
  - The arm's remaining defect: the stone-plated companion is cropped at the left edge and takes about a fifth of the frame.
- **Rae:**
  - On base she is "cleanly framed ... against open meadow, distant mountains and a tree".
  - On the arm "a huge dark creature body with stone plates fills the centre and top right", the trainer's head and backpack block the lower right, and Rae is "pushed into the left third". This matches the GPU lane's pre-check.
- **Stronghold patrol:**
  - Level. Verrick is readable on both sides. Red here is Team Tether, which is correct.
  - What holds this shot down is a placeholder-looking furnace (flat orange square door), blocky pipe-and-ring props and a one-tone green wall (3/3, both sides).

## Recommendation
1. Turn `speaker_centre` on per speaker, not globally: Hess yes, Rae no, Verrick either way.
2. Or keep the global rotation and add the companion and trainer to the cone that must stay clear toward the speaker. All 3 judges name this as their top scene fix. The Rae loss is the companion, not the angle.
3. This arm does not touch the F38#16/#17/#36/#37 row frames. Those rows need a change to their own shots.
4. The Hess gain is +1.16 on one shot, so it meets the 0.5 rule as its own change if shipped per speaker. Re-judge that per-speaker arm before landing, so the no-loss check covers Rae's unchanged shot.
