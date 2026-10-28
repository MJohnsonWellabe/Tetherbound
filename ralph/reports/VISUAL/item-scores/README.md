# Biome catalogue item scores (F38–F41)

Owner, 27 Oct 2026: "Do whatever is needed to score each biome's cards." Every F38–F41 catalogue row (106 items, P2-xxx) gets its own score, not just the stands it sits in.

## Job

`job.json` lists, per biome, every board row (`board_row`, e.g. `F41#7`). For each row it gives:
- the catalogue `item`, `subject` and `defect`;
- up to 3 `frames`. Each frame is a sighting from the phase-2 capture, with the exact `repro` command that originally shot it on the GTX 1060.

## Method

1. **Capture on current main.** Check out origin/main at the SHA you record. Run each unique frame's `repro` command once.
   - Keep the command's own arguments.
   - Change only `--output=` to `res://ralph/reports/VISUAL/item-scores/<biome>/frames/<frame id>`.
   - Add `--source-commit=<sha>` where the tool accepts it.
   - CPU lanes run under xvfb with Mesa llvmpipe. The GPU lane runs as each command states.
   - If a command fails or produces no frame, record it in `capture_failures` with the error. Do not retry more than once, and do not edit the capture tool except for the smallest fix to a reproduced crash.
2. **Judge each item.** Use `tools/visual_judge/`: the standard `JUDGE_PROMPT.md`, at least 3 anchor pairs per batch via `anchor_tiles.py`, and `calibrate.py`.
   - The set is one-sided: the item's frames only.
   - The subject line is the item's `subject`.
   - Ask the judges for the Bar A score of the subject. Also ask for a defect call on the catalogue `defect`, as PRESENT, PARTIAL or FIXED.
   - Use three fresh code-blind judges per batch, 12–20 items per batch.
   - If a judge omits items, re-ask once for the missing ones only.
3. **Mapped score.** Each item's score is the mapped three-judge mean. Record raw scores too.

## Output (commit; frames stay local per the repo-size rule)

Write `ralph/reports/VISUAL/item-scores/<biome>/scores.json`:

```json
{"main_sha": "...", "renderer": "CPU llvmpipe Compatibility | GPU <device> <preset>", "fit": {"r": 0.9, "rmse": 0.4},
 "items": {"P2-042": {"board_row": "F41#1", "mapped": 6.4, "raw": [6.0, 6.5, 6.2], "defect_call": ["PARTIAL","PARTIAL","FIXED"],
            "frames": ["stormwood__..."], "note": "one line"}},
 "capture_failures": [{"frame": "...", "error": "..."}]}
```

Also commit one `_sheet_<biome>.jpg` contact sheet under 1.5 MB, and a short `VERDICT.md` with a table of items by score.

Scores from CPU lanes are CPU-provisional. The GPU lane re-runs the same job to confirm them.
