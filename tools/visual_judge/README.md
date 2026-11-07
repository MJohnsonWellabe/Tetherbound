# tools/visual_judge

The yardstick: `JUDGE_PROMPT.md` (verbatim), `anchor_tiles.py` (3+ anchor pairs per batch), `calibrate.py` (anchor-mapped Bar A). The `visual-judge` skill and TECHNICAL §8.1 "CPU judging" give the full method.

## Quick A/B round for one item (`quick_judge.py`, owner 4 Nov 2026)

One item, base and candidate, judged the standard way in about 10 minutes on CPU. The yardstick does not change; only the plumbing does:
- **Only the item's stands.** It looks up the item's frames and repro commands in `ralph/reports/VISUAL/item-scores/job.json`. It merges them into the fewest boots: subsets go together, and creature `--only` lists are merged. Where a tool's own filter keeps the stage, camera and timings, it narrows the boot to those frames (creatures: `--poses=`).
- **No import, no re-capture of an unchanged base.** It never runs `--import`; import once per checkout (TECHNICAL §8.1). Base captures are cached under `.artifacts/qj/cache/<tree>/base/`, keyed by the HEAD tree plus any tracked edits. A second candidate on the same tree captures only the candidate. A tree change always takes a fresh base. Cloudreach tools get `--ground-cover-cache`.
- **The overlay restores byte-identically.** The candidate is a JSON overlay over `data/config` files. It is either a per-file merge patch or a list of dotted OFF flags to switch ON (`lane_bin/overlay.py` specs also work). Every file is restored and sha256-checked after the capture, even on a crash or Ctrl-C. If the process is killed, `quick_judge.py revert` restores from `.artifacts/qj/overlay_backup/`. Godot runs take the shared `godot.lock`; overlaid captures also take `scene.lock`.

```
python3 tools/visual_judge/quick_judge.py plan F39#23                 # stands + boots, no Godot
python3 tools/visual_judge/quick_judge.py run F39#23 --overlay '{"data/config/capture_readout_visual.json": {"readout_side_enabled": true}}'
#   -> captures, builds .artifacts/qj/<round>/{judge,k}, prints LAUNCH_JUDGES.md:
#      launch 3 fresh general-purpose judges in ONE message, each with the text of k/JUDGE_PROMPT_FILLED.txt pasted verbatim;
#      save their replies as replies/j1.txt j2.txt j3.txt (the whole reply is fine)
QJ_LANE=VIS-TIDEWAKE python3 tools/visual_judge/quick_judge.py finish .artifacts/qj/<round>
#   -> ralph/reports/LANES/<QJ_LANE>/qj/<round>/: VERDICT.md, batch/key/spec/mapped/defects JSON, _sheet_<round>.jpg (<1.5 MB)
```

Anchors are pinned to the v1/b5 set (`craft,f10_2_r3_capacitor,f04_6_r22`) so that rounds stay comparable. That set reproduced b5 within RMSE, while a random draw moved the level by 0.5–0.9. Override it with `packet --include`. Other subcommands: `capture` (capture only), `packet <round>` (rebuild the judge folder with a new seed), and `--dry-run` (print the Godot commands). The rules still hold: CPU mapped scores rank candidates; a row closes only on the GPU.
