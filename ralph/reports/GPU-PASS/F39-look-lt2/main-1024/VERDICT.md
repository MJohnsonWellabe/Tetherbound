# Tidewake time-of-day regrade (close-1024 lt2) on main: GPU pass (24 Oct 2026)

**Verdict: REOPENED.**
- **Scores:** the regrade (main, `lighting_candidate` ON) maps to **6.12**, against **5.35** for the control (`lighting_candidate` in `sections_off`). That is +0.77, the same at Medium and High.
- **CPU-provisional was 7.07.**
- **What it fixes:** evening and dawn now carry their own grade, FIXED in 3/3 judges on the regrade side.
- **What holds it under the bar:**
  - the night beach still casts nothing (PRESENT ×3, on both sides);
  - the noon sea/sky seam is only softened (PARTIAL ×2, PRESENT ×1);
  - the Veilfall close-up and the sparse dunes stay as they are.

## Run

- **Source:** main 45865499d (game content). Tidewake `lighting_candidate` ships ON there, with lt2's note.
- **Capture:** `tools/capture_tidewake_f13_5.gd --camera-set=res://tools/visual_judge/camera_sets/F39-look.json --capture-size=1920x1080 --preset=<Medium|High> --source-sha=45865499d…`.
  - All 9 views, with `complete: true` in each manifest.
  - Forward+ on a GTX 1060, isolated APPDATA.
  - Queue: `f39_look_queue.ps1.txt`.
- **Control:** the same tree with `lighting_candidate` appended to `data/config/tidewake_look.json` `sections_off`, restored after the run.
- **Source SHA:** `--source-sha` is the tool's required provenance field. It records main 45865499d, the game content of this checkout; tb/gpu-pass adds only reports on top.
- **Sides:** the six clear views lt2 judged:
  - First Shore 12:00 / 18:00 / 23:00;
  - the dune 12:00 / 05:00;
  - Veilfall close.

## Yardstick

- **Batch:** `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`: 4 anchor pairs plus 2 candidate sets (Medium and High, each regrade vs control).
- **Judges:** three fresh code-blind judges, each given `JUDGE_PROMPT.md` (main) verbatim.
- **Recorded defects:** lt2's three.
- **Calibration:** slope 0.958, intercept 1.326, r 0.88, anchor RMSE 0.58. Confirming batch (top anchor 7.53), no warnings.
- **Judge 2's block:** its first JSON block omitted the Medium set. Asked for it without new file access, it scored that set the same as High (`yardstick/j2.json` notes this). All three judges said the Medium and High sheets were near-identical.

| Side | Raw (j1/j2/j3) | Mapped per judge | **Mapped mean** |
|---|---|---|---|
| Control, Medium and High | 4.3 / 4.3 / 4.0 | 5.45 / 5.45 / 5.16 | **5.35** |
| **Regrade (main), Medium and High** | 5.0 / 5.0 / 5.0 | 6.12 / 6.12 / 6.12 | **6.12** |

## Recorded defects (regrade side; j1/j2/j3)

| Defect | Regrade | Control |
|---|---|---|
| Evening and dawn graded like midday | **FIXED ×3** | PRESENT ×3 |
| Razor sea/sky seam, no haze | PARTIAL / PRESENT / PARTIAL | PRESENT ×3 |
| Night beach flat ambient, nothing casts | PRESENT ×3 | PRESENT ×3 |

## What the judges saw

- **Regrade:**
  - 18:00 is a real warm peach-rose across sand and sea, not just the sky.
  - 05:00 at the dune is rose-umber, with haze round the sun.
  - The control's evening is noon with a warmer sky, and its dawn is grey midday sand under a low sun.
- **Still open, on both sides:**
  1. **23:00:** a flat blue wash, with no shadow from the trainer or props and no moon key read. The same as lt2's first ask on CPU.
  2. **Noon horizon:** a hard pale-cyan line. The haze shows only around the warm-hour sun.
  3. **Veilfall close:** "a near-black faceted cliff with a white blob of waterfall" (all three judges, `new_art`). The weakest frame in the set.
  4. **Dunes:** an even sand carpet with uniform pebble scatter and almost no props or groves.

## Files

- `_sheet_f39_lt2_gpu.png`: Medium, control (top) vs regrade (bottom); 18:00, 23:00 and 05:00 (89 KB).
- `yardstick/`:
  - `key.json`, `sets.md`, `candidates.json`, `recorded_defects.txt`, `judge_prompt_filled.txt`;
  - `j1.json`–`j3.json` (condensed), `batch.json`, `mapped.json`.
- Per-frame captures and manifests stay local.
