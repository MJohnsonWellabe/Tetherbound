# F40#0 Cloudreach recapture: PAUSED (not READY)

Stopped 21 Oct 2026 ~15:05Z on owner direction relayed by the coordinator ("pause on all that visual until
I start remote"). The GPU remote's High/Medium recapture is to redo F40#0. No rows were re-scored; no judges ran.

## Frames done: 148 (Low/Compatibility, CPU)
- Tool `tools/capture_cloudreach_f40_matrix.gd`, source `1cd2028e8efd4599a5ccca89c58c4e5113443112` (tb/cloudreach head),
  Mesa llvmpipe under xvfb, 1280x720 (`--low-resolution=1280x720`). Frames stay local (`.artifacts/f40/recap-low-cpu/`,
  not committed); names and SHA-256 hashes for every frame are in `frame-manifest.json`, with per-run failures.
- Per catalogue stand d (0-based): pieces `d*8+3 .. d*8+7` = day clear/rain, golden clear/rain, night clear, each
  × approach/gameplay/reverse/detail (20 frames).

| Stand | Frames | Note |
|---|---|---|
| 0 Realm Gate Crag | 20 | complete |
| 1 Galefoot Waycamp | 15 | 12 m approach view refused by the teleport slope guard (deterministic) |
| 2 Three Bells Bridge | 15 | approach refused (same) |
| 3 Broken Skyroad Arch | 0 | every view refused by the slope guard: stand needs a corrected catalogue position |
| 4 Windscar Beacon | 19 | ~6 min/frame; 2 h timeout hit on the 20th frame, no failures |
| 5 | 15 | approach refused |
| 6, 7, 8 | 20 each | complete |
| 9 | 4 | interrupted by the pause |
| 10, 11 | 0 | not started |

## Frames left
At least 52 more to reach the 200 minimum (target ≥220 for margin): finish stands 9–11 (≈56), then dawn pieces
`d*8+1 .. d*8+2` as top-up. Then the three code-blind judges re-score all 41 Cloudreach catalogue rows, plus a blind
completeness check (Stormwood F41#0 precedent: `ralph/reports/F41/recapture-rescore/`).
`tools/rescore_cloudreach_f40.py` cannot run on CPU: it requires a validated High+Medium baseline/candidate
four-leg pair audit.

## Resume (CPU path, one stand per Godot process; fresh `--output` directory each run)
```
SHA=$(git rev-parse HEAD)   # recapture at one SHA; a new SHA means restarting the whole set
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3 \
  --rendering-method gl_compatibility --resolution 1280x720 \
  --script res://tools/capture_cloudreach_f40_matrix.gd -- --biome=cloudreach --preset=Low \
  --low-resolution=1280x720 --source-commit=$SHA --piece=<d*8+3>-<d*8+7> \
  --output=res://.artifacts/f40/recap-low-cpu/dest<d>-<stamp>
```
For d = 9, 10, 11 (pieces 75-79, 83-87, 91-95), then the dawn top-ups. Allow ≥3.5 h timeout per stand on CPU.
GPU path (preferred, per owner): the High/Medium commands in `ralph/reports/R2-F40/runtime-proofs.json` with `--piece=1-96`.
