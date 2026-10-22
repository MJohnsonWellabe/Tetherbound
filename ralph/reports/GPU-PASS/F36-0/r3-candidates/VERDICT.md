# F36#0 r3 candidates: Riverdrake c3 and Meadowhart c1 (GPU, Medium, 22 Oct 2026, midday)

**Verdict: neither candidate closes its row. Both rows REOPENED.**
- **Riverdrake c3** (shove hit) maps to **7.39** against live 7.35, a +0.04 gain.
- **Meadowhart c1** (shove plus resting-deer faint) maps to **7.22–7.28** against live 7.22, a gain of +0.00 to +0.06.
- Both are below the 7.5 bar.
- Both live recipes reproduce their earlier GPU mappings: 7.35 against 7.33 for Riverdrake, and 7.22 against 7.19 for Meadowhart.

## What was run

- **Source:** tb/creatures head `ef497ef94`, in a local detached worktree. Nothing was committed from it.
- **Candidate recipe build:** `python tools/art_pipeline/f36_pose_postpass.py --candidate-1022 --topple=meadowhart --shove-hit=riverdrake`, run in that worktree with Python 3.12 and numpy 2.5.4.
  - It rewrote exactly two profiles in `data/creatures/f36_pose_candidates.json`: `meadowhart_quadruped_anatomical` and `riverdrake_quadruped_anatomical`.
  - The diff's sha256 is `c34bd23a…bd91`.
  - The file was restored with `git checkout` after capture.
- **Capture:** `res://tools/art_pipeline/capture_f36_poses.gd -- --species=riverdrake,meadowhart --whole-body --context`, at Medium (Forward+ on Vulkan, GTX 1060), 1280x720. Exact commands are in `commands.txt`.
- **Three arms:**
  - **live:** `--candidate` on the unmodified recipe file. This is the arm the earlier GPU mapping (7.33 / 7.19) scored.
  - **candidate:** `--candidate` after the post-pass.
  - **installed:** no `--candidate`. That plays the raw installed clips; the coordinator asked for this arm as "live".
  - The tool's own header says `--candidate` previews the flag-off recipe file and that the run without it is the baseline. So "live" in the earlier scores means the recipe arm, and I scored both. Riverdrake's installed run exits 1 because it has no installed swim or fly_grip clips; its hit and faint frames are complete.
- **First candidate run discarded:** the first candidate capture ran before numpy was installed, so the post-pass had failed and the run captured the unmodified recipe. It was discarded and re-run after a successful post-pass.
- **Judge sides:** the same five poses as the earlier F36 roster batch (standing, hit react, hit recover, faint mid, faint end), with the same crop.

## Yardstick result

**Batch:**
- Built with `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`.
- 4 candidate pairs, sides shuffled:
  - Riverdrake candidate vs live.
  - Riverdrake candidate vs installed.
  - Meadowhart candidate vs live.
  - Meadowhart candidate vs installed.
- Three fresh code-blind judges, each given `JUDGE_PROMPT.md` verbatim. The key was withheld until all three verdicts were in.

**Calibration:**
- 8 anchor points, linear fit, slope 0.613, intercept 3.487, r 0.83.
- Anchor RMSE 0.60, so no fit warning.
- Confirming batch: the top anchor reference is 7.53.
- No side is above the top anchor.

| Creature / arm | Raw Bar A (j1/j2/j3) | Mapped per judge | **Mapped mean** |
|---|---|---|---|
| Riverdrake candidate (both pairings; same image, same scores) | 6.5 / 6.6 / 6.0 | 7.47 / 7.53 / 7.16 | **7.39** |
| Riverdrake live recipe | 6.3 / 6.7 / 5.9 | 7.35 / 7.59 / 7.10 | **7.35** |
| Riverdrake installed clips | 5.8 / 6.0 / 5.6 | 7.04 / 7.16 / 6.92 | **7.04** |
| Meadowhart candidate (vs live) | 6.6 / 6.1 / 5.6 | 7.53 / 7.22 / 6.92 | **7.22** |
| Meadowhart candidate (vs installed) | 6.5 / 6.2 / 5.9 | 7.47 / 7.28 / 7.10 | **7.28** |
| Meadowhart live recipe | 6.0 / 6.4 / 5.9 | 7.16 / 7.41 / 7.10 | **7.22** |
| Meadowhart installed clips | 5.6 / 5.6 / 4.6 | 6.92 / 6.92 / 6.30 | **6.71** |

## What the judges saw

**Riverdrake candidate:**
- All three judges read it the same way: "a strong rearing hit react and readable flat faints".
- It beats the live recipe's subtle hit react.
- What holds it under 7.5 is not the pose:
  - The long, low body barely clears the 1.80 m trainer; only the crests rise above.
  - The material is flat, with no rim light, on the neutral stage.

**Meadowhart candidate:**
- The rearing hit reads, and the model matches the board at good scale.
- The judges split on the new resting-deer faint:
  - j1 scored it higher than live.
  - j2 and j3 said the faint end, "head held high", reads as kneeling or resting rather than fainted.
- Shared limits: flat material, small plain antlers and a low-contrast face.

**Installed clips (both creatures):**
- Weakest arm.
- Meadowhart's installed faint "splays the legs like a toppled figurine" and its hit react matches standing.

**Judges' top creature ask:** rim light and designed colour blocks on the stage materials, plus grounded faints that read as down rather than resting. The Riverdrake asks also include body height above the trainer.

## Files

- `_sheet_f36_r3.png`: each creature as installed, live recipe and candidate strips, with the same five poses.
- `commands.txt`: exact capture commands.
- `yardstick/`:
  - `key.json`, `candidates.json`, `sets.md`, `recorded_defects.txt` (none recorded), `judge_prompt_filled.txt`;
  - `j1.json`–`j3.json`: the judges' final JSON blocks;
  - `batch.json`, `mapped.json`: calibrate output.
- Per-frame captures and judge tiles stay local and are not committed.
