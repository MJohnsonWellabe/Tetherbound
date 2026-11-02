# Meadows single-flag A/Bs vs main (mapped Bar A)

GPU frames origin/tb/gpu-frames-1101 mw/<flag> vs mw/main (tree dd2d01342), High 1920. Standard JUDGE_PROMPT, 3 anchor pairs per folder, 3 code-blind judges per folder, calibrate.py --bar 7.0.

| A/B | flag | main | cand | delta |
|---|---|---|---|---|
| RIVER | water.json river surface_candidate.enabled, P2-006 r2 (tree 49ca00126) | 4.94 | 5.29 | +0.35 |
| LIGHT | meadows_look.json light_candidate.enabled (tree 439d2c4c3) | 6.50 | 6.71 | +0.21 |
| WARRENS | burrow_warrens.json hill_shell.r2.enabled, P2-012 r2 (tree d92497a04) | 5.32 | 5.32 | +0.00 |

## RIVER per set

| set | main | cand | delta |
|---|---|---|---|
| Meadows old mill crossing #1 | 4.68 | 5.52 | +0.84 |
| Meadows old mill crossing #2 | 5.19 | 5.06 | -0.13 |

## LIGHT per set

| set | main | cand | delta |
|---|---|---|---|
| Meadows grandpas village | 6.58 | 7.08 | +0.50 |
| Meadows the burrow warrens | 6.88 | 6.62 | -0.26 |
| Meadows the ironwood grove | 5.85 | 6.38 | +0.53 |
| Meadows the ridgeline watch | 6.55 | 6.08 | -0.47 |
| Meadows stronghold approach | 6.12 | 6.75 | +0.63 |
| Meadows grandpas village route walk #1 | 6.78 | 7.02 | +0.24 |
| Meadows grandpas village route walk #2 | 6.75 | 7.02 | +0.27 |

## WARRENS per set

| set | main | cand | delta |
|---|---|---|---|
| Meadows the burrow warrens | 6.10 | 6.00 | -0.10 |
| Meadows the burrow warrens route walk #1 | 5.91 | 6.00 | +0.09 |
| Meadows the burrow warrens route walk #2 | 3.96 | 3.96 | +0.00 |
