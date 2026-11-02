# Main 1102 GPU creature confirmation: installed (1 Nov main) vs shipped (main after #796), mapped Bar A

GPU frames from origin/tb/gpu-frames-1101 (main/ = installed control, main1102/ = shipped candidate; same tool and camera). Each side a 2x2 grid of hit-000, hit-050, faint-050, faint-100 with the batch-4 creature brief. Standard JUDGE_PROMPT v1, 3 anchor pairs (anchor_tiles.py, seed 601), 3 independent code-blind judges, calibrate.py --bar 7.5 (mapped_mean). Batch-4 columns are the batch-4 GPU numbers (b4j/RESULTS.json: its main and batch-4 candidate) where that species was judged.

| Creature | installed | shipped | delta | shipped >= 7.5 | b4 main | b4 batch4 | b4 delta | notes |
|---|---|---|---|---|---|---|---|---|
| cliffspike | 5.97 | 6.91 | +0.94 | no | 6.60 | 5.58 | -1.02 |  |
| craghorn | 6.31 | 7.25 | +0.94 | no | 6.92 | 6.17 | -0.75 |  |
| cannonback | 6.23 | 6.68 | +0.45 | no | 6.68 | 6.34 | -0.34 |  |
| riptusk | 6.42 | 6.68 | +0.26 | no | n/a | n/a | n/a |  |
| meadowhart | 6.87 | 7.06 | +0.19 | no | n/a | n/a | n/a |  |
| terrapup | 6.57 | 6.38 | -0.19 | no | n/a | n/a | n/a |  |
| ashtusk | 6.83 | 6.31 | -0.52 | no | 7.40 | 6.00 | -1.40 |  |
| tuskroot | 7.17 | 6.31 | -0.86 | no | n/a | n/a | n/a |  |
| torrentoad | 7.06 | 5.59 | -1.47 | no | n/a | n/a | n/a |  |

## Shipped at or above 7.5

- none

## Regressions vs installed (delta <= -0.3)

- ashtusk (-0.52)
- tuskroot (-0.86)
- torrentoad (-1.47)

Folder notes: {"CREATURES warnings": []}
