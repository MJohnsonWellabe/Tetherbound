# F36#0 roster re-judged with the owner-style prompt (GPU frames, 22 Oct 2026, evening)

**Owner direction (22 Oct):** the installed naturalistic creatures are the intended style. The judge prompt is corrected on tb/owner-creature-style `e188bc862`: `JUDGE_PROMPT.md` no longer asks for "designed colour blocks", and judges must not mark down naturalistic creatures.

**Result:**
- The corrected prompt lifts the roster by **+0.48 on the installed clips** (mean 6.27 → **6.75**) and by **+0.42 on the pose recipes** (6.55 → **6.96**).
- 26 of the 32 arms gain. The storm and dark creatures gain the most: Fulgocobra +1.05, Voltarach +1.03, Staticub +1.02, Tanglevolt recipe +1.00, Stormursa +0.95.
- **No arm reaches 7.5.** The closest are the Meadowhart recipe at 7.49, Ripplet recipe 7.46, Veridian installed 7.43 and Aeriex installed 7.37.
- **Ripplet falls** (recipe 7.89 → 7.46, installed 7.26 → 6.69). The judges now cite its glossy, plastic-looking sheen and an upright faint end. Aeriex installed is −0.17; the rest are flat.

## Method

- **Frames:** reused unchanged, exactly the sides of the earlier roster batch (`ralph/reports/GPU-PASS/F36-0/`, Medium, GTX 1060). The pairing is the same, so the comparison is like-for-like.
  - recipe = `capture_f36_poses.gd --candidate`; installed = without it.
  - Poses: standing, hit react, hit recover, faint mid and faint end.
- **Still matching main:** since those renders, main changed
  - `f36_pose_candidates.json` (Aeriex removed from `enabled_species`, so Aeriex now ships its installed clips);
  - `creature_body.gd` (an opt-in camera fade that the stage never enables);
  - follower and water-alpha scripts.
  None of that changes these stage frames.
- **Judges:** three fresh code-blind judges, each given the corrected `JUDGE_PROMPT.md` from `e188bc862` verbatim (`yardstick/judge_prompt_filled.txt`). The key was withheld until all three verdicts were in.
- **Batch:** `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`, giving 4 anchor pairs (craft, f36_0_npc C1, p2_094_r4, f36_0_gap C2) plus the 16 species pairs.
- **Calibration:** 8 points, slope 0.923, intercept 1.341, r 0.90, anchor RMSE 0.60, no warnings, confirming batch (top anchor 7.53). No side is above the top anchor.
- **The old scores** are the earlier batch's mapped means, under the old prompt and different random anchors (`ralph/reports/GPU-PASS/F36-0/yardstick/`).

## Old vs new (mapped mean; per-judge new values in `old_vs_new.csv`)

| Species | Installed old → new | Recipe old → new |
|---|---|---|
| abyssal_guardian | 5.98 → 6.75 (+0.77) | 6.85 → 7.28 (+0.43) |
| aeriex | 7.54 → 7.37 (−0.17) | 7.16 → 7.22 (+0.06) |
| burrowback | 6.71 → 6.72 (+0.01) | 7.16 → 7.15 (−0.01) |
| fulgocobra | 5.21 → 6.26 (+1.05) | 5.56 → 6.23 (+0.67) |
| galecrest | 5.87 → 6.45 (+0.58) | 5.56 → 6.32 (+0.76) |
| meadowhart | 6.43 → 6.88 (+0.45) | 7.19 → **7.49** (+0.30) |
| mirejaw | 6.22 → 6.38 (+0.16) | 6.12 → 6.45 (+0.33) |
| ripplet | 7.26 → 6.69 (−0.57) | 7.89 → 7.46 (−0.43) |
| riverdrake | 6.50 → 6.85 (+0.35) | 7.33 → 7.34 (+0.01) |
| staticub | 5.80 → 6.82 (+1.02) | 6.43 → 7.28 (+0.85) |
| stormcapra | 6.46 → 7.03 (+0.57) | 6.36 → 6.91 (+0.55) |
| stormursa | 5.56 → 6.51 (+0.95) | 6.64 → 7.12 (+0.48) |
| tanglevolt | 5.73 → 6.29 (+0.56) | 6.12 → 7.12 (+1.00) |
| tuskroot | 6.67 → 7.06 (+0.39) | 6.71 → 7.00 (+0.29) |
| veridian | 6.88 → 7.43 (+0.55) | 6.19 → 6.72 (+0.53) |
| voltarach | 5.42 → 6.45 (+1.03) | 5.49 → 6.32 (+0.83) |
| **roster mean** | **6.27 → 6.75 (+0.48)** | **6.55 → 6.96 (+0.42)** |

## What still holds the roster below 7.5 (all three judges)

1. **Faint poses** (scene/animation): in about 12 of 16 sets, one arm's faint end stays standing, sits upright facing the camera, or rears up. The working lying pose usually exists in the other arm.
2. **Material loss in rolled faints** (judge set codes; see `yardstick/key.json`): Gz A (an untextured grey body floating above its shadow), Ew B and Yd B (white or black undersides), Fm B (mane lost).
3. **The boards' emissive identity details are missing**: Voltarach's blue eyes, Fulgocobra's gold veins, Tanglevolt's lightning.
4. **Value and rim light** on dark creatures, the Kp bird and the Iw spider, on the neutral stage.

## Files

- `old_vs_new.csv`: per species and arm, the old mapped score, the new mapped score, the delta and the new per-judge mapped values.
- `yardstick/`:
  - `key.json`, `sets.md`, `recorded_defects.txt`, `judge_prompt_filled.txt`;
  - `j1.json`–`j3.json`: the judges' scores;
  - `batch.json`, `mapped.json`.
- The side images are the earlier batch's (local) and are not committed.
